#------------------------------------------------------------------------------
package Tags2::Output::Indent;
#------------------------------------------------------------------------------

# Pragmas.
use base qw(Tags2::Output::Core);
use strict;
use warnings;

# Modules.
use Error::Simple::Multiple qw(err);
use Indent;
use Indent::Word;
use Indent::Block;
use List::MoreUtils qw(none);
use Readonly;
use Tags2::Utils qw(encode_base_entities);
use Tags2::Utils::Preserve;

# Constants.
Readonly::Scalar my $EMPTY_STR => q{};
Readonly::Scalar my $LAST_INDEX => -1;
Readonly::Scalar my $LINE_SIZE => 79;
Readonly::Scalar my $SPACE => q{ };

# Version.
our $VERSION = 0.06;

#------------------------------------------------------------------------------
sub reset {
#------------------------------------------------------------------------------
# Resets internal variables.

	my $self = shift;

	# Comment flag.
	$self->{'comment_flag'} = 0;

	# Indent object.
	$self->{'indent'} = Indent->new(
		'next_indent' => $self->{'next_indent'},
	);

	# Indent::Word object.
	$self->{'indent_word'} = Indent::Word->new(
		'line_size' => $self->{'line_size'},
		'next_indent' => $EMPTY_STR,
	);

	# Indent::Block object.
	$self->{'indent_block'} = Indent::Block->new(
		'line_size' => $self->{'line_size'},
		'next_indent' => $self->{'next_indent'},
		'strict' => 0,
	);

	# Flush code.
	$self->_reset_flush;

	# Tmp code.
	$self->{'tmp_code'} = [];
	$self->{'tmp_comment_code'} = [];

	# Printed tags.
	$self->{'printed_tags'} = [];

	# Non indent flag.
	$self->{'non_indent'} = 0;

	# Flag, that means raw tag.
	$self->{'raw_tag'} = 0;

	# Preserved object.
	$self->{'preserve_obj'} = Tags2::Utils::Preserve->new(
		'preserved' => $self->{'preserved'},
	);

	# Process flag.
	$self->{'process'} = 0;

	return;
}

#------------------------------------------------------------------------------
# Private methods.
#------------------------------------------------------------------------------

