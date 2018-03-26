package ABSX::Actor::Dicepool;

use strict;
use warnings;

use Games::Dice;
use Class::Method::Modifiers;
use Role::Tiny::With;
with 'ABSX::Role::Actor';

sub core_actions { qw(rolls recounts) }

around TO_JSON => sub {
    my ($o, $s) = (shift, shift);
    my $data = $o->($s);
    delete $data->{'_gd_roll'};
    return $data;
};


sub rolls {
    my $self = shift;
    my @args = @_;
    if(scalar(@args)) {
        $self->{'last'} = [ @args ];
    }
    else {
        @args = @{$self->{'last'} ||= []};
    }
    my $key = join(' ',@args);
    my $results = Games::Dice::roll($key);
    $self->_record([$key => $results]);
    print "$results\n";
    return;
}

sub history { shift->{'history'} ||= [ ] }

sub _record {
    my $self = shift;
    my $pair = shift;
    $self->_maxlen($pair);
    push @{$self->history}, $pair;
}

sub _maxlen {
    my $self = shift;
    if(my $pair = shift) {
        my $maxlen = $self->_maxlen;
        foreach my $i (0, 1) {
            my $l = length $pair->[$i];
            $maxlen = $l if $l > $maxlen;
        }
        $self->{'maxlen'} = $maxlen;
    }
    return $self->{'maxlen'} ||= 0;
}

sub recounts {
    my $self = shift;
    my $format = '%-'.$self->_maxlen.'s';
    print '  +-'.('-'x$self->_maxlen).'---'.('-'x$self->_maxlen).'-+'."\n";
    foreach my $row (@{$self->history}) {
        my $rolled = sprintf($format, $row->[0]);
        my $result = sprintf($format, $row->[1]);
        print '  | '.join(' | ', $rolled, $result)." |\n";
    }
    print '  +-'.('-'x$self->_maxlen).'---'.('-'x$self->_maxlen).'-+'."\n";
    return;
}

sub longest {
    my $self = shift;
    my $history = $self->history;
    my $max = -1;
    my $max_i = 0;
    for (0 .. $#_) {              # for each index
        my $len = length $_[$_];  # only get length once per item
        if ($len > $max) {        # save index and update max if larger
            $max = $len;
            $max_i = $_;
        }
    }
    $_[$max_i]   # return the largest item
}

1;
