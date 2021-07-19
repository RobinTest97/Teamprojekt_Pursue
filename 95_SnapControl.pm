package main;

use strict;
use warnings;
use JSON::XS;
use DevIo; # load DevIo.pm if not already loaded

my $zwERG = "";

# called upon loading the module SnapControl
sub SnapControl_Initialize($)
{
  my ($hash) = @_;

  $hash->{DefFn}    = "SnapControl_Define";
  $hash->{UndefFn}  = "SnapControl_Undef";
  $hash->{SetFn}    = "SnapControl_Set";
  $hash->{ReadFn}   = "SnapControl_Read";
  $hash->{ReadyFn}  = "SnapControl_Ready";
}

my @allowedUsers = ();

# called when a new definition is created (by hand or from configuration read on FHEM startup)
sub SnapControl_Define($$)
{
  my ($hash, $def) = @_;
  my @a = split("[ \t]+", $def);

  my $name = $a[0];
  
  # $a[1] is always equals the module name "SnapControl"
  
  # first argument is the hostname or IP address of the device (e.g. "192.168.1.120")
  my $dev = $a[2]; 

  return "no device given" unless($dev);
  
  # close connection if maybe open (on definition modify)
  DevIo_CloseDev($hash) if(DevIo_IsOpen($hash));  

  # add a default port (1012), if not explicitly given by user
  $dev .= ':1705' if(not $dev =~ m/:\d+$/);

  # set the IP/Port for DevIo
  $hash->{DeviceName} = $dev;
    
  # open connection with custom init and error callback function (non-blocking connection establishment)
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
  
  Log 1, "SnapControl ($name) - received: $buf";
  
  # stop processing if no data is available (device disconnected)
  return if(!defined($buf));
  
  
  my $response = eval { decode_json($buf) };
  if($@){
	$zwERG .= $buf;  #decode failed -> must be combined with next String
  }else {
		$buf = "";
		if($response->{id} eq "32494"){
			Log3 $name, 5, "SnapControl ($name) - received: $response"; 
		}
  }
  
  #
  # do something with $buf, e.g. generate readings, send answers via DevIo_SimpleWrite(), ...
  #
}



# called if set command is executed
sub SnapControl_Set($$@)
{
    my ($hash, $name, $cmd, @args) = @_;
    
    my $usage = "unknown argument $cmd, choose one of statusRequest:noArg on:noArg off:noArg setStream register";

    if($cmd eq "statusRequest")
    {
		Log 1, "SnapControl ($name) - received: ".DevIo_Expect($hash, "{\"id\":32494,\"jsonrpc\":\"2.0\",\"method\":\"Server.GetStatus\"}\n", 5);
        #DevIo_SimpleWrite($hash, "{\"id\":32494,\"jsonrpc\":\"2.0\",\"method\":\"Server.GetStatus\"}\n", 2);
    }
    elsif($cmd eq "on")
    {
         #DevIo_SimpleWrite($hash, "on\r\n", 2);
		 DevIo_CloseDev($hash) if(DevIo_IsOpen($hash));  
		 DevIo_OpenDev($hash, 0, "SnapControl_Init", "SnapControl_Callback");
    }elsif($cmd eq "setStream")
    {
		if($args[0] eq "spotify")
		{
			Log 1, "{\"id\":8,\"jsonrpc\":\"2.0\",\"method\":\"Stream.AddStream\",\"params\":{\"streamUri\":\"librespot:///librespot?name=".$args[3]."&username=".$args[1]."&password=".$args[2]."&killall=false\"}}\n";
		DevIo_SimpleWrite($hash, "{\"id\":8,\"jsonrpc\":\"2.0\",\"method\":\"Stream.AddStream\",\"params\":{\"streamUri\":\"librespot:///librespot?name=".$args[3]."&username=".$args[1]."&password=".$args[2]."&killall=false\"}}\n", 2);
        # DevIo_SimpleWrite($hash, "{\"id\":1,\"jsonrpc\":\"2.0\",\"method\":\"Server.GetStatus\"}\n", 2);
		}
    }elsif($cmd eq "register")
    {
		push(@allowedUsers,$args[0]);
    }
    elsif($cmd eq "off")
    {
         DevIo_SimpleWrite($hash, "{\"id\":1,\"jsonrpc\":\"2.0\",\"method\":\"Server.GetStatus\"}\n", 2);
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