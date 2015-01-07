#!/usr/bin/perl

##########################################################
## dell-warranty-api.pl
## 	retrieves Dell server warranty status from dell's website
## 
## see also perldoc parse-nagios-objects_cache.pl formatting at the end.
##
## author: Thomas Blanchard - https://github.com/bouktin
## version: 1.03
## revision date: 2013-01-07
##########################################################

use strict;
use warnings;
use XML::Simple;
use LWP::UserAgent;
use Getopt::Long qw(:config no_ignore_case);
use Data::Dumper;
use Pod::Usage;

my $cfg = {
	st => '',
	help => 0,
	apikey => '1adecee8a60444738f280aad1cd87d0e'
};

GetOptions(
	'servicetag|st|s=s' 		=> \$cfg->{st},
	'warranty-only|waronly|quiet|q'	=> \$cfg->{waronly},
	'details'    			=> \$cfg->{details},
	'debug|d'    			=> \$cfg->{debug},
	'usage|help|h'			=> sub { pod2usage(-verbose => 2); exit 1; }
);


if ( $cfg->{st} !~ /[a-zA-Z0-9]{7}/ ) {
	print "the service tag $cfg->{st} is not valid (7 nb or char)\n";
	exit 1;
} 

my $uri = 'https://api.dell.com/support/v2/assetinfo/warranty/tags?apikey='.$cfg->{apikey}.'&svctags='.$cfg->{st};

my $ua = new LWP::UserAgent;
my $response = $ua->get($uri);

if ($cfg->{debug}) { print Dumper($response); }

my $xml_content=$response->decoded_content;

if ($cfg->{debug}) { print "Content:" . $xml_content . "\n"; }

my $xml = new XML::Simple;

my $data = $xml->XMLin($xml_content);


if ($cfg->{debug}) { print Dumper($data); }

if ( exists $data->{"GetAssetWarrantyResult"}->{"a:Faults"}->{"a:FaultException"} ) {
	print "Service tag not recognised - Exception code: " . $data->{"GetAssetWarrantyResult"}->{"a:Faults"}->{"a:FaultException"}->{"a:Code"} . " - Exception message: " .  $data->{"GetAssetWarrantyResult"}->{"a:Faults"}->{"a:FaultException"}->{"a:Message"} . "\n"; 
	exit 1;
}

if ($cfg->{debug}) { print $data->{"GetAssetWarrantyResult"}->{"a:Response"}->{"a:DellAsset"}->{"a:ShipDate"} . "\n"; }

my %properties = ( );
( $properties{"ShipDate"}, undef ) = split /T/, $data->{"GetAssetWarrantyResult"}->{"a:Response"}->{"a:DellAsset"}->{"a:ShipDate"};
$properties{"MachineDescription"} = $data->{"GetAssetWarrantyResult"}->{"a:Response"}->{"a:DellAsset"}->{"a:MachineDescription"};
$properties{"ServiceTag"} = $data->{"GetAssetWarrantyResult"}->{"a:Response"}->{"a:DellAsset"}->{"a:ServiceTag"};
$properties{"EndDate"} = 0;

if ($cfg->{debug}) { print "Ship date: ".$properties{"ShipDate"}."\nDesc:". $properties{"MachineDescription"} ."\n"; }

# my $array = $data->{"GetAssetWarrantyResult"}->{"a:Response"}->{"a:DellAsset"}->{"a:Warranties"}->{"a:Warranty"};
my ( $tmp, $array );
$tmp = $data->{"GetAssetWarrantyResult"}->{"a:Response"}->{"a:DellAsset"}->{"a:Warranties"}->{"a:Warranty"};

#if ( ref($tmp) =~ m/ARRAY/ ) {
#	$array = $tmp;
#} else if ( ref($tmp) =~ m/HASH/

if ( UNIVERSAL::isa( $tmp, "ARRAY" ) ) {
	$array = $tmp;
} elsif ( UNIVERSAL::isa( $tmp, "HASH" ) ) {
	@{$array}[0] = $tmp;
}

#print "ref(...) = " . ref(%$data->{"GetAssetWarrantyResult"}->{"a:Response"}->{"a:DellAsset"}->{"a:Warranties"}->{"a:Warranty"}) ."\n";
if ($cfg->{debug}) { 
	print "ref(...) = " . ref($array) ."\n";
	print "Dumper array: ". Dumper($array);
}

