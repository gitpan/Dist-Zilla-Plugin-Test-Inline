use strict;
package Dist::Zilla::Plugin::Test::Inline;
# ABSTRACT: Create test files for inline tests in POD sections
our $VERSION = '0.011001'; # VERSION


use Moose;
with 'Dist::Zilla::Role::FileGatherer';

use File::Basename qw( basename );
use File::Spec;
use File::Temp qw( tempdir );
use File::Find::Rule;
use Test::Inline;

sub gather_files {
    my $self = shift;
    my $arg = shift;

	$self->log("extracting inline tests from POD sections");

	# give Test::Inline our own input and output handlers
    my $inline = Test::Inline->new(
        verbose => 0,
        ExtractHandler => 'Dist::Zilla::Plugin::Test::Inline::Extract',
        OutputHandler => Dist::Zilla::Plugin::Test::Inline::Output->new($self),
    );

    $inline->add_all;
    $inline->save;
}

#
# Used to connect Test::Inline to Dist::Zilla
# (write generated test code into in-memory files)
#
{
    package Dist::Zilla::Plugin::Test::Inline::Output;
    
    sub new {
        my $class = shift;
        my $dzil = shift;

        return bless { dzil => $dzil }, $class;
    }

    sub write {
        my $self = shift;
        my $name = shift;
        my $content = shift;

        $self->{dzil}->add_file(
            Dist::Zilla::File::InMemory->new(
                name => "t/inline-tests/$name",
                content => $content,
            )
        );

        return 1;
    }
}
#
# Taken from https://github.com/moose/Moose/blob/master/inc/MyInline.pm
#
{
	package Dist::Zilla::Plugin::Test::Inline::Extract;
	
	use parent 'Test::Inline::Extract';
	
	# Extract code specifically marked for testing
	our $search = qr/
		(?:^|\n)                           # After the beginning of the string, or a newline
		(                                  # ... start capturing
		                                   # EITHER
			package\s+                            # A package
			[^\W\d]\w*(?:(?:\'|::)[^\W\d]\w*)*    # ... with a name
			\s*;                                  # And a statement terminator
		|                                  # OR
			class\s+                            # A class
			[^\W\d]\w*(?:(?:\'|::)[^\W\d]\w*)*    # ... with a name
			($|\s+|\s*{)                          # And some spaces or an opening bracket
		|                                  # OR
			role\s+                            # A role
			[^\W\d]\w*(?:(?:\'|::)[^\W\d]\w*)*    # ... with a name
			($|\s+|\s*{)                          # And some spaces or an opening bracket
		|                                  # OR
			=for[ \t]+example[ \t]+begin\n        # ... when we find a =for example begin
			.*?                                   # ... and keep capturing
			\n=for[ \t]+example[ \t]+end\s*?      # ... until the =for example end
			(?:\n|$)                              # ... at the end of file or a newline
		|                                  # OR
			=begin[ \t]+(?:test|testing)\b        # ... when we find a =begin test or testing
			.*?                                   # ... and keep capturing
			\n=end[ \t]+(?:test|testing)\s*?      # ... until an =end tag
			(?:\n|$)                              # ... at the end of file or a newline
		)                                  # ... and stop capturing
		/isx;
	
	sub _elements {
	    my $self     = shift;
	    my @elements = ();
	    while ( $self->{source} =~ m/$search/go ) {
	    	my $element = $1;
	    	# rename "role" or "class" to "package" so Test::Inline understands
	    	$element =~ s/^(role|class)(\s+)/package$2/;
	    	$element =~ s/\n\s*$//;
	        push @elements, $element;
	    }
	    
	    (List::Util::first { /^=/ } @elements) ? \@elements : '';
	}
	
}


1;

__END__

=pod

=head1 NAME

Dist::Zilla::Plugin::Test::Inline - Create test files for inline tests in POD sections

=head1 VERSION

version 0.011001

=head1 SYNOPSIS

In your C<dist.ini>:

	[Test::Inline]

In your module:

	# My/AddressRange.pm

	=begin testing

	use Test::Exception;
	dies_ok {
		My::AddressRange->list_from_range('10.2.3.A', '10.2.3.5')
	} "list_from_range() complains about invalid address";

	=end testing
	
	=cut
	
	sub list_from_range {
		# ...
	}

This will result in a file C<t/inline-tests/my_addressrange.t> in your distribution.

=head1 DESCRIPTION

This plugin integrates L<Test::Inline> into C<Dist::Zilla>.

It scans all modules for inline tests in POD sections that are embedded between
the keywords 

	=begin testing
	...
	=end testing

and exports them into C<t/inline-tests/*.t> files when C<Dist::Zilla> builds
your module. Multiple of these test sections may be specified within one file.

Please note that this plugin (in contrast to pure L<Test::Inline>) can also
handle L<Moops>-like class and role definitions.

=head1 EXTENDS

=over 4

=item * L<Moose::Object>

=back

=head1 METHODS

=head2 gather_files

Required by role L<Dist::Zilla::Role::FileGatherer>.

Searches for inline test code in POD sections using L<Test::Inline>, creates
in-memory test files and passes them to L<Dist::Zilla>.

=head1 ACKNOWLEDGEMENTS

The code of this Dist::Zilla file gatherer plugin is mainly taken from
L<https://github.com/moose/moose/blob/master/inc/ExtractInlineTests.pm>.

=over 4

=item *

Dave Rolsky <autarch@urth.org>, who basically wrote all this but left the honor of making a plugin of it to me ;-)

=back

=head1 AUTHOR

Jens Berthold <jens.berthold@jebecs.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Jens Berthold.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
