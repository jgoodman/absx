package ABSX::Action::Commits;

use strict;
use warnings;

use Role::Tiny::With;
with 'ABSX::Role::Action';

sub commits {
    my ($actor) = @_;
    $actor->model->write;
}


 1;
