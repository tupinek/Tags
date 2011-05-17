package Tags2::Output::Raw;

# Pragmas.
use base qw(Tags2::Output::Core);
use strict;
use warnings;

# Modules.
use Error::Simple::Multiple qw(err);
use List::MoreUtils qw(none);
use Readonly;
use Tags2::Utils::Preserve;
use Tags2::Utils qw(encode_attr_entities encode_char_entities);

# Constants.
Readonly::Scalar my $EMPTY_STR => q{};
Readonly::Scalar my $LAST_INDEX => -1;
Readonly::Scalar my $SPACE => q{ };

# Version.
our $VERSION = 0.06;

# Resets internal variables.
sub reset {
	my $self = shift;

	# Comment flag.
	$self->{'comment_flag'} = 0;

	# Flush code.
	$self->_reset_flush;

	# Tmp code.
	$self->{'tmp_code'} = [];
	$self->{'tmp_comment_code'} = [];

	# Printed tags.
	$self->{'printed_tags'} = [];

	# Preserved object.
	$self->{'preserve_obj'} = Tags2::Utils::Preserve->new(
		'preserved' => $self->{'preserved'},
	);

	return;
}

# Check parameters to rigth values.
sub _check_params {
        my $self = shift;

	# Check params from SUPER.
	$self->SUPER::_check_params();

	# Check 'attr_delimeter'.
	if ($self->{'attr_delimeter'} ne q{"}
		&& $self->{'attr_delimeter'} ne q{'}) {

		err "Bad attribute delimeter '$self->{'attr_delimeter'}'.";
	}

	return;
}

# Default parameters.
sub _default_parameters {
	my $self = shift;

	# Default parameters from SUPER.
	$self->SUPER::_default_parameters();

	# Attribute callback.
	$self->{'attr_callback'} = \&encode_attr_entities;

	# Attribute delimeter.
	$self->{'attr_delimeter'} = q{"};

	# CDATA callback.
	$self->{'cdata_callback'} = undef;

	# Data callback.
	$self->{'data_callback'} = \&encode_char_entities;

	# No simple tags.
	$self->{'no_simple'} = [];

	# Output separator. (Rewrite SUPER value.)
	$self->{'output_sep'} = $EMPTY_STR;

	# Preserved tags.
	$self->{'preserved'} = [];

	# Raw data callback.
	$self->{'raw_callback'} = undef;

	# XML output.
	$self->{'xml'} = 0;

	return;
}

# Flush $self->{'tmp_code'}.
sub _flush_tmp {
	my ($self, $string) = @_;

	# Added string.
	push @{$self->{'tmp_code'}}, $string;

	# Detect preserve mode.
	my ($pre, $pre_pre) = $self->{'preserve_obj'}->get;
	if ($pre && ! $pre_pre) {
		push @{$self->{'tmp_code'}}, "\n";
	}

	# Flush comment code before tag.
	if ($self->{'comment_flag'} == 0
		&& scalar @{$self->{'tmp_comment_code'}}) {

		$self->{'flush_code'} .= join $EMPTY_STR,
			@{$self->{'tmp_comment_code'}},
			@{$self->{'tmp_code'}};

	# After tag.
	} else {
		$self->{'flush_code'} .= join $EMPTY_STR,
			@{$self->{'tmp_code'}},
			@{$self->{'tmp_comment_code'}};
	}

	# Resets tmp_codes.
	$self->{'tmp_code'} = [];
	$self->{'tmp_comment_code'} = [];

	return;
}

# Attributes.
sub _put_attribute {
	my ($self, $attr, $value) = @_;

	# Check to 'tmp_code'.
	if (! @{$self->{'tmp_code'}}) {
		err 'Bad tag type \'a\'.';
	}

	# Check to pairs in XML mode.
	if ($self->{'xml'} && ! defined $value) {
		err 'In XML mode must be a attribute value.';
	}

	# Process data callback.
	my @attr = ($attr);
	if (defined $value) {
		push @attr, $value;
	}
	$self->_process_callback(\@attr, 'attr_callback');

	# Process attribute.
	my $full_attr = $attr[0];
	if (defined $attr[1]) {
		$full_attr .= q{=}.$self->{'attr_delimeter'}.
			$attr[1].$self->{'attr_delimeter'};
	}	
	push @{$self->{'tmp_code'}}, $SPACE, $full_attr;

	# Reset comment flag.
	$self->{'comment_flag'} = 0;

	return;
}

# Begin of tag.
sub _put_begin_of_tag {
	my ($self, $tag) = @_;

	# Flush tmp code.
	if (scalar @{$self->{'tmp_code'}}) {
		$self->_flush_tmp('>');
	}

	# XXX Is really?
	# Check to lowercased chars for XML.
	if ($self->{'xml'} && $tag ne lc $tag) {
		err 'In XML must be lowercase tag name.';
	}

	# Push begin of tag to tmp code.
	push @{$self->{'tmp_code'}}, "<$tag";

	# Added tag to printed tags.
	unshift @{$self->{'printed_tags'}}, $tag;

	$self->{'preserve_obj'}->begin($tag);

	return;
}

# CData.
sub _put_cdata {
	my ($self, @cdata) = @_;

	# Flush tmp code.
	if (scalar @{$self->{'tmp_code'}}) {
		$self->_flush_tmp('>');
	}

	# Added begin of cdata section.
	unshift @cdata, '<![CDATA[';

	# Check to bad cdata.
	if (join($EMPTY_STR, @cdata) =~ /]]>$/ms) {
		err 'Bad CDATA data.'
	}

	# Added end of cdata section.
	push @cdata, ']]>';

	# Process data callback.
	$self->_process_callback(\@cdata, 'cdata_callback');

	# To flush code.
	$self->{'flush_code'} .= join $EMPTY_STR, @cdata;

	return;
}

# Comment.
sub _put_comment {
	my ($self, @comments) = @_;

	# Comment string.
	unshift @comments, '<!--';
	if (substr($comments[$LAST_INDEX], $LAST_INDEX) eq q{-}) {
		push @comments, ' -->';
	} else {
		push @comments, '-->';
	}

	# Process comment.
	my $comment = join $EMPTY_STR, @comments;
	if (scalar @{$self->{'tmp_code'}}) {
		push @{$self->{'tmp_comment_code'}}, $comment;

		# Flag, that means comment is last.
		$self->{'comment_flag'} = 1;
	} else {
		$self->{'flush_code'} .= $comment;
	}

	return;
}

# Data.
sub _put_data {
	my ($self, @character_data) = @_;

	# Flush tmp code.
	if (scalar @{$self->{'tmp_code'}}) {
		$self->_flush_tmp('>');
	}

	# Process data callback.
	$self->_process_callback(\@character_data, 'data_callback');

	# To flush code.
	$self->{'flush_code'} .= join $EMPTY_STR, @character_data;

	return;
}

# End of tag.
sub _put_end_of_tag {
	my ($self, $tag) = @_;
	my $printed = shift @{$self->{'printed_tags'}};
	if ($self->{'xml'} && $printed ne $tag) {
		err "Ending bad tag: '$tag' in block of ".
			"tag '$printed'.";
	}

	# Tag can be simple.
	if ($self->{'xml'} && (! scalar @{$self->{'no_simple'}}
		|| none { $_ eq $tag } @{$self->{'no_simple'}})) {

		if (scalar @{$self->{'tmp_code'}}) {
			if (scalar @{$self->{'tmp_comment_code'}}
				&& $self->{'comment_flag'} == 1) {

				$self->_flush_tmp('>');
				$self->{'flush_code'} .= "</$tag>";
			} else {
				$self->_flush_tmp(' />');
			}
		} else {
			$self->{'flush_code'} .= "</$tag>";
		}

	# Tag cannot be simple.
	} else {
		if (scalar @{$self->{'tmp_code'}}) {
			$self->_flush_tmp('>');
		}
		$self->{'flush_code'} .= "</$tag>";
	}
	$self->{'preserve_obj'}->end($tag);

	return;
}

# Instruction.
sub _put_instruction {
	my ($self, $target, $code) = @_;

	# Flush tmp code.
	if (scalar @{$self->{'tmp_code'}}) {
		$self->_flush_tmp('>');
	}

	# To flush code.
	$self->{'flush_code'} .= '<?'.$target;
	if ($code) {
		$self->{'flush_code'} .= $SPACE.$code;
	}
	$self->{'flush_code'} .= '?>';

	return;
}

# Raw data.
sub _put_raw {
	my ($self, @raw_data) = @_;

	# Flush tmp code.
	if (scalar @{$self->{'tmp_code'}}) {
		$self->_flush_tmp('>');
	}

	# Process data callback.
	$self->_process_callback(\@raw_data, 'raw_callback');

	# To flush code.
	$self->{'flush_code'} .= join $EMPTY_STR, @raw_data;

	return;
}

# Reset flush code.
sub _reset_flush {
	my $self = shift;
	$self->{'flush_code'} = $EMPTY_STR;
	return;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

 Tags2::Output::Raw - Raw printing 'Tags2' structure to tags code.

=head1 SYNOPSIS

 use Tags2::Output::Raw;
 my $tags2 = Tags2::Output::Raw->new(%params);
 $tags2->put(['b', 'tag']);
 my @open_tags = $tags2->open_tags;
 $tags2->finalize;
 $tags2->flush;
 $tags2->reset;

=head1 METHODS

=over 8

=item C<new(%params)>

 Constructor.

=over 8

=item * C<attr_callback>

 Subroutine for output processing of attribute key and value.
 Input argument is reference to array.
 Default value is &Tags2::Utils::encode_attr_entities.
 Example is similar as 'data_callback'.

=item * C<attr_delimeter>

 String, that defines attribute delimeter.
 Default is '"'.
 Possible is '"' or "'".

 Example:
 Prints <tag attr='val' /> instead default <tag attr="val" />

 my $tags2 = Tags2::Output::Raw->new(
         'attr_delimeter' => "'",
 );
 $tags2->put(['b', 'tag'], ['a', 'attr', 'val'], ['e', 'tag']);
 $tags2->flush;

=item * C<auto_flush>

 Auto flush flag.
 Default is 0.

=item * C<cdata_callback>

 Subroutine for output processing of cdata.
 Input argument is reference to array.
 Default value is undef.
 Example is similar as 'data_callback'.

=item * C<data_callback>

 Subroutine for output processing of data.
 Input argument is reference to array.
 Default value is &Tags2::Utils::encode_char_entities.

 Example:
 'data_callback' => sub {
         my $data_ar = shift;
	 foreach my $data (@{$data_ar}) {

	         # Some process.
	         $data =~ s/^\s*//ms;
	 }
         return;
 }

=item * C<no-simple>

 Reference to array of tags, that can't by simple.
 Default is [].

 Example:
 That's normal in html pages, web browsers has problem with <script /> tag.
 Prints <script></script> instead <script />.

 my $tags2 = Tags2::Output::Raw->new(
         'no_simple' => ['script'],
 );
 $tags2->put(['b', 'script'], ['e', 'script']);
 $tags2->flush;

=item * C<output_callback>

 Output callback.
 Input argument is reference to scalar of output string.
 Default value is undef.
 Example is similar as 'data_callback'.

=item * C<output_handler>

 Handler for print output strings.
 Must be a GLOB.
 Default is undef.

=item * C<preserved>

 TODO
 Default is reference to blank array.

=item * C<raw_callback>

 Subroutine for output processing of raw data.
 Input argument is reference to array.
 Default value is undef.
 Example is similar as 'data_callback'.

=item * C<skip_bad_tags>

 TODO
 Default is 0.

=item * C<xml>

 Flag, that means xml output.
 Default is 0 (sgml).

=back

=item C<finalize()>

 Finalize Tags output.
 Automaticly puts end of all opened tags.

=item C<flush($reset_flag)>

 Flush tags in object.
 If defined 'output_handler' flush to its.
 Or return code.
 If enabled $reset_flag, then resets internal variables via reset method.

=item C<open_tags()>

 Return array of opened tags.

=item C<put(@data)>

 Put tags code in tags2 format.

=item C<reset()>

 Resets internal variables.

=back

=head1 ERRORS

 Output handler is bad file handler.
 In XML mode must be a attribute value.
 In XML must be lowercase tag name.
 TODO

=head1 EXAMPLE1

 # Pragmas.
 use strict;
 use warnings;

 # Modules.
 use Tags2::Output::Raw;

 # Object.
 my $tags2 = Tags2::Output::Raw->new;

 # Put data.
 $tags2->put(
         ['b', 'text'],
	 ['d', 'data'],
	 ['e', 'text'],
 );

 # Print.
 print $tags2->flush."\n";

 # Output:
 # <text>data</text>

=head1 EXAMPLE2

 # Pragmas.
 use strict;
 use warnings;

 # Modules.
 use Encode;
 use Tags2::Output::Raw;

 # Object.
 my $tags2 = Tags2::Output::Raw->new(
         'data_callback' => sub {
	         my $data_ar = shift;
		 foreach my $data (@{$data_ar}) {
		         $data = encode_utf8($data);
		 }
                 return;
	 },
 );

 # Data in characters.
 my $data = decode_utf8('řčěšřšč');

 # Put data.
 $tags2->put(
         ['b', 'text'],
	 ['d', $data],
	 ['e', 'text'],
 );

 # Print.
 print $tags2->flush."\n";

 # Output:
 # <text>řčěšřšč</text>

=head1 DEPENDENCIES

L<Error::Simple::Multiple(3pm)>,
L<List::MoreUtils(3pm)>,
L<Readonly(3pm)>,
L<Tags2::Utils::Preserve(3pm)>.

=head1 SEE ALSO

L<Tags2(3pm)>,
L<Tags2::Output::Core(3pm)>,
L<Tags2::Output::ESIS(3pm)>,
L<Tags2::Output::Indent(3pm)>,
L<Tags2::Output::Indent2(3pm)>,
L<Tags2::Output::LibXML(3pm)>,
L<Tags2::Output::PYX(3pm)>,
L<Tags2::Output::SESIS(3pm)>,
L<Tags2::Utils(3pm)>.

=head1 AUTHOR

Michal Špaček L<tupinek@gmail.com>

=head1 LICENSE AND COPYRIGHT

BSD license.

=head1 VERSION

0.06

=cut