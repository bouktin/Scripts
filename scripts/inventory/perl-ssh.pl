#!/usr/bin/perl -w

##########################################################
## perl-ssh.pl
## 	open an ssh connection and executes a command
## 
## see also perldoc format at the end.
##
## author: Thomas Blanchard - thomasfp.blanchard@gmail.com
## version: 0.03
## last revision: 2014-04-18
##########################################################

#use local::lib;
use strict;
use warnings;
use Getopt::Long qw(:config no_ignore_case);
use Pod::Usage;

use Math::BigInt::GMP;
use Net::SSH::Perl;

my ($UNKNOWN, $CRITICAL, $WARNING, $OK) = (3, 2, 1, 0);
my $EXIT_STATE=$OK;

my $cfg = {
	host => "",
	user => "",
	passwd => "",
	port => "",
	cmd => "",
	verbose => 0
};

GetOptions(
	"host|H=s"	=> \$cfg->{host},
	"user|u=s"	=> \$cfg->{user},
	"password|passwd|p=s"	=> \$cfg->{passwd},
	"port|P=s"	=> \$cfg->{port},
	"cmd|c=s"	=> \$cfg->{cmd},
	"verbose|v|d:i"	=> \$cfg->{verbose},
	"usage|help|h"	=> sub { pod2usage(1); exit $OK; }
);

sub usage {
	print qq{Usage: $0 [--help|-h] -H hostname -u user -p password -P port -c cmd
Where:
	-c cmd		command to run remotely, quoted
	\n}
};

my $ssh = Net::SSH::Perl->new($cfg->{host});
if ($cfg->{verbose} >= 2) { print "DEBUG before login " . scalar (localtime) . "\n"; }
$ssh->login($cfg->{user}, $cfg->{passwd});
if ($cfg->{verbose} >= 2) { print "DEBUG after login, before cmd " . scalar (localtime) . "\n"; }
my($stdout, $stderr, $exit) = $ssh->cmd($cfg->{cmd});
if ($cfg->{verbose} >= 2) { print "DEBUG after cmd " . scalar (localtime) . "\n"; }

print "exit status:\n$exit\n\n" if ($cfg->{verbose} > 0);
print "Err:\n$stderr\n\n" if defined $stderr and ($cfg->{verbose} > 0);

print "$stdout";

$EXIT_STATE=$exit if defined $exit;
exit $EXIT_STATE;

__END__

=pod

=head1 NAME

perl-ssh.pl

=head1 VERSION

=over 4

=item version 
0.03

=item last revision
2014-04-18

=back

=head1 SYNOPSIS

Open an ssh connection and executes a command, providing a host, user, password and command

perl-ssh.pl [--help|-h] [-v|-d|--verbose|--debug] -H hostname -u user -p password -P port -c cmd

run perldoc for detailed help

=head1 USAGE

=head2 General Usage

=over 4

=item B<Dependancies:> 
this package requires Net::SSH::Perl, Getopt::Long and Pod::Usage

=item B<Location:> 
You can use it pretty much anywhere.

=item B<Instalation:> 
Place in an executable path for ease.

=back

=head2 Paramters

=over 4

=item B<-h :> 
ask for help

=item B<-d :> 
see debug infos

=item B<-H|--host :> 
hostname or IP address

=item B<-u|--user :> 
username

=item B<-p|--passwd|--password :> 
Password (note: prompt if not provided)

=item B<-P|--port :> 
ssh port

=item B<-c|--cmd :> 
command to run on the remote host (needs to be quoted "")

=back

=head1 AUTHOR

Thomas Blanchard, C<< <thomasfp.blanchard@gmail.com> >>

=head1 BUGS

=head1 COPYRIGHT & LICENSE

Copyright (c) 2014, Thomas Blanchard
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut
