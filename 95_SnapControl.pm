package main;

use strict;
use warnings;
use JSON::XS;
use DevIo; # load DevIo.pm if not already loaded

my %streamLocations = ();
my %streamClients = ();
my $zwERG ="";
my $recentLocation="";
my $recentStream="";

# called upon loading the module SnapControl
sub SnapControl_Initialize($)
{
  my ($hash) = @_;

  $hash->{DefFn}    = "SnapControl_Define";
  $hash->{UndefFn}  = "SnapControl_Undef";
  $hash->{SetFn}    = "SnapControl_Set";
  $hash->{ReadFn}   = "SnapControl_Read";
  $hash->{ReadyFn}  = "SnapControl_Ready";
  $hash->{helper}  = ();
}

# called when a new definition is created (by hand or from configuration read on FHEM startup)
sub SnapControl_Define($$)
{
  my ($hash, $def) = @_;
  my @a = split("[ \t]+", $def);

  my $name = $a[0];
  
  # third argument is the hostname or IP address of the device (e.g. "192.168.1.120")
  my $dev = $a[2]; 

  return "no device given" unless($dev);
  
  # close connection if maybe open (on definition modify)
  DevIo_CloseDev($hash) if(DevIo_IsOpen($hash));  

  # add a default port (1012), if not explicitly given by user
  $dev .= ':1705' if(not $dev =~ m/:\d+$/);

  # set the IP/Port for DevIo
  $hash->{DeviceName} = $dev;
    
  # open connection with custom init and error callback function (non-blocking connection innitiation)
  DevIo_OpenDev($hash, 0, "SnapControl_Init", "SnapControl_Callback"); 
 
  return undef;
}



# called when definition is undefined 
# (config reload, shutdown or delete of definition)
sub SnapControl_Undef($$)
{
  my ($hash, $name) = @_;
 
  # close the connection 
  DevIo_CloseDev($hash);
  
  return undef;
}

# called repeatedly if device disappeared
sub SnapControl_Ready($)
{
  my ($hash) = @_;
  
  # try to reopen the connection in case the connection is lost
  return DevIo_OpenDev($hash, 1, "SnapControl_Init", "SnapControl_Callback"); 
}

# called when data was received
sub SnapControl_Read($)
{
  my ($hash) = @_;
  my $name = $hash->{NAME};
  
  # read the available data
  my $buf = DevIo_SimpleRead($hash);
  
  #Log 1, "SnapControl ($name) - received: $buf";
  
  # stop processing if no data is available (device disconnected)
  return if(!defined($buf));
  my $response;
  {
	local $@;
	$response = eval { decode_json($buf) };
	if($@){
		$zwERG .= $buf;  #decode failed -> must be combined with previous String
	}
  }
  
  {
	local $@;
	if(!($response)){
		my $response = eval { decode_json($zwERG) };
	}
	if($@){
		$zwERG = "";
		#combined Strings make up a valid JSON
		#zwERG is cleared for next JSON combination
		if($response->{id} eq "9"){
			#messages with id 9 are SetStream - answers
			if(exists $streamLocations{${$response->{result}->{stream_id}}}){
				my $groupID=$streamClients{$streamLocations{${$response->{result}->{stream_id}}}};
				#Location where Stream was played before will be set idle
				DevIo_SimpleWrite($hash, "{\"id\":10,\"jsonrpc\":\"2.0\",\"method\":\"Group.SetStream\",\"params\":{\"id\":".$groupID."\",\"stream_id\":\"default\"}}",2);
			}
		}elsif($response->{id} eq "10"){
			#messages with id 10 are answers for silencing an old snapclient
				$streamLocations{$recentStream}=$recentLocation;
				$recentStream="";
				$recentLocation="";
		}
	}
  }
}



