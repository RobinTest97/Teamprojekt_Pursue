##############################################
# $Id: myUtilsTemplate.pm 21509 2020-03-25 11:20:51Z rudolfkoenig $
#
# Save this file as 99_myUtils.pm, and create your own functions in the new
# file. They are then available in every Perl expression.

package main;

use strict;
use warnings;
use JSON::XS;

# name of the SnapControl-device is stored as a global variable
my $snapDev = '';

# called upon loading the module SnapControl
sub PresConnect2Snap_Initialize($)
{
  my ($hash) = @_;
  $hash->{DefFn}    = "PresConnect2Snap_Define";
  $hash->{UndefFn}  = "PresConnect2Snap_Undef";
  $hash->{NotifyFn} = "PresConnect2Snap_Notify";
 
}


########################################################################################################
# Define a device the Type is "PresConnect2Snap" 
# 
# e.g. define <deviceName> PresConnect2Snap <PRESENCE-deviceName> <SnapControl-deviceName>
#
########################################################################################################
sub PresConnect2Snap_Define($$)
{
  my ($hash, $def) = @_;
  my @a = split("[ \t]+", $def);
  return "Wrong syntax: use define <deviceName> PresConnect2Snap <PRESENCE-deviceName> <SnapControl-deviceName>" if(int(@a) != 4);
  my $name = $a[0];
  
# $a[1] is always equals the module name
  
# name of Presence-device
  my $dev = $a[2]; 
  my $type = InternalVal($dev, "TYPE", 0); 
  return "no device given" unless($dev);
  return "device should be defined" unless($type);
  return "type of device should be PRESENCE" unless($type eq 'PRESENCE'); # Limits the type of defined device 

# name of SnapControl-device 
  $snapDev = $a[3];
  my $snapType = InternalVal($snapDev, "TYPE", 0);
  return "type of device should be SnapControl" unless($snapType eq 'SnapControl');

# Limits of specific devices whose NOTIFYDEV is global and TYPE is PRESENCE for the Notify
  $hash->{NOTIFYDEV} = "global,TYPE=PRESENCE";
  
  readingsSingleUpdate($hash, "state", "activate", 1);

  return undef;
}

sub PresConnect2Snap_Undef($$)
{
  my ($hash, $name) = @_; 
  return undef;
}


####################################################
# Trigger a activity when received an event for the
# update of value "room" from PRESENCE.
####################################################
sub PresConnect2Snap_Notify($$)
{
  my ($hash, $device_hash) = @_;
  my $deviceName      = $device_hash->{NAME}; # name of device (value from Internals)
  my $macaddr	      = $device_hash->{ADDRESS}; # Bluetoothe-MAC-address of device (value from Internals)
  my $room 	      = $device_hash->{READINGS}{room}{VAL}; # (value from Readings)
  my $rssi            = $device_hash->{READINGS}{rssi}{VAL}; # $hash->{READINGS}{"rssi_$deviceName"}{VAL} for RSSIvalue of device
  my $deviceStatus    = $device_hash->{READINGS}{presence}{VAL}; # status of device: absent/present
  my $events	      = deviceEvents($device_hash, 1);
 
  my $number          = looks_like_number($room);

  if(!$events){ 
	# When $events is not generated
    Log 1, "nothing happens"; 

  }else{

	# Update Readings
	# All default-value are 0
	readingsBeginUpdate($hash);
	readingsBulkUpdateIfChanged($hash, "presence", $deviceStatus, 1);
	readingsBulkUpdateIfChanged($hash, "room", $room, 1);
	readingsEndUpdate($hash, 0);

		if($deviceStatus eq "present" && $rssi >= -5 && !$number){

        	 	Log 2, "$deviceName is in the $room";
			fhem("set $snapDev setStreamLocation $room $macaddr");
			
	    	}elsif($deviceStatus eq "absent"){
		# if client doesnt detect the device(abesnt) 
		# the value of MAC-Address in SnapControl will be set as default

			Log 2, "$deviceName is $deviceStatus";
			fhem("set $snapDev setStreamLocation $room default");

		}elsif($rssi < -5){
	
			Log 2, "Nobody is in the $room";
	
		}

 
  return undef;

  } # if !$events

} # sub

1;


=pod
=begin html

<a id="PresConnect2Snap"></a>
<h3>PresConnect2Snap</h3>
<ul>
    <i>PresConnect2Snap</i> This modul is used to send parameters "Roomname" and "Bluetooth-MAC-Address" from PRESENCE to SnapControl.
    <br><br>
    <a id="PresConnect2Snap-define"></a>
    <b>Define</b>
    <ul>
        <code>define <deviceName> PresConnect2Snap <PRESENCE-deviceName> <SnapControl-deviceName></code>
        <br><br>
        Example: <code> define PresNoti PresConnect2Snap MyPhone MySnap</code>
        <br><br>
        The first parameter <deviceName> means the name for the device whose type is this modul "PresConnect2Snap".
	Second one <PRESENCE-deviceName> for PRESENCE, thus the used parameter must be already defined as "PRESENCE". 
	If not, it will be shown a Message on FHEM-Web to ask for change. 
	Its in the same way by third parameter <SnapControl-deviceName>, the device must be deined as "SnapControl".
    </ul>
    <br>
    <br>
</ul>

=end html

=cut
