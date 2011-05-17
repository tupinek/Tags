package Tags::Utils;

# Pragmas.
use base qw(Exporter);
use strict;
use warnings;

# Modules.
use Error::Simple::Multiple qw(err);
use HTML::Entities;
use Readonly;

# Constants.
Readonly::Array our @EXPORT_OK => qw(encode_newline encode_attr_entities
	encode_char_entities);
Readonly::Scalar my $ATTR_CHARS => q{<&"};
Readonly::Scalar my $CHAR_CHARS => q{<&\240};
Readonly::Scalar my $EMPTY_STR => q{};

# Version.
our $VERSION = 0.01;

# Encode newline in data to '\n' in output.
sub encode_newline {
	my $string = shift;
	$string =~ s/\n/\\n/gms;
	return $string;
}

# Encode '<&"' attribute entities.
sub encode_attr_entities {
	my $data_r = shift;
	if (ref $data_r eq 'SCALAR') {
		${$data_r} = encode_entities(decode_entities(${$data_r}),
			$ATTR_CHARS);
	} elsif (ref $data_r eq 'ARRAY') {
		foreach my $one_data (@{$data_r}) {
			encode_attr_entities(\$one_data);
		}
	} elsif (ref $data_r eq $EMPTY_STR) {
		return encode_entities(decode_entities($data_r), $ATTR_CHARS);
	} else {
		err 'Reference \''.(ref $data_r).'\' doesn\'t supported.';
	}
	return;
}

# Encode '<&NBSP' char entities.
sub encode_char_entities {
	my $data_r = shift;
	if (ref $data_r eq 'SCALAR') {
		${$data_r} = encode_entities(decode_entities(${$data_r}),
			$CHAR_CHARS);
	} elsif (ref $data_r eq 'ARRAY') {
		foreach my $one_data (@{$data_r}) {
			encode_char_entities(\$one_data);
		}
	} elsif (ref $data_r eq $EMPTY_STR) {
		return encode_entities(decode_entities($data_r), $CHAR_CHARS);
	} else {
		err 'Reference \''.(ref $data_r).'\' doesn\'t supported.';
	}
	return;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

 Tags::Utils - Utils module for Tags.

=head1 SYNOPSIS

 use Tags::Utils qw(encode_newline encode_attr_entities encode_char_entities);
 my $string_with_encoded_newline = encode_newline("foo\nbar");
 my $string_with_encoded_attr_entities = encode_attr_entities('<data & "data"');
 my $string_with_encoded_char_entities = encode_char_entities('<data & data');

=head1 SUBROUTINES

=over 8

=item C<encode_newline($string)>

 Encode newline to '\n' string.

=item C<encode_attr_entities($data_r)>

 Decode all '&..;' strings.
 Encode '<', '&' and '"' entities to '&..;' string.

 $data_r can be:
 - Scalar. Returns encoded scalar.
 - Scalar reference. Returns undef.
 - Array reference of scalars. Returns undef.

=item C<encode_char_entities($data_r)>

 Decode all '&..;' strings.
 Encode '<', '&' and 'non-break space' entities to '&..;' string.

 $data_r can be:
 - Scalar. Returns encoded scalar.
 - Scalar reference. Returns undef.
 - Array reference of scalars. Returns undef.

=back

=head1 ERRORS

 encode_newline():
   None.

 encode_attr_entities():
   Reference '%s' doesn't supported.

 encode_char_entities():
   Reference '%s' doesn't supported.

=head1 EXAMPLE1

 # Pragmas.
 use strict;
 use warnings;

 # Modules.
 use Tags::Utils qw(encode_newline);

 # Input text.
 my $text = <<'END';
 foo
 bar
 END

 # Encode newlines.
 my $out = encode_newline($text);

 # In $out:
 # foo\nbar\n

=head1 EXAMPLE2

 # Pragmas.
 use strict;
 use warnings;

 # Modules.
 use Tags::Utils qw(encode_attr_entities);

 # Input data.
 my @data = ('&', '<', "\240", '&nbsp;');

 # Encode.
 encode_attr_entities(\@data);

 # In @data:
 # (
 #         '&amp;',
 #         '&lt;',
 #         '&nbsp;',
 #         '&nbsp;',
 # )

=head1 DEPENDENCIES

L<HTML::Entities(3pm)>,
L<Error::Simple::Multiple(3pm)>,
L<Readonly(3pm)>.

=head1 SEE ALSO

L<Tags(3pm)>,
L<Tags::Output::Core(3pm)>,
L<Tags::Output::Raw(3pm)>.

=head1 AUTHOR

Michal Špaček L<skim@cpan.org>

=head1 LICENSE AND COPYRIGHT

BSD license.

=head1 VERSION

0.01

=cut
