#------------------------------------------------------------------------------
package Tags2::Utils;
#------------------------------------------------------------------------------

# Pragmas.
use base qw(Exporter);
use strict;
use warnings;

# Modules.
use Readonly;
use HTML::Entities;

# Constants.
Readonly::Array our @EXPORT_OK => qw(encode_newline encode_base_entities);

# Version.
our $VERSION = 0.01;

#------------------------------------------------------------------------------
sub encode_newline {
#------------------------------------------------------------------------------
# Encode newline in data to '\n' in output.

	my $string = shift;
	$string =~ s/\n/\\n/gms;
	return $string;
}

#------------------------------------------------------------------------------
sub encode_base_entities {
#------------------------------------------------------------------------------
# Encode '<>&' base entities.
# TODO Other types.

	my $data_r = shift;
	if (ref $data_r eq 'SCALAR') {
		${$data_r} = encode_entities(${$data_r}, '<>&');
		return;
	} elsif (ref $data_r eq 'ARRAY') {
		foreach my $one_data (@{$data_r}) {
			encode_base_entities(\$one_data);
		}
	} else {
		return encode_entities($data_r, '<>&');
	}
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

 Tags2::Utils - Utils module for Tags2.

=head1 SYNOPSIS

 use Tags2::Utils qw(encode_newline encode_base_entities);
 TODO

=head1 SUBROUTINES

=over 8

=item B<encode_newline($string)>

 TODO

=item B<encode_base_entities($data_r)>

 TODO

=back

=head1 ERRORS

 No errors.

=head1 EXAMPLE

 # Pragmas.
 use strict;
 use warnings;

 # Modules.
 use Tags2::Utils qw(TODO);

 TODO

=head1 DEPENDENCIES

L<Readonly(3pm)>,
L<HTML::Entities(3pm)>.

=head1 SEE ALSO

L<Tags2(3pm)>,
L<Tags2::Output::Core(3pm)>,
L<Tags2::Output::ESIS(3pm)>,
L<Tags2::Output::Indent(3pm)>,
L<Tags2::Output::LibXML(3pm)>,
L<Tags2::Output::PYX(3pm)>,
L<Tags2::Output::Raw(3pm)>,
L<Tags2::Output::SESIS(3pm)>.

=head1 AUTHOR

Michal Špaček L<tupinek@gmail.com>

=head1 LICENSE AND COPYRIGHT

BSD license.

=head1 VERSION

0.01

=cut
