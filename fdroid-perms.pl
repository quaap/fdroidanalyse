#!/usr/bin/perl

use strict;
use warnings;

use utf8;
use open ':encoding(utf8)';


use XML::LibXML;

# Normal + Signature
my @granted = qw(ACCESS_LOCATION_EXTRA_COMMANDS ACCESS_NETWORK_STATE ACCESS_NOTIFICATION_POLICY ACCESS_WIFI_STATE BLUETOOTH BLUETOOTH_ADMIN BROADCAST_STICKY CHANGE_NETWORK_STATE CHANGE_WIFI_MULTICAST_STATE CHANGE_WIFI_STATE DISABLE_KEYGUARD EXPAND_STATUS_BAR GET_PACKAGE_SIZE INSTALL_SHORTCUT INTERNET KILL_BACKGROUND_PROCESSES MANAGE_OWN_CALLS MODIFY_AUDIO_SETTINGS NFC READ_SYNC_SETTINGS READ_SYNC_STATS RECEIVE_BOOT_COMPLETED REORDER_TASKS REQUEST_COMPANION_RUN_IN_BACKGROUND REQUEST_COMPANION_USE_DATA_IN_BACKGROUND REQUEST_DELETE_PACKAGES REQUEST_IGNORE_BATTERY_OPTIMIZATIONS SET_ALARM SET_WALLPAPER SET_WALLPAPER_HINTS TRANSMIT_IR USE_FINGERPRINT VIBRATE WAKE_LOCK WRITE_SYNC_SETTINGS 

BIND_ACCESSIBILITY_SERVICE BIND_AUTOFILL_SERVICE BIND_CARRIER_SERVICES BIND_CHOOSER_TARGET_SERVICE BIND_CONDITION_PROVIDER_SERVICE BIND_DEVICE_ADMIN BIND_DREAM_SERVICE BIND_INCALL_SERVICE BIND_INPUT_METHOD BIND_MIDI_DEVICE_SERVICE BIND_NFC_SERVICE BIND_NOTIFICATION_LISTENER_SERVICE BIND_PRINT_SERVICE BIND_SCREENING_SERVICE BIND_TELECOM_CONNECTION_SERVICE BIND_TEXT_SERVICE BIND_TV_INPUT BIND_VISUAL_VOICEMAIL_SERVICE BIND_VOICE_INTERACTION BIND_VPN_SERVICE BIND_VR_LISTENER_SERVICE BIND_WALLPAPER CLEAR_APP_CACHE MANAGE_DOCUMENTS READ_VOICEMAIL REQUEST_INSTALL_PACKAGES SYSTEM_ALERT_WINDOW WRITE_SETTINGS WRITE_VOICEMAIL FLASHLIGHT com.android.vending.BILLING);

# "Dangerous"
my @notgranted = qw(READ_CALENDAR WRITE_CALENDAR  CAMERA  READ_CONTACTS WRITE_CONTACTS GET_ACCOUNTS  ACCESS_FINE_LOCATION ACCESS_COARSE_LOCATION  RECORD_AUDIO  READ_PHONE_STATE READ_PHONE_NUMBERS CALL_PHONE ANSWER_PHONE_CALLS READ_CALL_LOG WRITE_CALL_LOG ADD_VOICEMAIL USE_SIP PROCESS_OUTGOING_CALLS  BODY_SENSORS  SEND_SMS RECEIVE_SMS READ_SMS RECEIVE_WAP_PUSH RECEIVE_MMS  READ_EXTERNAL_STORAGE WRITE_EXTERNAL_STORAGE);

