##############################################
# $Id: myUtilsTemplate.pm 21509 2020-03-25 11:20:51Z rudolfkoenig $
#
# Save this file as 99_myUtils.pm, and create your own functions in the new
# file. They are then available in every Perl expression.

package main;

use strict;
use warnings;
use JSON::XS;
use DevIo; # load DevIo.pm if not already loaded


# called upon loading the module SnapControl
sub PresConnect2Snap_Initialize($)
{
  my ($hash) = @_;
  $hash->{DefFn}    = "PresConnect2Snap_Define";
  $hash->{UndefFn}  = "PresConnect2Snap_Undef";
  $hash->{NotifyFn} = "PresConnect2Snap_Notify";
 
}


####################################################
# Define a device the Type is "PresConnect2Snap" 
# 
# e.g. define <name> PresConnect2Snap <deviceName>
#
####################################################
sub PresConnect2Snap_Define($$)
{
  my ($hash, $def) = @_;
  my @a = split("[ \t]+", $def);
  return "Wrong syntax: use define <name> PresConnect2Snap <deviceName>" if(int(@a) != 3);
  my $name = $a[0];
  
  # $a[1] is always equals the module name
  
  # deviceName
  my $dev = $a[2]; 
  my $type = InternalVal($dev, "TYPE", 0); 
  return "no device given" unless($dev);
  return "device should be defined" unless($type);
  return "type of device should be PRESENCE" unless($type eq 'PRESENCE'); # Limits the type of defined device 

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

        	 	Log 2, "$deviceName is in the $room, $macaddr";

	    	}elsif($deviceStatus eq "absent"){
		# if client doesnt detect the device(abesnt), 
		# the name of client(room) wont be shown on the Readings
		# and the state will be absent.

			Log 2, "$deviceName is $deviceStatus, $macaddr";

		}elsif($rssi < -5){
	
			Log 2, "Nobody is in the $room";
	
		}

 
  return undef;

  } # if !$events

} # sub

1;
