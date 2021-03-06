package Alien::Build::Plugin::Prefer::GoodVersion;

use strict;
use warnings;
use Alien::Build::Plugin;
use Carp ();

# ABSTRACT: Plugin to filter known good versions
# VERSION

=head1 SYNOPSIS

 use alienfile;
 plugin 'Prefer::GoodVersion' => '1.2.3';

=head1 DESCRIPTION

This plugin allows you to specify one ore more good versions of a library.  This plugin does
the opposite of the C<Prefer::BadVersion> plugin.  You need need a Prefer plugin that filters
and sorts files first.  You may specify the filter in one of three ways:

=over

=item as a string

Filter any files that match the given version.

 use alienfile;
 plugin 'Prefer::GoodVersion' => '1.2.3';

=item as a array

Filter all files that match any of the given versions.

 use alienfile;
 plugin 'Prefer::GoodVersion' => [ '1.2.3', '1.2.4' ];

=item as a code reference

Filter any files return a true value.

 use alienfile;
 plugin 'Prefer::GoodVersion' => sub {
   my($file) = @_;
   $file->{version} eq '1.2.3'; # same as the string version above
 };

=back

This plugin can also be used to filter known good versions of a library on just one platform.
For example, if you know that version 1.2.3 if good on windows, but the default logic is fine
on other platforms:

 use alienfile;
 plugin 'Prefer::GoodVersion' => '1.2.3' if $^O eq 'MSWin32';

=head1 PROPERTIES

=head2 filter

Filter entries that match the filter.

=head1 CAVEATS

If you are using the string or array mode, then you need an existing Prefer plugin that sets the
version number for each file candidate, such as L<Alien::Build::Plugin::Prefer::SortVersions>.

=head1 SEE ALSO

=over 4

=item L<alienfile>

=item L<Alien::Build>

=item L<Alien::Build::Plugin::Prefer::SortVersions>

=back

=cut

has '+filter' => sub { Carp::croak("The filter property is required for the Prefer::GoodVersion plugin") };

sub init
{
  my($self, $meta) = @_;

  $meta->add_requires('configure', __PACKAGE__, '1.44');
  
  my $filter;
  
  if(ref($self->filter) eq '')
  {
    my $string = $self->filter;
    $filter = sub {
      my($file) = @_;
      $file->{version} eq $string;
    };
  }
  elsif(ref($self->filter) eq 'ARRAY')
  {
    my %filter = map { $_ => 1 } @{ $self->filter };
    $filter = sub {
      my($file) = @_;
      !! $filter{$file->{version}};
    };
  }
  elsif(ref($self->filter) eq 'CODE')
  {
    my $code = $self->filter;
    $filter = sub { !! $code->($_[0]) };
  }
  else
  {
    Carp::croak("unknown filter type for Prefer::GoodVersion");
  }
  
  $meta->around_hook(
    prefer => sub {
      my($orig, $build, @therest) = @_;
      my $res1 = $orig->($build, @therest);
      return $res1 unless $res1->{type} eq 'list';
      
      return {
        type => 'list',
        list => [
          grep { $filter->($_) } @{ $res1->{list} }
        ],
      };
    },
  );
}

1;