#------------------------------------------------------------------------------
sub _check_params {
#------------------------------------------------------------------------------
# Check parameters to rigth values.

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

#------------------------------------------------------------------------------
sub _default_parameters {
#------------------------------------------------------------------------------
# Default parameters.

	my $self = shift;

	# Default parameters from SUPER.
	$self->SUPER::_default_parameters();

	# Attribute delimeter.
	$self->{'attr_delimeter'} = '"';

	# Indent CDATA section.
	$self->{'cdata_indent'} = 0;

	# CDATA callback.
	$self->{'cdata_callback'} = undef;

	# Data callback.
	$self->{'data_callback'} = \&encode_base_entities;

	# Callback to instruction.
	$self->{'instruction'} = $EMPTY_STR;

	# Indent line size.
	$self->{'line_size'} = $LINE_SIZE;

	# Next indent string.
	$self->{'next_indent'} = $SPACE x 2;

	# No simple tags.
	$self->{'no_simple'} = [];

	# Preserved tags.
	$self->{'preserved'} = [];

	# Raw data callback.
	$self->{'raw_callback'} = undef;

	# XML output.
	$self->{'xml'} = 0;

	return;
}

#------------------------------------------------------------------------------
sub _flush_code {
#------------------------------------------------------------------------------
# Helper for flush data.

	my ($self, $code) = @_;
	if (! $self->{'process'}) {
		$self->{'process'} = 1;
	}
	$self->{'flush_code'} .= $code;
	return;
}

#------------------------------------------------------------------------------
sub _newline {
#------------------------------------------------------------------------------
# Print newline if need.

	my $self = shift;

	# Null raw tag (normal tag processing).
	if ($self->{'raw_tag'}) {
		$self->{'raw_tag'} = 0;

	# Adding newline if flush_code.
	} else {
		my (undef, $pre_pre) = $self->{'preserve_obj'}->get;
		if ($self->{'process'} && $pre_pre == 0) {
			$self->_flush_code($self->{'output_sep'});
		}
	}

	return;
}

#------------------------------------------------------------------------------
sub _print_tag {
#------------------------------------------------------------------------------
# Print indented tag from @{$self->{'tmp_code'}}.

	my ($self, $string) = @_;
	if ($string) {
		if ($string =~ /^\/>$/ms) {
			push @{$self->{'tmp_code'}}, $SPACE;
		}
		push @{$self->{'tmp_code'}}, $string;
	}

	# Flush comment code before tag.
	# TODO Optimalization.
	if ($self->{'comment_flag'} == 0
		&& scalar @{$self->{'tmp_comment_code'}}) {

		# Comment from tmp place.
		foreach my $tmp_comment (@{$self->{'tmp_comment_code'}}) {
			$self->_newline;
			my $indent_tmp_comment = $self->{'indent_block'}
				->indent($tmp_comment, $self->{'indent'}->get);
			$self->_flush_code($indent_tmp_comment);
		}

		my $pre = $self->{'preserve_obj'}->get;
		my $act_indent;
		if (! $self->{'non_indent'} && ! $pre) {
			$act_indent = $self->{'indent'}->get;
		}
		$self->_newline;

		# Get indent string and put to flush.
		my $tmp = $self->{'indent_block'}->indent(
			$self->{'tmp_code'}, $act_indent, $pre ? 1 : 0,
		);
		$self->_flush_code($tmp);

		$self->{'tmp_code'} = [];
		if (! $self->{'non_indent'} && ! $pre) {
			$self->{'indent'}->add;
		}
		$self->{'preserve_obj'}->begin($self->{'printed_tags'}->[0]);
	} else {
		my $pre = $self->{'preserve_obj'}->get;
		my $act_indent;
		if (! $self->{'non_indent'} && ! $pre) {
			$act_indent = $self->{'indent'}->get;
		}
		$self->_newline;

		# Get indent string and put to flush.
		my $tmp = $self->{'indent_block'}->indent(
			$self->{'tmp_code'}, $act_indent, $pre ? 1 : 0
		);
		$self->_flush_code($tmp);

		$self->{'tmp_code'} = [];
		if (! $self->{'non_indent'} && ! $pre) {
			$self->{'indent'}->add;
		}
		$self->{'preserve_obj'}->begin($self->{'printed_tags'}->[0]);

		# Comment from tmp place.
		foreach my $tmp_comment (@{$self->{'tmp_comment_code'}}) {
			$self->_newline;
			my $indent_tmp_comment = $self->{'indent_block'}
				->indent($tmp_comment, $self->{'indent'}->get);
			$self->_flush_code($indent_tmp_comment);
		}
	}
	$self->{'tmp_comment_code'} = [];
	return;
}

#------------------------------------------------------------------------------
sub _print_end_tag {
#------------------------------------------------------------------------------
# Print indented end of tag.

	my ($self, $string) = @_;
	my $act_indent;
	my ($pre, $pre_pre) = $self->{'preserve_obj'}->get;
	if (! $self->{'non_indent'} && ! $pre) {
		$self->{'indent'}->remove;
		if (! $pre_pre) {
			$act_indent = $self->{'indent'}->get;
		}
	}
	$self->_newline;
	my $indent_end = $self->{'indent_block'}->indent(
		['</'.$string, '>'], $act_indent, $pre ? 1 : 0,
	);
	$self->_flush_code($indent_end);
	return;
}

#------------------------------------------------------------------------------
sub _put_attribute {
#------------------------------------------------------------------------------
# Attributes.

	my ($self, $attr, $value) = @_;

	# Check to 'tmp_code'.
	if (! @{$self->{'tmp_code'}}) {
		err 'Bad tag type \'a\'.';
	}

	# Check to pairs in XML mode.
	if ($self->{'xml'} && ! defined $value) {
		err 'In XML mode must be a attribute value.';
	}

	# Process attribute.
	push @{$self->{'tmp_code'}}, $SPACE, $attr;
	if (defined $value) {
		push @{$self->{'tmp_code'}}, q{=}, $self->{'attr_delimeter'}.
			$value.$self->{'attr_delimeter'};
	}

	# Reset comment flag.
	$self->{'comment_flag'} = 0;

	return;
}

#------------------------------------------------------------------------------
sub _put_begin_of_tag {
#------------------------------------------------------------------------------
# Begin of tag.

	my ($self, $tag) = @_;

	# Flush tmp code.
	if (scalar @{$self->{'tmp_code'}}) {
		$self->_print_tag('>');
	}

	# XML check for uppercase names.
	if ($self->{'xml'} && $tag ne lc($tag)) {
		err 'In XML must be lowercase tag name.';
	}

	# Push begin of tag to tmp code.
	push @{$self->{'tmp_code'}}, "<$tag";

	# Added tag to printed tags.
	unshift @{$self->{'printed_tags'}}, $tag;

	return;
}

#------------------------------------------------------------------------------
sub _put_cdata {
#------------------------------------------------------------------------------
# CData.

	my ($self, @cdata) = @_;

	# Flush tmp code.
	if (scalar @{$self->{'tmp_code'}}) {
		$self->_print_tag('>');
	}

	# Added begin of cdata section.
	unshift @cdata, '<![CDATA[';

	# Check to bad cdata.
	if ((join $EMPTY_STR, @cdata) =~ /]]>$/ms) {
		err 'Bad CDATA section.';
	}

	# Added end of cdata section.
	push @cdata, ']]>';

	# Process data callback.
	$self->_process_callback(\@cdata, 'cdata_callback');

	$self->_newline;
	$self->{'preserve_obj'}->save_previous;

	# TODO Proc tohle nejde volat primo?
	my $tmp = $self->{'indent_block'}->indent(
		\@cdata, $self->{'indent'}->get,
		$self->{'cdata_indent'} == 1 ? 0 : 1,
	);

	# To flush code.
	$self->_flush_code($tmp);

	return;
}

