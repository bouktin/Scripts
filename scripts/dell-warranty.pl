#!/usr/bin/perl

##########################################################
## dell-warranty.pl
##
## author: Thomas Blanchard - bouktin@gmail.com
## version: 1.00
## last revision: 2011-10-11
##########################################################

use strict;
use warnings;
use Encode;
use HTTP::Request;
use HTML::TableExtract;
use LWP::UserAgent;
use Getopt::Long qw(:config no_ignore_case);

my $cfg = {
	st => '',
	type => 'warranty',
	suffix => '',
	from => 'uk',
	help => 0
};

GetOptions(
	'servicetag|st|s=s' => \$cfg->{st},
	'warranty|w'	=> sub { $cfg->{type}='warranty'; },
	'config|c'	=> sub { $cfg->{type}='config'; },
	'type|t'	=> sub { $cfg->{type}='type'; },
	'from|f:s'	=> \$cfg->{from},
	'help|h'    => \$cfg->{help},
	'debug|d'    => \$cfg->{debug}
);

SWITCH: {
	if ( $cfg->{type} =~ /warranty/ ) { $cfg->{suffix} =''; last SWITCH; }
	if ( $cfg->{type} =~ /config/ ) { $cfg->{suffix} ='&~tab=2'; last SWITCH; }
	if ( $cfg->{type} =~ /type/ ) { $cfg->{suffix} =''; last SWITCH; }
	$cfg->{suffix}='';
}

if ( $cfg->{help} ) {
	print qq{$0 {-t[ype]|-w[arranty]|-c[onfig]} -st 123ABCD [-from {us|uk}] [-debug] [-help]\n
The 'from' option can be either 'uk' or 'us' (lower case).\nThe main difference is the locale, i.e. the warranty date format: dd/mm/yyyy for uk and [m]m/[d]d/yyyy for us.
	type:	retrieves the type of the hardware (server model, chassis) based on the "System Type:" field in the web page
	warranty:	retrieves the warranty of the hardware\n

### quick batch usage:
# copy and paste from excel into a variable:
[tblanchard\@fs1.vclk.net inventory]\$ LST="7VD1W1J
> 6CCNH1J
> 4Z75V1J
> G1R3J71
> "
# and then run:
[tblanchard\@fs1.vclk.net inventory]\$ for st in \$LST; do ./table-parse-dell.pl -w -st \$st; done
7VD1W1J;Next Business Day;DELL;09/10/2005;09/10/2008;0,
6CCNH1J;Next Business Day;DELL;12/02/2005;12/02/2008;0,
4Z75V1J;Next Business Day;DELL;22/09/2005;22/09/2008;0,
G1R3J71;4 Hour On-Site Service;UNY;12/05/2006;11/05/2008;0,

### batch usage from file
LST=`awk -F";" '{print \$2}' file`;

};
	exit 0;
}

my $uri;

# Chose the Europe or US website
if ( $cfg->{from} =~ /uk/ ) {
	$uri = 'http://support.euro.dell.com/support/topics/topic.aspx/emea/shared/support/my_systems_info/en/details?' .
		encode("iso-8859-1", 'c=uk&servicetag=' . $cfg->{st} . $cfg->{suffix});
}
else {
    $uri = 'http://support.dell.com/support/topics/global.aspx/support/my_systems_info/details?' . 
        encode("iso-8859-1", 'c=us&servicetag=' . $cfg->{st} . $cfg->{suffix});
}

# Fetch the page
my $ua = new LWP::UserAgent;
my $req = new HTTP::Request 'GET', $uri;
$req->content_type('application/x-www-form-urlencoded');
if ($cfg->{debug}) {print "req as string: " . $req->as_string . "\n";}

my $html_string = $ua->request($req);
if ($html_string->is_success) {
    #print $webRes->decoded_content."\n";  # or whatever
    if ($cfg->{debug}) { print $html_string->status_line."\n";}     # or whatever
}
else {
     die $html_string->status_line."\n";
}

# Extract the right table from the page
my $te;
SWITCH: {
	if ( $cfg->{type} =~ /warranty/ ) { $te = HTML::TableExtract->new( attribs => { class => "contract_table" } ); last SWITCH; }
	if ( $cfg->{type} =~ /config/ ) { $te = HTML::TableExtract->new( depth => 5, count => 4 ); last SWITCH; }
	if ( $cfg->{type} =~ /type/ ) { $te = HTML::TableExtract->new( depth => 5, count => 3 ); last SWITCH; }
	$te = HTML::TableExtract->new( attribs => { class => "contract_table" } );
}

# Parse the content of the table
$te->parse($html_string->content);

SWITCH: {
	if ( $cfg->{type} =~ /warranty/ ) {
        foreach my $ts ($te->tables) {
            if ($cfg->{debug}) {print "Table (", join(',', $ts->coords), "):\n";}
            foreach my $row ($ts->rows) {
                print ($cfg->{st}. ";" . join(';', @$row) . ",") if ( @$row[0] !~ /Description/);
            }
        }
        print "\n";
        last SWITCH;
    }
    if ( $cfg->{type} =~ /config/ ) {
        print $cfg->{st}.";";
        eval {
            foreach my $row ($te->rows) {
                if (defined @$row[2]) {
                    my $r = @$row[2];
                    $r =~ s/[^a-zA-Z0-9[:blank:]]+//g;
                    if ($r =~ /memory|hd|cisco/i ) { print "$r,"};
                    if ($cfg->{debug}) {print "row:". join(';', @$row)."\n"};
                }
            }
        };
        print "\n";
        last SWITCH;
    }
    if ( $cfg->{type} =~ /type/ ) {
        print $cfg->{st}.";";
        foreach my $row ($te->rows) {
            if (defined @$row[0]) {
                my $r = @$row[0];
                if ($r =~ /System Type:/i ) { print @$row[1]};
                if ($cfg->{debug}) {print "row:". join(';', @$row)."\n"};
            }
        }
        print "\n";
        last SWITCH;
    }
    
}

