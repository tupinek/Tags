# Pragmas.
use strict;
use warnings;

# Modules.
use English qw(-no_match_vars);
use Error::Pure::Utils qw(clean);
use Tags::Output::Raw;
use Test::More 'tests' => 6;

# Test.
eval {
	Tags::Output::Raw->new('');
};
is($EVAL_ERROR, "Unknown parameter ''.\n");
clean();

# Test.
eval {
	Tags::Output::Raw->new('something' => 'value');
};
is($EVAL_ERROR, "Unknown parameter 'something'.\n");
clean();

# Test.
eval {
	Tags::Output::Raw->new('attr_delimeter' => '-');
};
is($EVAL_ERROR, "Bad attribute delimeter '-'.\n");
clean();

# Test.
eval {
	Tags::Output::Raw->new('auto_flush' => 1);
};
is($EVAL_ERROR, 'Auto-flush can\'t use without output handler.'."\n");
clean();

# Test.
eval {
	Tags::Output::Raw->new('output_handler' => '');
};
is($EVAL_ERROR, 'Output handler is bad file handler.'."\n");
clean();

# Test.
my $obj = Tags::Output::Raw->new;
isa_ok($obj, 'Tags::Output::Raw');
