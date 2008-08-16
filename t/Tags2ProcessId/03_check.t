# $Id: 03_check.t,v 1.1 2008-07-30 11:14:52 skim Exp $

print "Testing: check() method.\n" if $debug;
my $obj = $class->new;
eval {
	$obj->check(
		['b', 'tag'],
		['a', 'id', 'value'],
		['e', 'tag'],
	);
};
ok($@, '');

$obj->reset;
eval {
	$obj->check(
		['b', 'tag'],
		['a', 'id', 'value'],
		['a', 'id', 'value2'],
		['e', 'tag'],
	);
};
ok($@, "Other id attribute in tag 'tag'.\n");

$obj->reset;
eval {
	$obj->check(
		['b', 'tag'],
		['a', 'id', 'value', 'id', 'value2'],
		['e', 'tag'],
	);
};
ok($@, "Other id attribute in tag 'tag'.\n");

$obj->reset;
eval {
	$obj->check(
		['b', 'tag'],
		['a', 'id', 'value'],
		['e', 'tag'],
		['b', 'tag'],
		['a', 'id', 'value'],
		['e', 'tag'],
	);
};
ok($@, "Id attribute 'value' in tag 'tag' is duplicit over structure.\n");