package ABSX::Action::Confesses;

use strict;
use warnings;

use Role::Tiny::With;
with 'ABSX::Role::Action';

sub confesses {
    my ($actor) = shift;
    print $actor->json->encode($actor);
}


1;
