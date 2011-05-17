package Tags2::Process::EntitySubstitute;

# Pragmas.
use encoding 'utf8';
use strict;
use warnings;

# Modules.
use Class::Utils qw(set_params);
use Error::Simple::Multiple qw(err);
use List::MoreUtils qw(any);

# Version.
our $VERSION = 0.01;

# Constructor.
sub new {
	my ($class, @params) = @_;
	my $self = bless {}, $class;

	# Entity structure.
	$self->{'entity'} = {};

	# Entity characters to encode/decode.
	$self->{'entity_chars'} = [];

	# Process params.
	set_params($self, @params);

	# Check to hash reference in entity parameter.
	if (ref $self->{'entity'} ne 'HASH') {
		err 'Bad \'entity\' hash reference.';
	}

	# Object.
	return $self;
}

# Encode text strings in data to entity from dtd.
sub encode {
	my ($self, @data) = @_;
	foreach my $i (0 .. $#data) {
		$data[$i] = $self->_encode($data[$i]);
	}

	# Return data.
	return @data;
}

# Decode entity from dtd to text strings.
sub decode {
	my ($self, @data) = @_;
	foreach my $i (0 .. $#data) {
		$data[$i] = $self->_decode($data[$i]);
	}

	# Return data.
	return @data;
}

# Encode characters to '&#[0-9]+;' syntax.
sub encode_chars {
	my ($self, @data) = @_;
	foreach my $i (0 .. $#data) {
		$data[$i] = $self->_encode_chars($data[$i]);
	}

	# Return data.
	return @data;
}

# Decode characters from '&#[0-9]+;' syntax.
sub decode_chars {
	my ($self, @data) = @_;
	foreach my $i (0 .. $#data) {
		$data[$i] = $self->_decode_chars($data[$i]);
	}

	# Return data.
	return @data;
}

# Encode.
sub _encode {
	my ($self, $data) = @_;
	$data = $self->_decode($data);
	if (any { $_ eq '&' } keys %{$self->{'entity'}}) {
		$data =~ s/&/$self->{'entity'}->{'&'}/gms;
		delete $self->{'entity'}->{'&'}
	}
	foreach my $ent (keys %{$self->{'entity'}}) {
		$data =~ s/(?<!&)$ent/$self->{'entity'}->{$ent}/gmsx;
	}
	return $data;
}

# Decode.
sub _decode {
	my ($self, $data) = @_;
	foreach my $ent (keys %{$self->{'entity'}}) {
		$data =~ s/$self->{'entity'}->{$ent}/$ent/gmsx;
	}
	return $data;
}

# Encode chars.
sub _encode_chars {
	my ($self, $data) = @_;
	$data = $self->_decode_chars($data);
	foreach my $ent_char (@{$self->{'entity_chars'}}) {
		my $tmp = '&#'.ord($ent_char).';';
		$data =~ s/$ent_char/$tmp/gms;
	}
	return $data;
}

# Decode chars.
sub _decode_chars {
	my ($self, $data) = @_;
	$data =~ s/&#(\d+);/chr($1)/egms;
	$data =~ s/&#x([\da-fA-F]+);/chr($1)/egmsx;
	return $data;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

 Tags2::Process::EntitySubstitute - Class for entity substitute.

=head1 SYNOPSIS

 TODO

=head1 METHODS

=over 8

=item C<new(%parameters)>

 Constructor.

=over 8

=item C<entity>

 TODO

=item C<entity_chars>

 TODO

=back

=item C<encode($data)>

 TODO

=item C<decode($data)>

 TODO

=item C<encode_chars($data)>

 TODO

=item C<decode_chars($data)>

 TODO

=back

=head1 ERRORS

 Mine:
   Bad 'entity' hash reference.

 From Class::Utils:
   Unknown parameter '%s'.

=head1 EXAMPLE

 TODO

=head1 DEPENDENCIES

L<Error::Simple::Multiple(3pm)>.

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