#Special/internal/privileged
my @other = qw( ACCESS_COARSE_UPDATES ACCESS_LOCATION ACCESS_MOCK_LOCATION ACCESS_SUPERUSER ACCESS_WIMAX_STATE AUTHENTICATE_ACCOUNTS BATTERY_STATS BIND_APPWIDGET BIND_JOB_SERVICE BLUETOOTH_PRIVILEGED CALL_PRIVILEGED CAPTURE_AUDIO_OUTPUT 
 CHANGE_COMPONENT_ENABLED_STATE CHANGE_CONFIGURATION CHANGE_WIMAX_STATE com.android.alarm.permission.SET_ALARM 
 com.android.browser.permission.READ_HISTORY_BOOKMARKS com.android.browser.permission.WRITE_HISTORY_BOOKMARKS 
 com.android.email.permission.ACCESS_PROVIDER com.android.email.permission.READ_ATTACHMENT 
 com.android.launcher.permission.INSTALL_SHORTCUT com.android.launcher.permission.READ_SETTINGS 
 com.android.launcher.permission.UNINSTALL_SHORTCUT com.android.launcher.permission.WRITE_SETTINGS 
 com.android.setting.permission.ALLSHARE_CAST_SERVICE com.android.settings.INJECT_SETTINGS 
 com.android.vending.CHECK_LICENSE DELETE_PACKAGES DEVICE_POWER DOWNLOAD_WITHOUT_NOTIFICATION DUMP 
 FAKE_PACKAGE_SIGNATURE FOREGROUND_SERVICE GET_CLIPS GET_TASKS GLOBAL_SEARCH HARDWARE_TEST INJECT_EVENTS 
 INSTALL_LOCATION_PROVIDER INSTALL_PACKAGES INTERACT_ACROSS_USERS_FULL MANAGE_ACCOUNTS MANAGE_APP_TOKENS MANAGE_USB 
 MEDIA_CONTENT_CONTROL MODIFY_PHONE_STATE MOUNT_UNMOUNT_FILESYSTEMS PACKAGE_USAGE_STATS PERSISTENT_ACTIVITY 
 QUICKBOOT_POWERON READ_APP_BADGE READ_CLIPS READ_INTERNAL_STORAGE READ_LOGS READ_MEDIA_STORAGE READ_OWNER_DATA 
 READ_PROFILE READ_SECURE_SETTINGS READ_SOCIAL_STREAM READ_USER_DICTIONARY REBOOT RECORD_VIDEO RESET_BATTERY_STATS 
 RESTART_PACKAGES ROOT SET_ACTIVITY_WATCHER SET_DEBUG_APP SET_ORIENTATION STORAGE TETHER_PRIVILEGE USB_PERMISSION 
 USE_CREDENTIALS USES_POLICY_FORCE_LOCK WRITE_APN_SETTINGS WRITE_CLIPS WRITE_INTERNAL_STORAGE WRITE_MEDIA_STORAGE 
 WRITE_PROFILE WRITE_SECURE_SETTINGS WRITE_SMS WRITE_USER_DICTIONARY);

# normal permissions to be warry of
my @mywarry = qw(INTERNET BLUETOOTH BLUETOOTH_ADMIN ACCESS_NETWORK_STATE ACCESS_WIFI_STATE CHANGE_NETWORK_STATE CHANGE_WIFI_MULTICAST_STATE CHANGE_WIFI_STATE NFC KILL_BACKGROUND_PROCESSES SET_WALLPAPER TRANSMIT_IR REORDER_TASKS MODIFY_AUDIO_SETTINGS RECEIVE_BOOT_COMPLETED CHANGE_CONFIGURATION USE_CREDENTIALS MANAGE_ACCOUNTS NETWORK WRITE_SYNC_SETTINGS com.android.browser.permission.READ_HISTORY_BOOKMARKS com.android.browser.permission.WRITE_HISTORY_BOOKMARKS );

my @fullwarry;

push @fullwarry, @mywarry;
push @fullwarry, @notgranted;


my $filename = 'index.xml';

open my $fh, '<', $filename;
binmode $fh, ':raw';
my $dom = XML::LibXML->load_xml(IO => $fh);

my $total = 0;
my %permcounts;

my %normalpermsperapp;
my %askpermsperapp;
my %otherpermsperapp;
my %warrypermsperapp;
my %fullwarrypermsperapp;


my @packages;

