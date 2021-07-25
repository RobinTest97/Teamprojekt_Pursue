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
  $hash->{DefFn}    = "ControlNoti_Define";
  $hash->{UndefFn}  = "ControlNoti_Undef";
  $hash->{NotifyFn} = "ControlNoti_Notify";
 
}

# Enter you functions below _this_ line.
sub PresConnect2Snap_Define($$)
{
  my ($hash, $def) = @_;
  my @a = split("[ \t]+", $def);

  my $name = $a[0];
  
  # $a[1] is always equals the module name "ControlNoti"
  
  # deviceName. define [name] ControlNoti [deviceName]
  my $dev = $a[2]; 

  return "no device given" unless($dev);

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



sub PresConnect2Snap_Notify($$)
{
  my ($hash, $device_hash) = @_;
  my $deviceName      = $device_hash->{NAME}; # device name / hash

  my $room 	      = $device_hash->{READINGS}{room}{VAL};
  my $rssi            = $device_hash->{READINGS}{rssi}{VAL}; # $hash->{READINGS}{"rssi_$deviceName"}{VAL} for RSSIvalue of device
  my $deviceStatus    = $device_hash->{READINGS}{presence}{VAL}; # for status of device: absent/present
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

	    	}elsif($deviceStatus eq "absent"){
		# if client doesnt detect the device(abesnt), 
		# the name of client(room) wont be shown on the Readings
		# and the state will be absent.

			Log 2, "$deviceName is $deviceStatus";

		}elsif($rssi < -5){
	
			Log 2, "Nobody is in the $room";
	
		}

 
  return undef;

  } # if !$events

} # sub

1;
