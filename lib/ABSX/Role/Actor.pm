package ABSX::Role::Actor;

use strict;
use warnings;
use Role::Tiny;
use Throw;

sub new {
    my ($class, $ref) = @_;
    my $self = bless(($ref || { }), (ref($class) || $class));
    $self->{'actions'} = [ $self->core_actions ];
    return $self;
}

sub core_actions { shift; qw(confesses commits), @_ }
sub actions      { my $s = shift; $s->{'actions'} ||= [ $s->core_actions ] }
sub attribute    { shift->{'attributes'} ||= { } }
sub class        { (my $c = ref($_[0]) || $_[0]) =~ s/^ABSX::Actor:://g; lc($c) }

sub exercise {
    my ($self, $action, @args) = @_;
    my $module = 'ABSX::Action::'.ucfirst($action);
    my $file   = 'ABSX/Action/'.ucfirst($action).".pm";
    my $sub    = scalar(grep { -e "$_/$file" } @INC) ? do { require $file; $module->can($action) } : $self->can($action);
    if(!$sub) {
        throw '-absx: '.$self->alias.": $action: action not found";
    }
    if(!$self->has_action($action) || $action eq 'exercise') {
        throw '-absx: '.$self->alias.": $action: invalid action for actor";
    }
    $sub->($self, @args);
}

sub has_action {
    my ($self, $action) = @_;
    my $r = grep { $action eq $_ } @{$self->actions};
}

sub uuid {
    my $self = shift;
    $self->{'uuid'} = shift if scalar @_;
    return $self->{'uuid'};
}

sub alias {
    my $self = shift;
    return $self->{'alias'} || join(':',$self->uuid, $self->class);
}

sub console {
    my $self = shift;
    $self->{'console'} or throw '-absx: '.$self->alias.': console undefined';
}

sub TO_JSON {
    my $self = shift;
    my $pretty = { _CLASS => ref($self), %$self };
    delete $pretty->{'json'};
    if($pretty->{'model'}) {
        $pretty->{'_MODEL'} = ref(delete($pretty->{'model'}));
    }
    return $pretty;
}
sub json { shift->{'json'} ||= JSON->new->allow_nonref([1])->convert_blessed([1])->canonical([1])->pretty([1]) }

sub storage_driver { shift->{'storage_driver'} ||= $ENV{'STORAGE_DRIVER'} || 'file' }

sub model {
    my $self = shift;
    return $self->{'model'} ||= do {
        require ABSX::Model;
        ABSX::Model->new({ storage_driver => $self->storage_driver });
    };
}

1;
