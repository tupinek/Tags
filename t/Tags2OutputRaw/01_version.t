# $Id: 01_version.t,v 1.2 2007-09-20 14:54:00 skim Exp $

print "Testing: Version.\n" if $debug;
ok(eval('$'.$class.'::VERSION'), '0.03');
