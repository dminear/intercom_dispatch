#!/usr/bin/perl -w

use strict;
use Redis;

my $r = Redis->new( server => 'redis.aududu.com:6379');
$r->auth($ENV{'REDIS_PW'});

my $ip = "192.168.0.104";
my $t = time();
# push message onto list
my $json = "{\"ip\":\"" . $ip . "\",\"time\":" . $t . "}";

my $len = $r->rpush( 'intercom_alert_list', $json );
print "pushed $json, queue length is $len\n";
