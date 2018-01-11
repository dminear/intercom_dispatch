#!/usr/bin/perl -w

use strict;
use Redis;
use Data::Dumper;
use JSON;
use HTTP::Request::Common qw(POST);
use LWP::UserAgent;


my $debug = 1;

my $r = Redis->new( server => 'redis.aududu.com:6379');

$r->auth($ENV{'REDIS_PW'});

while (1) {
	print "checking alert list...\n" if $debug;
	my $v = $r->blpop( 'intercom_alert_list' , 5);
	if (defined $v ) {
		my $text = $$v[1];
		print "json text is $text\n" if $debug;
		my $j = decode_json $text;
		print Dumper($j) if $debug;
		my $t = time();
		if ($t - $j->{'time'} < 30) {
			print "Send out alerts!!!!\n" if $debug;
			my $sending_ip = $j->{'ip'};

			alertlist( $sending_ip );
		} else {
			print "time expired, no alerts sent.\n" if $debug;
		}
	} else {
		warn "popped off an undef val\n" if $debug;;
	}
}

sub alertlist {
	my $sender = shift;

	print "received alert from $sender\n";
	my $v = $r->hgetall( 'intercom' );
	print "hgetall from intercom is\n" if $debug;
	print Dumper($v) if $debug;
	my %clients = @$v;
	print Dumper(\%clients);
	foreach my $k (keys %clients) {
		my $time = $clients{$k};
		print "working on ip $k at time $time\n" if $debug;
		if (time() - $time > 1230) {	# has not checked in for 20 minutes
			print "deleting stale ip $k from intercom hash\n" if $debug;
			$r->hdel('intercom', $k);
			next;
		}
		if ($sender eq $k) {
			print "same as sender, pausing 3 seconds\n" if $debug;
			sleep(3);
		}
		# looks like we should try to alert this ip
		sendalert( $k );
	}
}

sub sendalert {
	my $ip = shift;

    print "Connecting to $ip to sound alarm\n" if $debug;
    my $ua = LWP::UserAgent->new();
    $ua->timeout(2);
    my $req = POST( 'http://' . $ip . ':14252/', [ n => 'alert', ]);
    my $content = $ua->request($req)->as_string;
    print "returned content is:\n";
	print $content;
}