foreach my $app ($dom->findnodes('/fdroid/application')) {
    $total++;

    my $name = $app->findvalue('./name');
    my $package = $app->findvalue('./id');
    my $permissions = $app->findvalue('./package[1]/permissions'); #Only worry about latest release

    push @packages, $package;
    
    #print "$name, $package:\n";
    for my $perm (split /,\s*/, $permissions) {
        if ($perm =~ /^[A-Z_]+$/ or $perm =~ /^com\.android\./) {
            
            $permcounts{$perm}=0 if !exists $permcounts{$perm};
            $permcounts{$perm}++;
            
            if (grep /^$perm$/, @mywarry) {
                $warrypermsperapp{$package}=0 if !exists $warrypermsperapp{$package};
                $warrypermsperapp{$package}++;
            }
            
            if (grep /^$perm$/, @fullwarry) {
                $fullwarrypermsperapp{$package}=0 if !exists $fullwarrypermsperapp{$package};
                $fullwarrypermsperapp{$package}++;
            }

            if (grep /^$perm$/, @granted) {
                $normalpermsperapp{$package}=0 if !exists $normalpermsperapp{$package};
                $normalpermsperapp{$package}++;
            } elsif (grep /^$perm$/, @notgranted) {
                $askpermsperapp{$package}=0 if !exists $askpermsperapp{$package};
                $askpermsperapp{$package}++;
            } elsif (grep /^$perm$/, @other) {
                $otherpermsperapp{$package}=0 if !exists $otherpermsperapp{$package};
                $otherpermsperapp{$package}++;
            } else {
                print "\tODD:$perm\n";         
            }

            
            #print "\tandroid.permission.$perm\n";
        } else {
            #print "\tXXX $perm\n";            
        }
    }
    #print "\n";
}

print "Total apps: $total\n\n";

print "All perms\n";
print "perm, count, percentage of apps\n";
for my $perm (sort keys %permcounts) {
    my $count = $permcounts{$perm};
    print "$perm\t$count\t" . sprintf("%2.2f", $count/$total*100) . "%\n";
}
print "\n";


print "Normal warry perms\n";
print "perm, count, percentage of apps\n";
for my $perm (sort @mywarry) {
    my $count = $permcounts{$perm} || 0;
    print "$perm\t$count\t" . sprintf("%2.2f", $count/$total*100) . "%\n";
}
print "\n";

print "Ask perms\n";
print "perm, count, percentage of apps\n";
for my $perm (sort @notgranted) {
    my $count = $permcounts{$perm} || 0;
    print "$perm\t$count\t" . sprintf("%2.2f", $count/$total*100) . "%\n";
}
print "\n";



my $normtot = 0;
my $asktot = 0;

my $warrytot = 0;
my $fullwarrytot = 0;

my $awarrytot = 0;
my $afullwarrytot = 0;

print "package, mywarry, fullwarry, norm, ask, other, total(norm + ask + other)\n";


for my $package (sort @packages) {
    my $norm = $normalpermsperapp{$package} || 0;
    my $ask = $askpermsperapp{$package} || 0;
    my $other = $otherpermsperapp{$package} || 0;
    
    my $mywarry = $warrypermsperapp{$package} || 0;
    my $fullwarry = $fullwarrypermsperapp{$package} || 0;
    
    $normtot += $norm;
    $asktot += $ask;

    $warrytot += $mywarry;
    $fullwarrytot += $fullwarry;
    
    $awarrytot++ if $mywarry==0;
    $afullwarrytot++ if $fullwarry==0;
    
    print "$package, $mywarry, $fullwarry, $norm, $ask, $other, ". ($norm + $ask + $other);
    print "\n";    
}

print "\n";    
print "Normal  perms per-app average: " . sprintf("%2.2f", $normtot/$total) . "\n";
print "Ask     perms per-app average: " . sprintf("%2.2f", $asktot/$total) . "\n";

print "Total   perms per-app average: " . sprintf("%2.2f", ($normtot+$asktot)/$total) . "\n";
print "\n";    


print "Warry   perms per-app average: " . sprintf("%2.2f", $warrytot/$total) . "\n";
print "Warry2  perms per-app average: " . sprintf("%2.2f", $fullwarrytot/$total) . "\n";

print "aWarry  apps percentage: " . sprintf("%2.2f", $awarrytot/$total * 100). "\n";
print "aWarry2 apps percentage: " . sprintf("%2.2f", $afullwarrytot/$total * 100) . "\n";

