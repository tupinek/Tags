# Modules.
use Tags2::Output::ESIS;
use Test::More 'tests' => 1;

print "Testing: Comment.\n";
my $obj = Tags2::Output::ESIS->new;
$obj->put(
	['c', 'comment'],
	['c', ' comment '],
);
my $ret = $obj->flush;
my $right_ret = <<'END';
_comment
_ comment 
END
chomp $right_ret;
is($ret, $right_ret);