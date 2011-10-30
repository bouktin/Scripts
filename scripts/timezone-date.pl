#!/usr/bin/perl

use strict;
use warnings;

use DateTime;
use DateTime::Format::Strptime;

my @vc_tz = ( 
	( "shanghai", "Asia/Shanghai", "CST"), 
	( "london", "Europe/London", "GMT"), 
	( "los_angeles", "America/Los_Angeles", "PST")
)
my $format_l = map { new DateTime::Format::Strptime(
                pattern => '%Y%m%d %H:%M',
                time_zone => $_[1],
                ) } @vc_tz ;

foreach @tz in @vc_tz {
	print "@tz[0]: "$format_l
}