# called if set command is executed
sub SnapControl_Set($$@)
{
    my ($hash, $name, $cmd, @args) = @_;
    
    my $usage = "unknown argument $cmd, choose one of statusRequest:noArg setStream register setStreamLocation";

    if($cmd eq "statusRequest")
    {
	my $answer = DevIo_Expect($hash, "{\"id\":32494,\"jsonrpc\":\"2.0\",\"method\":\"Server.GetStatus\"}\n", 5);
	chop($answer); #Snapcast-JSON-RPC ends JSON-Objects with \n, which needs to be choped off
	chop($answer);
	chop($answer);
	Log 1, "SnapControl ($name) - received: ".$answer;
	local $@;
	my $response = eval { decode_json($answer)};
	if($@){
		if($response->{id} eq "32494"){
			#messages with id 32494 are server-status answers
			Log3 $name, 5, "SnaPControl ($name) - received: $response"; 
			foreach my $nextGroup (@{$response->{result}->{server}->{groups}}){
				my $groupID=$nextGroup->{id};
				Log3 $name, 5, "a GroupID: $groupID";
				foreach my $nextClient (@{$nextGroup->{clients}}){
					$streamClients{${$nextClient->{id}}}=$groupID;
					#saving every clientID and the groupID of their assigned group
					Log3 $name, 5, "Client Group-Combo: $groupID - ".$streamClients{${$nextClient->{id}}}; 
					}
				}
			}
		}
        #DevIo_SimpleWrite($hash, "{\"id\":32494,\"jsonrpc\":\"2.0\",\"method\":\"Server.GetStatus\"}\n", 2);
    }elsif($cmd eq "setStream")
    {
		if($args[0] eq "spotify")
		{
			if (grep { $_ eq $args[3] } @{$hash->{helper}}){ #check if stream-Name was registered
			Log 1, "{\"id\":8,\"jsonrpc\":\"2.0\",\"method\":\"Stream.AddStream\",\"params\":{\"streamUri\":\"librespot:///librespot?name=".$args[3]."&username=".$args[1]."&password=".$args[2]."&killall=false\"}}\n";
			DevIo_SimpleWrite($hash, "{\"id\":8,\"jsonrpc\":\"2.0\",\"method\":\"Stream.AddStream\",\"params\":{\"streamUri\":\"librespot:///librespot?name=".$args[3]."&username=".$args[1]."&password=".$args[2]."&killall=false\"}}\n", 2);
			} else {
			Log 1, "Authentifikation für Anlegen eines Snapcast Stream fehlgeschlagen,".$args[3]." ist nicht als gültige MAC-Adresse gespeichert!";
			}
        # DevIo_SimpleWrite($hash, "{\"id\":1,\"jsonrpc\":\"2.0\",\"method\":\"Server.GetStatus\"}\n", 2);
		}
    }elsif($cmd eq "register")
    {
		#internal
		push(@{$hash->{helper}},$args[0]);
		foreach ( @{$hash->{helper}} ) {
			Log 1, "ALLOWEDUSERS content:".$_;
		}
		#global array version (deprecated)
		#push(@allowedUsers,$args[0]);
    }elsif($cmd eq "setStreamLocation")
    {
			$recentLocation = $args[0];
			$recentStream = $args[1];
			#save values for use after server-answer
			my $groupID = $streamClients{$args[0]};
			if ($groupID ne ''){
				DevIo_SimpleWrite($hash, "{\"id\":9,\"jsonrpc\":\"2.0\",\"method\":\"Group.SetStream\",\"params\":{\"id\":".$groupID."\",\"stream_id\":\"".$args[1]."\"}}",2);
			}else{
				Log 1, "There is no snapclient with the ID\"".$args[1]."\", snapclient IDs have to be set manually.";
			}
    }
    else
    {
        return $usage;
    }
}
    
# will be executed upon successful connection establishment (see DevIo_OpenDev())
sub SnapControl_Init($)
{
    my ($hash) = @_;

    # send a status request to the device
    #DevIo_SimpleWrite($hash, "{\"id\":32494,\"jsonrpc\":\"2.0\",\"method\":\"Server.GetStatus\"}\n", 2);
	
    
    return undef; 
}

# will be executed if connection establishment fails (see DevIo_OpenDev())
sub SnapControl_Callback($)
{
    my ($hash, $error ) = @_;
    my $name = $hash ->{NAME};

    # create a log emtry with the error message
    Log3 $name, 5, "SnapControl ($name) - error while connecting: error"; 
    
    return undef; 
}

1;

=pod
=begin html

<a id="SnapControl"></a>
<h3>SnapControl</h3>
<ul>
	<i>SnapControl</i> implements an interface to allow communication with a Snapcast-server. It can be used 
	to manually control a Snapcast setup. As part of a greater architecture it can also be used to automatically control
	a Snapcast setup.
	<br><br>
	<a id="SnapControl-define"></a>
	<b>SnapControl</b>
	<ul>
		<code>define &lt;name&gt; SnapControl &lt;SnapserverIP&gt;</code>
		<br><br>
        Example if Snapserver and FHEM-Server are running on the same device: <code>define SNAPCONTROL SnapControl 127.0.0.1</code>
		<br><br>
        The SnapserverIP parameter needs the IPv4-adress of the snapcast server wich needs to be controlled.
	</ul>
	<br>
	<a id="SnapControl-set"></a>
	<b>Set</b><br>
	<ul>
	<br><br>
        Options:
        <ul>
              <li><i>statusRequest</i><br>
                  Writes all available Information about the Snapserver (configured streams, groups of client and the clients themselves)
				  as a json-Object into the log-file.</li>
              <li><i>setStream</i><br>
                  Currently only Spotify-streams are supported. Multiple parameters, which need to be seperated by a space, need to be determined</li>
                  in a set order. With a Spotify Stream this order is: Spotify-account-name, Spotify-account-password, name of the stream.</li>
				  An example or a complete Set-Command would be: "set SNAPCONTROL spotify MisterSpotify password12345 streamName1".</li>
				  The stream-Name must be registered before it can be used.
              <li><i>register</i><br>
                  Registers a stream-name, this is important for when "setStream" is going to be used.</li>
        </ul>
	</ul>
    <br>
</ul>

=end html

=cut