#foreach my $warranty ( %$data->{"GetAssetWarrantyResult"}->{"a:Response"}->{"a:DellAsset"}->{"a:Warranties"}->{"a:Warranty"} ) {
foreach my $warranty ( @{$array} ) {
	
	if ($cfg->{debug}) { 
		print "ref(\$warranty) = " . ref($warranty) ."\n";
		print "warranty loop: " . Dumper($warranty); 
	}
	my $warid = $warranty->{"a:ItemNumber"};
	my ( $endDate, undef ) = split /T/, $warranty->{"a:EndDate"};

	if ($cfg->{debug}) { print "warranty id: $warid\nend date: $endDate\n"; }

	$properties{ $warid } = { $warranty->{"a:ServiceLevelDescription"} => $endDate };

	my $d1 = $endDate;
	my $d2 = $properties{ "EndDate" };
	$d1 =~ s/-//g;
	$d2 =~ s/-//g;
	if ($d2 < $d1) { 
		$properties{ "EndDate" } = $endDate;
		$properties{ "SLDesc" } = $warranty->{"a:ServiceLevelDescription"};
	}
	if ($cfg->{debug}) { print "d1 (loop Date) = $d1\nd2 (end Date) = $d2\n"; }
}

if ($cfg->{debug}) { print Dumper(\%properties); }
# print svctag;war_type;system_info;sthip_date;end_date
if ( $cfg->{waronly} ) {
	print $properties{"EndDate"}."\n";
} elsif ( $cfg->{details} ) {
	print Dumper(\%properties);
} else {
	print $properties{"ServiceTag"} .";". $properties{"SLDesc"} .";". $properties{"MachineDescription"} .";". $properties{"ShipDate"} .";". $properties{"EndDate"} ."\n"; # .";". $properties{""} ."\n";
}

exit 0;

=pod

=head1 NAME

dell-warranty-api.pl

=head1 VERSION

=over 4

=item version 
1.03

=item last revision
2013-01-07

=back

=head1 SYNOPSIS

This script retrieves the shipping date, warranty end and equipment description for dell machines.
the output is a CSV file (separator semi-colon ";" ) containing the warranty information as:

svctag;war_type;system_info;sthip_date;end_date

start_date and end_date in the ISO format YYYY-MM-DD

=head1 USAGE

=head2 General Usage

dell-warranty-api.pl -st 123ABCD [-debug] [-help] [[-]-warranty-only|-waronly|-q] [--details]

 ### quick batch usage:
 # copy and paste from excel into a variable:
 [user@server inventory]$ LST="ABC1234 
 > BCD2345
 > CDE4567
 > DEF5678"
 # and then run:
 [user@server inventory]$ for st in $LST; do ./check-dell-warranty.pl -st $st; done
 ABC1234;Next Business Day;DELL;09/10/2005;09/10/2008
 BCD2345;Next Business Day;DELL;12/02/2005;12/02/2008
 CDE4567;Next Business Day;DELL;22/09/2005;22/09/2008
 DEF5678;4 Hour On-Site Service;PE1850 3.2GHz/1MB XNN,800 FSB;2005-05-12;2008-05-12
 
 ### batch usage from file
 LST=`awk -F";" '{print \$2}' file`;
 OR derectly:
 cat file | while read st; do ./check-dell-warranty.pl -st \$st; done

=over 4

=item B<Location:> 
You can use it pretty much anywhere. It needs Data::Dumper Getopt::Long Pod::Usage XML::Simple LWP::UserAgent.


=item B<Instalation:> 
Place in an executable path for ease.

=back

=head2 Options

=over 4

=item B<-h :> 
ask for help

=item B<-d :> 
debug version, returns lots of crap

=item B<-st :> 
the service tag to check the warranty for (7 alphanumeric charatcers ([a-zA-Z0-9]))

=item B<--waronly :> 
display only the warranty end

=item B<--details :> 
display details about all the warranty found

=back

=head1 SOURCES

Use apis:
https://api.dell.com/support/v2/assetinfo/warranty/tags?apikey=1adecee8a60444738f280aad1cd87d0e&svctags=1234ABC
http://lists.us.dell.com/pipermail/linux-poweredge/2012-February/045959.html
https://gist.github.com/1893036

=head1 TODO

=head1 BUGS

none known, please report any to the author.

=head1 AUTHOR

Thomas Blanchard, C<< <thomasfp.blanchard@gmail.com> >>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2013 Thomas Blanchard
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:
    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of the <organization> nor the
      names of its contributors may be used to endorse or promote products
      derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL <COPYRIGHT HOLDER> BE LIABLE FOR ANY
DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut


