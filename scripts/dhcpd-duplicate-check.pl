#!/usr/bin/perl

##########################################################
## dhcpd-duplicate-check.pl
## 	checks the presence of duplicate files
##
## author: Thomas Blanchard - thomasfp.blanchard@gmail.com
## version: 1.02
## last revision: 2014-03-14
##########################################################

use local::lib;
use strict;
use warnings;
use Net::MAC;
use Data::Dumper;
use Getopt::Long qw(:config no_ignore_case);

my $dhcpfile="/etc/dhcp/dhcpd.conf";
#my @VERBOSITY= qw/ 1 2 3 4 5/;
my $verbose = 1;	# 0 = quiet, exit state only, 1: summary state, 2:detail of problem, 3: small debug , 4: verbose debug
my ($group , $host, $mac) = qw(dummy dummy 0);
my ( %l_mac, %l_host );
my ($mac_dup , $host_dup) = ( 0 , 0 );

my ($UNKNOWN, $CRITICAL, $WARNING, $OK) = (3, 2, 1, 0);
my $EXIT_STATE=$OK;

GetOptions(
	"file|f=s"	=> \$dhcpfile ,
	"verbose|v|d=i"	=> \$verbose,
	"help|h"	=> sub { usage(); exit 0; }
);

sub usage {
	print qq{Usage: $0 --file|-f FILE-TO-CHECK [--verbose VERBOSITY] [--help|-h]
Where:
	VERBOSITY	0 = quiet (exit state only), 1: summary state (default), 2:detail of problem, 3: small debug , 4: verbose debug
	
	}
}

open DHCPDCONF, "<$dhcpfile" or die "impossible to open the file";

while (<DHCPDCONF>) {
	my $line = $_;
	# if comment, skip loop
	if ( $line =~ /^[[:blank:]]*#/ ) { next; }
	#if ($verbose) { print "line:$line" ;}
	## if matches: /group GROUPNAME {/
	## then create group
	if ( $line =~ /group[[:blank:]]+([[:alnum:]-]+)[[:blank:]]*{/ ) {
		$group = $1;
		if ($verbose >= 3) { print "group: $group \n";}
	}

	## if matches: /host HOSTNAME {/
	## then create host
	if ( $line =~ /host[[:blank:]]+([[:alnum:].-]+)[[:blank:]]*{/ ) {
		$host = $1;
		if ($verbose >= 3) { print "host: $host \n";}
	}

	## if matches: /hardware ethernet 00:30:d3:06:28:38;/
	## create Net:MAC
	## dump Net:MAC into list
	## save hostname
	## save group
	if ( $line =~ /hardware ethernet ([a-fA-F0-9:]+)/ ) {
		$mac = Net::MAC->new("mac" => $1)->convert()->get_mac();
		if ($verbose >= 3) { print "mac: $mac (based on $1)\n";}
		my ( @tmp_m, @tmp_h ) = ( (), () );
		# complete mac list
		push @tmp_h, @{$l_mac{$mac}} if defined $l_mac{$mac};
		push @tmp_h, $host;
		@{$l_mac{$mac}} = @tmp_h;
		
		# complete host list
		push @tmp_m, @{$l_host{$host}} if defined $l_host{$host};
		push @tmp_m, $mac;
		@{$l_host{$host}} = @tmp_m;
		
		if ($verbose >= 4) { print "mac: $mac - host $host - group $group - tmp mac array @tmp_m - tmp hsot array @tmp_h \n"; }
	}
	
	## read line extract mac /hardware ethernet 00:30:d3:06:28:38;/
	## read line extract fixed-address /fixed-address console.server.example.com;/
	
	## if matches: /}/
	## close HOSTNAME
	## close GROUPNAME
	if ( $line =~ /}/ ) {
		$host="dummy";
		if ($verbose >= 4) { print "end of host or group"; }
	}
}

if ($verbose >= 4) { print "Dumper \%l_mac: \n" . Dumper(\%l_mac); }

foreach my $tmp_mac (keys %l_mac) {
	#$mac = $_;
	my @tmp = @{$l_mac{$tmp_mac}};
	if ($verbose >= 3) { print "nb element: ".@tmp."\t content: @tmp\n"; }
	if ( @tmp > 1 ) {
		if ($verbose >= 2) { print "Duplicate MAC: $tmp_mac - hosts: @tmp \n"; }
		$mac_dup++;
	}
}

foreach my $tmp_host (keys %l_host) {
	#$host = $_;
	my @tmp = @{$l_host{$tmp_host}};
	if ($verbose >= 3) { print "nb element: ".@tmp."\t content: @tmp\n"; }
	if ( @tmp > 1 ) {
		if ($verbose >= 2) { print "Duplicate HOST: $tmp_host - MAC ADDR: @tmp \n"; }
		$host_dup++;
	}
}


if ($mac_dup > 0 || $host_dup > 0) {
	if ($verbose >= 1) { print "Found $mac_dup duplicate MAC addr and $host_dup duplicate HOST in the file $dhcpfile \n"; }
	$EXIT_STATE=$CRITICAL;
} else {
	if ($verbose >= 1) { print "Found no duplicate in the file $dhcpfile \n"; }
	$EXIT_STATE=$OK;
}

exit $EXIT_STATE;

# perl -e 'use Net::MAC; my $mac = Net::MAC->new("mac" => "0:3:ba:2c:f7:a6"); my $newmac= $mac->convert(); print $newmac->get_mac(), "\n"; '
# perl -e 'use Net::MAC; print Net::MAC->new("mac" => "0:3:ba:2c:f7:a6")->convert()->get_mac(), "\n"; '

#/^([0-9a-f]{2}([:-]|$)){6}$/i