#------------------------------------------------------------------------------
sub _put_comment {
#------------------------------------------------------------------------------
# Comment.

	my ($self, @comments) = @_;

	# Comment string.
	unshift @comments, '<!--';
	if (substr($comments[$LAST_INDEX], $LAST_INDEX) eq '-') {
		push @comments, ' -->';
	} else {
		push @comments, '-->';
	}

	# Process comment.
	if (scalar @{$self->{'tmp_code'}}) {
		push @{$self->{'tmp_comment_code'}}, \@comments;

		# Flag, that means comment is last.
		$self->{'comment_flag'} = 1;
	} else {
		$self->_newline;
		my $indent_comment = $self->{'indent_block'}->indent(
			\@comments, $self->{'indent'}->get,
		);
		$self->_flush_code($indent_comment);
	}
	return;
}

#------------------------------------------------------------------------------
sub _put_data {
#------------------------------------------------------------------------------
# Data.

	my ($self, @data) = @_;

	# Flush tmp code.
	if (scalar @{$self->{'tmp_code'}}) {
		$self->_print_tag('>');
	}

	# Process data callback.
	$self->_process_callback(\@data, 'data_callback');

	$self->_newline;
	$self->{'preserve_obj'}->save_previous;
	my $pre = $self->{'preserve_obj'}->get;
	my $indent_data = $self->{'indent_word'}->indent(
		(join $EMPTY_STR, @data),
		$pre ? $EMPTY_STR : $self->{'indent'}->get,
		$pre ? 1 : 0
	);
	$self->_flush_code($indent_data);
	return;
}

