package Catalyst::Plugin::ConfigLoaderDirs;

# ABSTRACT: Load config from a selection of specified directories

use strict;
use warnings;
use base qw/Catalyst::Plugin::ConfigLoader/;

use Config::Any;
use File::Spec;

# VERSION
# AUTHORITY

=head1 SYNOPSIS

    package MyApp;

    use strict;
    use warnings;

    use Catalyst::Runtime '5.70';

    use Catalyst qw/-Debug ConfigLoaderDirs/;

    our $VERSION = '0.01';

    __PACKAGE__->config( name => 'MyApp' );
    __PACKAGE__->config( 'Plugin::ConfigLoaderDirs' => { directory => [ '/etc', '__HOME__' ] } );

    __PACKAGE__->setup;

    1;

=head1 DESCRIPTION

This is a thin layer over L<Catalyst::Plugin::ConfigLoader> that allows the
specification of a set of directories to search for configuration data.  This
allows, for example, the use of a global configuration directory to be used
rather than the configuration being within the application directory itself.

As this is an initial trial module it has not been pushed to CPAN at this time.

=cut

# ------------------------------------------------------------------------

=head2 find_files

This method determines the potential file paths to be used for config loading.
It returns an array of paths including the extension to pass to
L<Config::Any|Config::Any> for loading.

=cut

sub find_files {
    my $c = shift;
    my ( $path, $extension ) = $c->get_config_path;
    my $suffix     = $c->get_config_local_suffix;
    my @extensions = @{ Config::Any->extensions };

    my @files;
    if ($extension) {
        die "Unable to handle files with the extension '${extension}'"
            unless grep { $_ eq $extension } @extensions;
        ( my $local = $path ) =~ s{\.$extension}{_$suffix.$extension};
        push @files, $path, $local;
    }
    else {
        my @dirset  = $c->get_config_directory_set;
        my $appname = ref $c || $c;
        my $prefix  = Catalyst::Utils::appprefix($appname);

        foreach my $dir (@dirset) {
            foreach my $ext (@extensions) {
                push( @files, File::Spec->catfile( $dir, ( $prefix . '.' . $ext ) ) );
                push( @files, File::Spec->catfile( $dir, ( $prefix . '_' . $suffix . '.' . $ext ) ) ) if ($suffix);
            }
        }
    }

    return @files;
}

# ------------------------------------------------------------------------

=head2 get_config_directory_set

Returns a set of directories to search for config within, based on the
information configured for C<Plugin::ConfigLoaderDirs> under the C<directory>
key.

=cut

sub get_config_directory_set {
    my $c = shift;

    my @dirset;
    my $dirs =
        $c->config->{'Plugin::ConfigLoaderDirs'}->{directory} || $c->config->{'Plugin::ConfigLoader'}->{directory};
    if ($dirs) {
        push @dirset, ( ( ref($dirs) eq 'ARRAY' ) ? @{$dirs} : $dirs );
    }
    else {
        push @dirset, $c->path_to('');
    }

    # so that we can use macros in the directory list we explicitly expand
    # them here...
    @dirset = map { $c->config_substitutions($_) } @dirset;

    return @dirset;
}

# ------------------------------------------------------------------------

1;
