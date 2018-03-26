package ABSX::Actor::Codex;

use strict;
use warnings;

use Role::Tiny::With;
with 'ABSX::Role::Actor';

sub core_actions { qw(defines) }

sub defines {
    my ($self, $uuid, $term, $class) = @_;
    if(!$term) {
        warn "-absx: $uuid: defines: missing term\n";
        return;
    }
    if(!$class) {
        warn "-absx: $uuid: defines: missing class\n";
        return;
    }
    my %seen = ();
    $self->{'term2classes'}->{$term} = [ sort _uniq(@{$self->{'term2classes'}->{$term} ||= []}, $class) ];
    $self->{'class2terms'}->{$class} = [ sort _uniq(@{$self->{'class2terms'}->{$term}  ||= []}, $term)  ];
    return 1;
}

sub _uniq { my %s; grep { not $s{$_}++ } @_ }

1;
