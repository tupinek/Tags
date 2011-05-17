# Modules.
use Tags2::Output::ESIS;
use Test::More 'tests' => 2;

print "Testing: CDATA.\n";
my $obj = Tags2::Output::ESIS->new;
$obj->put(
	['b', 'tag'],
	['cd', 'aaaaa<dddd>dddd'],
	['e', 'tag'],
);
my $ret = $obj->flush;
my $right_ret = <<'END';
(tag
-aaaaa<dddd>dddd
)tag
END
chomp $right_ret;
is($ret, $right_ret);

$obj->reset;
$obj->put(
	['b', 'tag'],
	['cd', 'aaaaa<dddd>dddd', ']]>'],
	['e', 'tag'],
);
$ret = $obj->flush;
$right_ret = <<'END';
(tag
-aaaaa<dddd>dddd]]>
)tag
END
chomp $right_ret;
is($ret, $right_ret);