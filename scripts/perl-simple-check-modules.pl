#!/usr/bin/perl
use strict;
use local::lib;
#use lib '/home/user/perl5/lib/perl5';
#print "\$0=@ARGV[0]\t\$1=@ARGV[1]\t\$2=$ARGV[2]\n";
#if ( @ARGV[0] =~ /local/ ) { use local::lib; shift @ARGV; }
#else {print "don't use local::lib\n";}

foreach my $module ( @ARGV ) {
  eval "require $module";
  if ( !$@ ) { printf( "%-20s: %s\n", $module, $module->VERSION ) ; }
  else { printf("%-20s: NOT_FOUND\n", $module); }
}

exit 0;

__END__

force a different library:

perl -e 'use strict; use local::lib; use lib "/home/user/lib/perl5"; my $module="Tree::Simple::VisitorFactory"; eval "require $module"; if ( !$@ ) { printf( "%-20s: %s\n", $module, $module->VERSION ) ; } else { printf("%-20s: NOT_FOUND\n", $module); }'

perl -e 'use strict; use local::lib; use lib "/home/otheruser/lib/"; use lib "/home/otheruser/lib/perl5/";
my @lst = qw/ Net::SSLeay Cyrpt::SSLeay /;
foreach my $module ( @lst ) {
eval "require $module";
if ( !$@ ) { printf( "%-20s: %s\n", $module, $module->VERSION ) ; }
else { printf("%-20s: NOT_FOUND\n", $module); }
}'
