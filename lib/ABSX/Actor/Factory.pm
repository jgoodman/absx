package ABSX::Actor::Factory;

use strict;
use warnings;

use Throw;
use Class::Method::Modifiers;
use Role::Tiny::With;
with 'ABSX::Role::Actor';

sub core_actions { qw(builds) }
sub builds {
    my ($self, $alias, @args) = @_;

    my $class;
    while(my $param = shift(@args)) {
        $param = uc $param;
        if($param eq 'AS') {
            $class = shift(@args) || throw '-absx: missing class';
        }
    }
    $class ||= $alias;

    my $module = "ABSX::Actor::".ucfirst(lc($class));
    (my $file = "$module.pm") =~ s{::}{/}g;
    require $file;
    my $child = $module->new;
    return sub {
        my $console = shift;
        $console->actors($child);
        $console->add_alias($alias);
    };
}

1;

__END__
=head1 Name

Factory, Version 0.1

=head1 SYNOPSIS

  factory <ACTION> [OPTIONS]

ACTIONS

  helps              Prints this message
  confesses          Dumps this actor's data

=cut
