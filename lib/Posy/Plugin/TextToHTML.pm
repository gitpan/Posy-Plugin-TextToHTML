package Posy::Plugin::TextToHTML;
use strict;

=head1 NAME

Posy::Plugin::TextToHTML - Posy plugin to convert plain text files to HTML.

=head1 VERSION

This describes version B<0.63> of Posy::Plugin::TextToHTML.

=cut

our $VERSION = '0.63';

=head1 SYNOPSIS

    @plugins = qw(Posy::Core
	...
	Posy::Plugin::TextToHTML
	...);

=head1 DESCRIPTION

This uses the HTML::TextToHTML module (as used by the txt2html script) to
convert the body of an entry from text into HTML.  This checks the
extension of the entry file, and if it is 'txt', then it will convert
the entry.

This basically replaces the 'parse_entry' method, and calls the parent
method for anything other than text.

=head2 Configuration

This expects configuration settings in the $self->{config} hash,
which, in the default Posy setup, can be defined in the main "config"
file in the data directory.

=over

=item B<txt2html_options>

Set the options for the text-to-HTML processing.  See L<HTML::TextToHTML>
for details.  Certain options are meaningless in this context and will
be ignored, since this is not being processed as a full file, but as
just body content. Therefore options such as 'append_file', 'prepend_file'
and 'append_head' will not work, as well as options which refer to doing
things to the headers.  But that's okay, since you can do things like
that with flavours and other plugins.

Give the options as one long space-separated string, with each option
name followed by its value.  For example:

txt2html_options: xhtml 1 escape_HTML_chars 0 make_anchors 0

=item B<txt2html_simple>

Don't do HTML::TextToHTML processing, just fall back on the default
simple processing. (default: false)

If true, this will just call the parent parse_entry; thus some conversion
will happen, but the Posy::Core conversion just sticks PRE tags around
everything, very simple.

Use this to disable needless lengthy processing if, for example,
you are only displaying a "short body" (see L<Posy::Plugin::ShortBody>)
for 'chrono' or 'category' path-types, where many entry files are
being processed.  One could thus set this to true (1) in the
chrono.config file, for example.  (See also L</txt2html_raw_flavour>)

=item B<txt2html_raw_flavour>

txt2html_raw_flavour: txt

If txt2html_simple is false, and the current flavour matches this string,
then do no processing at all; set the entry body to be the same as the raw
entry.  This is useful if, for example, one has a 'txt' flavour which just
wants plain text to display.

=back

=cut

=head1 OBJECT METHODS

Documentation for developers and those wishing to write plugins.

=head2 init

Do some initialization; make sure that default config values are set.

=cut
sub init {
    my $self = shift;
    $self->SUPER::init();

    # set defaults
    $self->{config}->{txt2html_simple} = 0
	if (!defined $self->{config}->{txt2html_simple});
    $self->{config}->{txt2html_options} = 
    'xhtml 1 make_anchors 0'
	if (!defined $self->{config}->{txt2html_options});
} # init

=head1 Entry Action Methods

Methods implementing per-entry actions.

=head2 parse_entry

$self->parse_entry($flow_state, $current_entry, $entry_state)

Parses $current_entry->{raw} into $current_entry->{title}
and $current_entry->{body}

=cut
sub parse_entry {
    my $self = shift;
    my $flow_state = shift;
    my $current_entry = shift;
    my $entry_state = shift;

    my $id = $current_entry->{id};
    my $file_type = $self->{file_extensions}->{$self->{files}->{$id}->{ext}};
    if ($self->{config}->{txt2html_simple})
    {
	$self->SUPER::parse_entry($flow_state, $current_entry, $entry_state);
    }
    elsif ($file_type eq 'text'
	and $self->{config}->{txt2html_raw_flavour}
	and ($self->{path}->{flavour} =~
	     m#$self->{config}->{txt2html_raw_flavour}#))
    {
	$current_entry->{body} = $current_entry->{raw};
    }
    elsif ($file_type eq 'text')
    {
	require HTML::TextToHTML;

	my %options = ();
	if (defined $self->{config}->{txt2html_options})
	{
	    if (!ref $self->{config}->{txt2html_options}) # a string
	    {
		my @options = split(/\s+/, $self->{config}->{txt2html_options});
		%options = (@options);
		# convert '' options to be empty strings
		while (my ($key, $val) = each %options)
		{
		    if ($val eq "''")
		    {
			$options{$key} = '';
		    }
		}
		$self->{config}->{txt2html_options} = \%options;
	    }
	    else # assume we've converted it already
	    {
		%options = %{$self->{config}->{txt2html_options}};
	    }
	}
	$self->debug(2, "$id is txt");
	$current_entry->{raw} =~ m/^(.*)$/mi;
	$current_entry->{title} = $1;
	# make only one HTML::TextToHTML object
	if (!defined $self->{TextToHTML}->{obj})
	{
	    $self->{TextToHTML}->{obj} = HTML::TextToHTML->new(%options);
	}
	else # set the arguments
	{
	    $self->{TextToHTML}->{obj}->args(%options);
	}
	$current_entry->{body} =
	    $self->{TextToHTML}->{obj}->process_chunk($current_entry->{raw});
    }
    else # use parent
    {
	$self->SUPER::parse_entry($flow_state, $current_entry, $entry_state);
    }
    1;
} # parse_entry

=head1 INSTALLATION

Installation needs will vary depending on the particular setup a person
has.

=head2 Administrator, Automatic

If you are the administrator of the system, then the dead simple method of
installing the modules is to use the CPAN or CPANPLUS system.

    cpanp -i Posy::Plugin::TextToHTML

This will install this plugin in the usual places where modules get
installed when one is using CPAN(PLUS).

=head2 Administrator, By Hand

If you are the administrator of the system, but don't wish to use the
CPAN(PLUS) method, then this is for you.  Take the *.tar.gz file
and untar it in a suitable directory.

To install this module, run the following commands:

    perl Build.PL
    ./Build
    ./Build test
    ./Build install

Or, if you're on a platform (like DOS or Windows) that doesn't like the
"./" notation, you can do this:

   perl Build.PL
   perl Build
   perl Build test
   perl Build install

=head2 User With Shell Access

If you are a user on a system, and don't have root/administrator access,
you need to install Posy somewhere other than the default place (since you
don't have access to it).  However, if you have shell access to the system,
then you can install it in your home directory.

Say your home directory is "/home/fred", and you want to install the
modules into a subdirectory called "perl".

Download the *.tar.gz file and untar it in a suitable directory.

    perl Build.PL --install_base /home/fred/perl
    ./Build
    ./Build test
    ./Build install

This will install the files underneath /home/fred/perl.

You will then need to make sure that you alter the PERL5LIB variable to
find the modules, and the PATH variable to find the scripts (posy_one,
posy_static).

Therefore you will need to change:
your path, to include /home/fred/perl/script (where the script will be)

	PATH=/home/fred/perl/script:${PATH}

the PERL5LIB variable to add /home/fred/perl/lib

	PERL5LIB=/home/fred/perl/lib:${PERL5LIB}

=head1 REQUIRES

    Posy
    Posy::Core
    HTML::TextToHTML

    Test::More

=head1 SEE ALSO

perl(1).
Posy
HMTL::TextToHTML

=head1 BUGS

Please report any bugs or feature requests to the author.

=head1 AUTHOR

    Kathryn Andersen (RUBYKAT)
    perlkat AT katspace dot com
    http://www.katspace.com

=head1 COPYRIGHT AND LICENCE

Copyright (c) 2004-2005 by Kathryn Andersen

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Posy::Plugin::TextToHTML
__END__
