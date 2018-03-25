package ABSX::Action::Commits;

use strict;
use warnings;

use Role::Tiny::With;
with 'ABSX::Role::Action';

sub commits {
    my ($actor) = shift;
    $actor->model->write($actor);
}


 1;
