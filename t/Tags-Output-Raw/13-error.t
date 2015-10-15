# Pragmas.
use strict;
use warnings;

# Modules.
use English qw(-no_match_vars);
use Error::Pure::Utils qw(clean);
use Tags::Output::Raw;
use Test::More 'tests' => 6;
use Test::NoWarnings;

# Test.
my $obj = Tags::Output::Raw->new(
	'xml' => 1,
);
eval {
	$obj->put(['b', 'TAG']);
};
is($EVAL_ERROR, "In XML must be lowercase tag name.\n");
clean();

# Test.
$obj->reset;
eval {
	$obj->put(['b', 'tag'], ['b', 'tag2'], ['e', 'tag']);
};
is($EVAL_ERROR, "Ending bad tag: 'tag' in block of tag 'tag2'.\n");
clean();

# Test.
$obj->reset;
eval {
	$obj->put(['a', 'key', 'val']);
};
is($EVAL_ERROR, 'Bad tag type \'a\'.'."\n");
clean();

# Test.
$obj->reset;
eval {
	$obj->put(['q', 'key', 'val']);
};
is($EVAL_ERROR, 'Bad type of data.'."\n");
clean();

# Test.
$obj->reset;
eval {
	$obj->put('q');
};
is($EVAL_ERROR, 'Bad data.'."\n");
clean();
