package ABSX::Model;

use strict;
use warnings;
use FindBin qw($Bin);
use JSON;
use Throw;
use File::Slurp;

sub new {
    my ($class, $args) = @_;
    $args ||= { };
    bless $args, $class;
}

sub data { shift->{'data'} || throw 'Missing data' }

sub write {
    my $self = shift;
    my $data = $self->data;
    local $data->{'domain'} = $data->{'domain'};
    my $domain = delete $data->{'domain'};

    my $dir = "$Bin/../data/$domain";
    mkdir $dir unless -e $dir;
    write_file("$dir/".$data->{'alias'}, encode_json($data), "\n");
}

sub load {
    my ($self, @args) = @_;
    my $data = $self->data;
    local $data->{'domain'} = $data->{'domain'};
    my $domain = delete $data->{'domain'};

    my $alias = $data->{'alias'} || throw 'No alias defined';

    my $dir = "$Bin/../data/$domain";
    mkdir $dir unless -e $dir;
    my $file = "$dir/".$data->{'alias'};
    unless(-e $file) {
        return if uc(($args[0] || '') . ' ' . ($args[1] || '')) eq 'IF EXISTS';
        throw 'file not found', { file => $file };
    }
    decode_json(read_file($file));
}

1;