#------------------------------------------------------------------------------
sub _put_end_of_tag {
#------------------------------------------------------------------------------
# End of tag.

	my ($self, $tag) = @_;
	my $printed = shift @{$self->{'printed_tags'}};
	if ($self->{'xml'} && $printed ne $tag) {
		err "Ending bad tag: '$tag' in block of tag '$printed'.";
	}

	# Tag can be simple.
	if ($self->{'xml'} && (! scalar @{$self->{'no_simple'}}
		|| none { $_ eq $tag } @{$self->{'no_simple'}})) {

		my $pre = $self->{'preserve_obj'}->end($tag);
		if (scalar @{$self->{'tmp_code'}}) {
			if (scalar @{$self->{'tmp_comment_code'}}
				&& $self->{'comment_flag'} == 1) {

				$self->_print_tag('>');
# XXX				$self->{'preserve_obj'}->end($tag);
				$self->_print_end_tag($tag);
			} else {
				$self->_print_tag('/>');
				if (! $self->{'non_indent'} && ! $pre) {
					$self->{'indent'}->remove;
				}
			}
		} else {
			$self->_print_end_tag($tag);
		}

	# Tag cannot be simple.
	} else {
		if (scalar @{$self->{'tmp_code'}}) {
			unshift @{$self->{'printed_tags'}}, $tag;
			$self->_print_tag('>');
			shift @{$self->{'printed_tags'}};
# XXX				$self->_newline;
		}
		$self->{'preserve_obj'}->end($tag);
		$self->_print_end_tag($tag);
	}
	return;
}

#------------------------------------------------------------------------------
sub _put_instruction {
#------------------------------------------------------------------------------
# Instruction.

	my ($self, $target, $code) = @_;

	# Flush tmp code.
	if (scalar @{$self->{'tmp_code'}}) {
		$self->_print_tag('>');
	}

	# Process instruction code.
	if (ref $self->{'instruction'} eq 'CODE') {
		$self->{'instruction'}->($self, $target, $code);

	# Print instruction.
	} else {
		$self->_newline;
		$self->{'preserve_obj'}->save_previous;
		my $indent_instr = $self->{'indent_block'}->indent(
			['<?'.$target, $SPACE, $code, '?>',
			$self->{'indent'}->get],
		);
		$self->_flush_code($indent_instr);
	}

	return;
}

#------------------------------------------------------------------------------
sub _put_raw {
#------------------------------------------------------------------------------
# Raw data.

	my ($self, @raw_data) = @_;

	# Flush tmp code.
	if (scalar @{$self->{'tmp_code'}}) {
		$self->_print_tag('>');
	}

	# Process data callback.
	$self->_process_callback(\@raw_data, 'raw_callback');

	# Added raw data to flush code.
	$self->_flush_code(join $EMPTY_STR, @raw_data);

	# Set raw flag.
	$self->{'raw_tag'} = 1;

	return;
}

