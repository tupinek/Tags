# Modules.
use File::Object;
use Tags2::Output::Raw;
use Test::More 'tests' => 2;

# Include helpers.
do File::Object->new->up->file('get_stdout.inc')->serialize;

print "Testing: Output handler.\n";
my $obj = Tags2::Output::Raw->new(
	'output_handler' => \*STDOUT,
	'xml' => 0,
);
my $ret = get_stdout($obj, 1, ['b', 'MAIN'], ['d', 'data'], ['e', 'MAIN']);
is($ret, '<MAIN>data</MAIN>');

$obj = Tags2::Output::Raw->new(
	'auto_flush' => 1,
	'output_handler' => \*STDOUT,
	'xml' => 0,
);
$ret = get_stdout($obj, 1, ['b', 'MAIN'], ['d', 'data'], ['e', 'MAIN']);
is($ret, '<MAIN>data</MAIN>');
