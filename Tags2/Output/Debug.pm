#------------------------------------------------------------------------------
package Tags2::Output::Debug;
#------------------------------------------------------------------------------

# Pragmas.
use base qw(Tags2::Output::Core);
use strict;
use warnings;

# Modules.
use Error::Simple::Multiple qw(err);

# Version.
our $VERSION = 0.01;

#------------------------------------------------------------------------------
sub new {
#------------------------------------------------------------------------------
# Constructor.

	my ($class, @params) = @_;
	my $self = bless {}, $class;

	# Output separator.
	$self->{'output_sep'} = "\n";

	# Skip bad tags.
	$self->{'skip_bad_tags'} = 0;

	# Process params.
        while (@params) {
                my $key = shift @params;
                my $val = shift @params;
                err "Bad parameter '$key'." if ! exists $self->{$key};
                $self->{$key} = $val;
        }

	# Initialization.
	$self->reset;

	# Object.
	return $self;
}

#------------------------------------------------------------------------------
sub reset {
#------------------------------------------------------------------------------
# Reset.

	my $self = shift;

	# Flush code.
	$self->{'flush_code'} = [];

	return;
}

#------------------------------------------------------------------------------
# Private methods.
#------------------------------------------------------------------------------

#------------------------------------------------------------------------------
sub _put_attribute {
#------------------------------------------------------------------------------
# Attributes.

	my ($self, $data) = @_;
	push @{$self->{'flush_code'}}, 'Attribute';
	return;
}

#------------------------------------------------------------------------------
sub _put_begin_of_tag {
#------------------------------------------------------------------------------
# Begin of tag.

	my ($self, $data) = @_;
	push @{$self->{'flush_code'}}, 'Begin of tag';
	return;
}

#------------------------------------------------------------------------------
sub _put_cdata {
#------------------------------------------------------------------------------
# CData.

	my ($self, $data) = @_;
	push @{$self->{'flush_code'}}, 'CData';
	return;
}

#------------------------------------------------------------------------------
sub _put_comment {
#------------------------------------------------------------------------------
# Comment.

	my ($self, $data) = @_;
	push @{$self->{'flush_code'}}, 'Comment';
	return;
}

#------------------------------------------------------------------------------
sub _put_data {
#------------------------------------------------------------------------------
# Data.

	my ($self, $data) = @_;
	push @{$self->{'flush_code'}}, 'Data';
	return;
}

#------------------------------------------------------------------------------
sub _put_end_of_tag {
#------------------------------------------------------------------------------
# End of tag.

	my ($self, $data) = @_;
	push @{$self->{'flush_code'}}, 'End of tag';
	return;
}

#------------------------------------------------------------------------------
sub _put_instruction {
#------------------------------------------------------------------------------
# Instruction.

	my ($self, $data) = @_;
	push @{$self->{'flush_code'}}, 'Instruction';
	return;
}

#------------------------------------------------------------------------------
sub _put_raw {
#------------------------------------------------------------------------------
# Raw data.

	my ($self, $data) = @_;
	push @{$self->{'flush_code'}}, 'Raw data';
	return;
}

1;