#------------------------------------------------------------------------------
sub _reset_flush {
#------------------------------------------------------------------------------
# Reset flush code.

	my $self = shift;
	$self->{'flush_code'} = $EMPTY_STR;
	return;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

 Tags2::Output::Indent - Indent class for Tags2.

=head1 SYNOPSIS

 use Tags2::Output::Indent(%params);
 my $tags2 = Tags2::Output::Indent->new;
 $tags2->put(['b', 'tag']);
 my @open_tags = $tags2->open_tags;
 $tags2->finalize;
 $tags2->flush;
 $tags2->reset;

=head1 METHODS

=over 8

=item B<new(%params)>

 Constructor

=over 8

=item * B<attr_delimeter>

 String, that defines attribute delimeter.
 Default is '"'.
 Possible is '"' or "'".

 Example:
 Prints <tag attr='val' /> instead default <tag attr="val" />

 my $tags2 = Tags2::Output::Indent->new(
         'attr_delimeter' => "'",
 );
 $tags2->put(
         ['b', 'tag'],
         ['a', 'attr', 'val'],
         ['e', 'tag'],
 );
 $tags2->flush;

=item * B<auto_flush>

 Auto flush flag.
 Default is 0.

=item * B<cdata_indent>

 Flag, that means indent CDATA section.
 Default value is no-indent (0).

=item * B<cdata_callback>

 Subroutine for output processing of cdata.
 Input argument is reference to array.
 Default value is undef.
 Example is similar as 'data_callback'.

=item * B<data_callback>

 Subroutine for output processing of data.
 Input argument is reference to array.
 Default value is &Tags2::Utils::encode_base_entities.

 Example:
 'data_callback' => sub {
         my $data_ar = shift;
	 foreach my $data (@{$data_ar}) {

	         # Some process.
	         $data =~ s/^\s*//ms;
	 }
 }

=item * B<line_size>

 TODO
 Default value is 79.

=item * B<next_indent>

 TODO
 Default value is "  ".

=item * B<no_simple>

 Reference to array of tags, that can't by simple.
 Default is [].

 Example:
 That's normal in html pages, web browsers has problem with <script /> tag.
 Prints <script></script> instead <script />.

 my $tags2 = Tags2::Output::Raw->new(
         'no_simple' => ['script']
 );
 $tags2->put(
         ['b', 'script'],
         ['e', 'script'],
 );
 $tags2->flush;

=item * B<output_handler>

 Handler for print output strings.
 Must be a GLOB.
 Default is undef.

=item * B<output_separator>

 TODO
 Default value is newline (\n).

=item * B<preserved>

 TODO
 Default is reference to blank array.

=item * B<raw_callback>

 Subroutine for output processing of raw data.
 Input argument is reference to array.
 Default value is undef.
 Example is similar as 'data_callback'.

=item * B<skip_bad_tags>

 TODO
 Default is 0.

=back

=item B<finalize()>

 Finalize Tags output.
 Automaticly puts end of all opened tags.

=item B<flush($reset_flag)>

 Flush tags in object.
 If defined 'output_handler' flush to its.
 Or return code.
 If enabled $reset_flag, then resets internal variables via reset method.

=item B<open_tags()>

 Return array of opened tags.

=item B<put(@data)>

 Put tags code in tags2 format.

=item B<reset()>

 Resets internal variables.

=back

=head1 ERRORS

 'auto_flush' parameter can't use without 'output_handler' parameter.
 Bad attribute delimeter '%s'.
 Bad CDATA section.
 Bad data.
 Bad parameter '%s'.
 Bad tag type 'a'.
 Bad type of data.
 Ending bad tag: '%s' in block of tag '%s'.
 In XML mode must be a attribute value.

=head1 EXAMPLE

 # Pragmas.
 use strict;
 use warnings;

 # Modules.
 use Tags2::Output::Indent;

 # Object.
 my $tags = Tags2::Output::Indent->new;

 # Put data.
 $tags2->put(
         ['b', 'text'],
	 ['d', 'data'],
	 ['e', 'text'],
 );

 # Print.
 print $tags2->flush."\n";

 # Output:
 # <text>
 #   data
 # </text>

=head1 DEPENDENCIES

L<Error::Simple::Multiple(3pm)>,
L<Indent(3pm)>,
L<Indent::Word(3pm)>,
L<Indent::Block(3pm)>,
L<List::MoreUtils(3pm)>,
L<Readonly(3pm)>,
L<Tags2::Utils::Preserve(3pm)>.

=head1 SEE ALSO

L<Tags2(3pm)>,
L<Tags2::Output::Core(3pm)>,
L<Tags2::Output::ESIS(3pm)>,
L<Tags2::Output::Indent2(3pm)>,
L<Tags2::Output::LibXML(3pm)>,
L<Tags2::Output::PYX(3pm)>,
L<Tags2::Output::Raw(3pm)>,
L<Tags2::Output::SESIS(3pm)>,
L<Tags2::Utils(3pm)>.

=head1 AUTHOR

Michal Špaček L<tupinek@gmail.com>

=head1 LICENSE AND COPYRIGHT

BSD license.

=head1 VERSION

0.06

=cut
