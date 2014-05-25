#!/usr/bin/perl

# author: Thomas Blanchard - thomasfp.blanchard@gmail.com
# version: 0.2
# version date: 2014-05-25
# purpose: Retrieves a specific server's data from a spacewalk server

use strict;
use warnings;
use Frontier::Client;
use Data::Dumper;

# host is the spacewalk server, query is the server we want information about
my $cfg = {
	host => "spacewalk.example.net",
	user => "admin",
	passwd => "password",
	query => 'some-arbitrary-server.example.net',
};

my $client = new Frontier::Client(url => "http://".$cfg->{"host"}."/rpc/api");
my $session = $client->call('auth.login', $cfg->{"login"}, $cfg->{"password"});

if (defined $ARGV[0]) {$cfg->{"query"}=$ARGV[0];}

sub get_system_id () {
    my $info =  $client->call('system.getId', $session, $cfg->{"query"});
    if(@$info ==  0){
        print "Exact client".$cfg->{"query"}." not found, making a search query, this may take some time.\n";
        my $hostex = "^" . $cfg->{"query"} . ".*?";
        $info =  $client->call('system.searchByName', $session, $hostex);
        if(@$info ==  0){
            print "Didn't find ".$cfg->{"query"}." or a regex $hostex. Giving up.\n";
            #push @failed,$host;

            exit 1;
        }
        elsif(@$info > 1){
            print "More than one match. Cowardly refusing to guess.\n";
            #push @failed,$host;
            exit 1;
        }
    }
	return (@$info[0])->{id};
}

sub display_data ($$) {
	(my $data, my $how) = @_;
	if ($how eq "csv") {
		# print "systemid;hostname;product;servicetag;os;memory;cpu;uptime"
		printf("%s;%s;%s;%s;%s;%s;%s;%s\n", 
				$data->{"systemid"}, 
				$data->{"hostname"}, 
				$data->{"dmiinfos"}->{'product'}, 
				$data->{"servicetag"}, 
				join (".", ($data->{"os"}, $data->{"release"}, $data->{"arch"}) ),
				$data->{"meminfos"}->{"ram"} ,
				$data->{"getCpu"}->{"count"},
				$data->{"uptime"} );
	} else {
		# full / pretty display
		printf("systemid: %s\nhostname: %s\nmodel: %s\nservice tag: %s\nos: %s\nmemory (MB): %s\ncpu: %s\nuptime: %s\n", 
				$data->{"systemid"}, 
				$data->{"hostname"}, 
				$data->{"dmiinfos"}->{'product'}, 
				$data->{"servicetag"}, 
				join (".", ($data->{"os"}, $data->{"release"}, $data->{"arch"}) ),
				$data->{"meminfos"}->{"ram"} ,
				$data->{"getCpu"}->{"count"},
				$data->{"uptime"} );
		print "See more system details on spacewalk: https://".$cfg->{"host"}."/rhn/systems/details/SystemHardware.do?sid=". $data->{"systemid"} . "\n";
	}
}

sub get_data ($$) {
    (my $systemid, my $hostname) = @_;
	my $data = ();
	$data->{"systemid"} = $systemid;
	$data->{"hostname"} = $hostname;
	$data->{"getDetails"} = $client->call('system.getDetails', $session, $systemid);
	$data->{"dmiinfos"} = $client->call('system.getDmi', $session, $systemid);
	$data->{"meminfos"} = $client->call('system.getMemory', $session, $systemid);
	$data->{"getCpu"} = $client->call('system.getCpu', $session, $systemid);
	$data->{"getCustomValues"} = $client->call('system.getCustomValues', $session, $systemid);
	#$data->{"devinfos"} = $client->call('system.getDevices', $session, $systemid);
	#print Dumper ($data);

	# extract service tag from dmiinfos->asset
	($data->{"servicetag"}) = ($data->{"dmiinfos"}->{"asset"} =~ /.*\(system: (\w{7})\)$/);
	if (! defined $data->{"servicetag"}) { $data->{"servicetag"} = "unknown"; }

	# extract OS information from getDetails->description
	($data->{"os"},$data->{"release"},$data->{"arch"}) = ($data->{"getDetails"}->{"description"} =~ /.*\nOS: (\S+)\nRelease: (\S+)\nCPU Arch: (\S+)/m);
	if (! defined $data->{"os"}) { $data->{"os"} = "unknown"; }
	
	# extract uptime information from getDetails->last_boot
	## $data->{"getDetails"}->{"last_boot"} value is: bless( do{\(my $o = '20130409T05:03:31')}, 'Frontier::RPC2::DateTime::ISO8601' ) cf Module's doc
	$data->{"uptime"} = $data->{"getDetails"}->{"last_boot"}->value() ;
	if (! defined $data->{"uptime"}) { $data->{"uptime"} = "unknown"; }
	return $data;
}

my $data = get_data(get_system_id(), $cfg->{"query"});
display_data($data, "full");

exit 0;

