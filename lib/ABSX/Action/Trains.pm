package ABSX::Action::Trains;

use strict;
use warnings;

use Role::Tiny::With;
with 'ABSX::Role::Action';

sub trains {
    my $actor    = shift;
    my $skill  = lc(shift || '');
    $skill     = shift if $skill eq 'in';
    #unless($skill && grep {$skill eq $_} @SKILLS) {
    #    warn "-absx: $actor: trains: invalid skill\n";
    #    return;
    #}
    print $actor->alias." trains in $skill\n";
}



1;
