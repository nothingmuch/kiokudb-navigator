package KiokuDB::Navigator;
use Moose;
use MooseX::Types::Path::Class;

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:STEVAN';

use JSORB;
use JSORB::Dispatcher::Path;
use JSORB::Server::Simple;
use JSORB::Server::Traits::WithStaticFiles;

use KiokuDB;
use KiokuDB::Backend::Serialize::JSPON::Collapser;

with 'MooseX::Getopt';

has 'db' => (
    is       => 'ro',
    isa      => 'KiokuDB',   
    required => 1,
);

has 'doc_root' => (
    is       => 'ro',
    isa      => 'Path::Class::Dir',   
    coerce   => 1,
    required => 1,
);

has 'root_id' => (
    is      => 'ro',
    isa     => 'Str',   
);

has 'jsorb_namespace' => (
    is      => 'ro',
    isa     => 'JSORB::Namespace',   
    default => sub {
        return JSORB::Namespace->new(
            name     => 'KiokuDB',
            elements => [
                JSORB::Interface->new(
                    name       => 'Navigator',
                    procedures => [
                        JSORB::Method->new(
                            name        => 'lookup',
                            method_name => '_lookup',
                            spec        => [ 'Str' => 'HashRef' ]
                        )
                    ]
                )
            ]
        );        
    },
);

sub _lookup {
    my $self = shift;
    my $id   = shift || $self->root_id;
    my $obj  = $self->db->lookup($id);
    (defined $obj)
        || confess "No object found for $id";
    my $collapser = KiokuDB::Backend::Serialize::JSPON::Collapser->new;
    return $collapser->collapse_jspon(
        $self->db->live_objects->object_to_entry(
            $obj
        )
    );    
}

sub run {
    my $self = shift;
    
    my $s = $self->db->new_scope;
    
    JSORB::Server::Simple->new_with_traits(
        traits     => [
            'JSORB::Server::Traits::WithDebug',
            'JSORB::Server::Traits::WithStaticFiles',
            'JSORB::Server::Traits::WithInvocant',
        ],
        invocant   => $self,        
        doc_root   => $self->doc_root,
        dispatcher => JSORB::Dispatcher::Path->new_with_traits(
            traits    => [ 'JSORB::Dispatcher::Traits::WithInvocant' ],
            namespace => $self->jsorb_namespace,
        )

    )->run;    
}

no Moose; 1;

__END__

=pod

=head1 NAME

KiokuDB::Navigator - A Moosey solution to this problem

=head1 SYNOPSIS

  use KiokuDB::Navigator;

=head1 DESCRIPTION

=head1 METHODS 

=over 4

=item B<>

=back

=head1 BUGS

All complex software has bugs lurking in it, and this module is no 
exception. If you find a bug please either email me, or add the bug
to cpan-RT.

=head1 AUTHOR

Stevan Little E<lt>stevan.little@iinteractive.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2008 Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
