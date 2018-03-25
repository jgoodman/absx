package ABSX::Actor::Factory;

use strict;
use warnings;

use Class::Method::Modifiers;
use Role::Tiny::With;
with 'ABSX::Role::Actor';

around core_actions => sub {
    my ($o, $s) = (shift, shift);
    $o->($s, qw(builds), @_);
};

sub builds {
    my ($self, $class, @args) = @_;
    my $module = "ABSX::Actor::".ucfirst(lc($class));
    (my $file = "$module.pm") =~ s{::}{/}g;
    require $file;
    my $child = $module->new;
    return sub {
        my $console = shift;
        $console->actors($child)
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
