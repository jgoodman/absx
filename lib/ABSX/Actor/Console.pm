package ABSX::Actor::Console;

use strict;
use warnings;
use JSON;
use Term::ReadLine;
use Throw;

use ABSX::Actor::Factory;
use ABSX::Actor::Stub;

use Class::Method::Modifiers;
use Role::Tiny::With;
with 'ABSX::Role::Actor';

sub core_actions { qw(exits saves) }

around TO_JSON => sub {
    my ($o, $s) = (shift, shift);
    my $pretty = $o->($s);
    delete $pretty->{'term'};
    if($pretty->{'actors'}) {
        $pretty->{'actors'} = [ map { join(':',$_->uuid,$_->class,$_->alias) } @{delete $pretty->{'actors'}} ];
    }
    return $pretty;
};

# TODO move to codex
my %ALIASES = (
    _INDEX  => 2,
    console => 0,
    factory => 1,
);

my @SKILLS     = qw(acrobatics athletics guile guile);
my @ATTRIBUTES = qw(stats);

my %_seen = ();
my @KEYWORDS = sort grep { not $_seen{$_}++ }
               (keys(%ALIASES), @SKILLS, @ATTRIBUTES, qw{confesses exits helps builds});

sub loop {
    my $self = shift;
    $self = $self->load(@_);
    while (1) {
        my @args   = $self->parse_input($self->term->readline("absx > ")) or next;
        my $alias  = shift(@args) // next;
        my $actor  = $self->get_actor($alias) || do { warn "-absx: $alias: actor not found\n"; next };
        my $action = shift(@args) || do { warn "-absx: $alias: missing action\n";  next }; # TODO run help instead?
        my $cb = eval { $actor->exercise($action, @args) };
        warn $@ if $@;
        if(ref($cb) eq 'CODE') {
            eval { $cb->($self) };
            warn $@ if $@;
        }
    };
    return $self;
}

sub load {
    my $self = shift;
    $self = $self->new(@_) unless ref $self;
    my $save = $self->model->load(qw(IF EXISTS));
    if($save) {
        my $labels = delete $save->{'actors'};
        $self->{'actors'} = [ ];
        %ALIASES = (_INDEX => 0);
        foreach my $label (@$labels) {
            print "Loading $label\n";
            my ($i, $class, $alias) = split(':', $label);
            my $module = "ABSX::Actor::".ucfirst $class;
            (my $file  = "$module.pm") =~ s{::}{/}g;
            require $file;
            my $s = $module->new({domain => $self->domain, alias => $alias})->model->load;
            my $child = $module->new($s);
            $self->add_actor($alias, $child);
        }
    }
    return $self;
}

sub parse_input {
    my ($self, $line) = @_;
    return unless $line;
    $line =~ s{(?:^\s+|\s+$)}{};
    #split(/('[^']*')/, $line); # TODO quotes
    my @args = split(/ +/, $line);
    return @args;
}

sub add_alias {
    my ($self, $alias) = @_;
    throw '-absx: alias already defined' if $ALIASES{$alias};
    $ALIASES{$alias} = $ALIASES{'_INDEX'}++;
    push @KEYWORDS, $alias; # TODO uniq?
}

sub get_actor {
    my ($self, $alias) = @_;
    my $actor_id = $ALIASES{$alias} // $alias;
    return unless $actor_id =~ m/^\d+$/;
    $self->actors->[$actor_id];
}

sub add_actor {
    my ($self, $alias, $child) = @_;
    $self->actors($child);
    $self->add_alias($alias);
    $child->{'domain'} = $self->domain; # FIXME this should be done via accessor
    return $child;
}

sub actors {
    my $self = shift;
    my $actors = $self->{'actors'} ||= do {
        $self->uuid(0);
        my $factory = ABSX::Actor::Factory->new({alias => 'factory'});
        $factory->uuid(1);
        [ $self, $factory ];
    };
    if (scalar(@_)) {
        my $inc = scalar(@$actors);
        foreach my $actor (@_) {
            $actor->uuid($inc++);
            push(@$actors, $actor);
        }
    }
    return $actors;
}

sub term {
    my $self = shift;
    return $self->{'term'} ||= do {
        my $term = Term::ReadLine->new('ABSX Console Interface');
        my $attr = $term->Attribs;
        $attr->{completion_suppress_append}    = 1;
        $attr->{attempted_completion_function} = sub { $term->completion_matches(shift, \&keyword) };
        $attr->ornaments(0);
        $term;
    };
}

{
    my $KEY_INC;
    sub keyword {
      my ($text, $state) = @_;
        return unless $text;
        ($state ? $KEY_INC++ : ($KEY_INC = 0));
        for (; $KEY_INC<=$#KEYWORDS; $KEY_INC++) {
            return $KEYWORDS[$KEY_INC] if $KEYWORDS[$KEY_INC] =~ /^\Q$text/;
        };
        return undef;
    }
}

sub exits { exit }
sub helps {
    print <<END_HELP_MSG;
ABSX Console, Version 0.1

  console <ACTION> [OPTIONS]

ACTIONS

  helps              Prints this message
  confesses          Dumps this actor's data
  exits              Quit current console app
  saves              Writes all actors to storage

END_HELP_MSG
}


sub saves {
    my ($self) = @_;
    foreach my $actor (@{$self->actors}) {
        $actor->{'domain'} = $self->domain;
        $actor->model->write;
    }
}

1;
__END__
=head1 NAME

ABSX::Actor::Console

=head1 SYNOPSIS

A console for game management.

=cut
