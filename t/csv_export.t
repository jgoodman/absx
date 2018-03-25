#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use File::Slurp;
use Text::CSV;
use FindBin;

my %subtests = (
    Abilities => \&abilities,
    Int       => \&attributes,
    Spells    => \&spells,
    Virtues   => \&virtues,
);

my $TM = $ENV{'TEST_METHOD'};
plan tests => $TM ? 1 : 4;
die "Unkown test method [$TM]!\n" if $TM && !$subtests{$TM};

my $LATEST;
my $data = get_data();
foreach my $header (sort keys %$data) {
    my $sub = ($header =~ m/^Character, (\w+),?/)
            ? $subtests{$1}
            : die "Unkown subtest method [$header]!\n";
    my $section = $1;
    next if $TM && $TM ne $section;
    ok(eval { $sub->($header => $data->{$header}) }, "Processed $section");
    diag("Found Error: $@") if $@;
}

sub latest_raw_txt {
    (my $data_dir = $FindBin::Bin) =~ s{/t$}{/data};
    opendir my $DH, $data_dir or die "Failed opendir [$data_dir]!";
    my $latest = (sort { $b cmp $b } grep { m/^\d\d\d\d-\d\d-\d\d(?:-\d+)?\.raw\.txt$/ } readdir $DH)[0];
    ($LATEST) = $latest =~ m/^([\d-]+)\.raw\.txt$/;
    note "Latest: $LATEST";
    "$data_dir/$latest";
}

sub get_data {
    my $text = read_file latest_raw_txt();
    my %data;
    my $cur  = '';
    foreach my $line (split("\n", $text)) {
        next unless $line;
        if($line =~ s/^(Character)\s+/$1, /) {
            $line =~ s/  +/, /g;
            $cur = $line;
            next;
        }
        next unless $cur;
        push @{$data{$cur} ||= []}, $line;
    }
    return \%data;
}

sub parse_row {
    my ($row) = @_;
    $row =~ s/^([\w ]+)    (\w)/$2/;
    return ($1, $row);
}

sub write_csv {
    my ($name,$data) = @_;
    my $csv = Text::CSV->new( { binary => 1 } ) or die "Cannot use CSV: ".Text::CSV->error_diag ();
    $csv->eol("\r\n");
    (my $file = $FindBin::Bin) =~ s{/t$}{/export};
    mkdir $file unless -e $file;
    $file .= "/$LATEST";
    mkdir $file unless -e $file;
    $file .= "/$name.csv";
    open my $fh, ">:encoding(utf8)", $file or die "Error [>$file]: $!";
    $csv->print($fh, $_) for @$data;
    return $file;
}

sub abilities {
    my ($header, $chars) = @_;
    my $rows = [[qw(Character Ability Rank Speciality)]];
    foreach my $char (@$chars) {
        my ($name, $abilities) = parse_row($char);

        # Remove comma in parens to avoid splitting them
        $abilities =~ s/(\([^\(\)]+), ([^\(\)]+\))\.?/$1:$2/g;

        foreach my $ability (split(', ', $abilities)) {
            # Clean up parens for specializations
            $ability =~ s/\( ( [\w\s]* ) \) \.?$/$1/x;
            my @row = ($name, split(/ +(\d+) */, $ability));
            $row[$_] //= '' for (1..3);
            push @$rows, \@row;
        }
    }
    write_csv('Abilities', $rows);
}

sub attributes {
    my ($header, $rows) = @_;
    my @cols = split(', ', $header);
    my @chars;
    my @weap_cols = qw(Name INIT ATK DFN DAM);
    while(my $row = shift @$rows) {
        $row =~ s/, (Unc .+)$//g;
        my $wp = $1;
        my @values = split(/(?:, | {2,})/, $row);
        my %r;
        foreach my $col (@cols) {
            $r{$col} = shift(@values);
        }
        $r{'Wound Penalties'} = { map { split(/ +/, $_, 2) } $wp =~ m/^(Unc .+), (Inc .+)$/ };
        $r{'Wound Penalties'}->{Unc} = { map { split ' ', $_ } split(', ', $r{'Wound Penalties'}->{Unc}) };
        $r{'Wound_Penalties'} = delete $r{'Wound Penalties'};
        while ($rows->[0] && $rows->[0] =~ m/^ {10,}\w/) {
            (my $weap_raw = shift(@$rows)) =~ s/^ +//;
            my %weapon;
            @weapon{@weap_cols} = split /  +/, $weap_raw;
            $weapon{Name} =~ s/, /:/;
            push @{$r{'Weapons'} ||= []}, \%weapon;
        }
        push @chars, \%r;
    }
    pop(@cols); # remove "wound penalities"
    my @attr = ([sort @cols]);
    my @weaps = (['Character', sort @weap_cols]);
    foreach my $char (@chars) {
        my $wp = delete $char->{'Wound_Penalties'}; # TODO Save this data, for now tho ignore it
        foreach my $r (@{ delete $char->{'Weapons'} }) {
            push @weaps, [ $char->{'Character'}, map {$r->{$_}} sort @weap_cols ];
        }
        my $wounds  = delete $char->{Wound_Penalties};
        push @attr, [map { $char->{$_} } sort keys %$char];
    }
    write_csv('Attributes', \@attr);
    write_csv('CharacterWeapons', \@weaps);
}

sub spells {
    my ($header, $rows) = @_;
    my @cols = split(', ', $header);
    foreach (@$rows) {
        my ($name, $row) = parse_row($_);
    }
}

sub virtues {
    my ($header, $rows) = @_;
    my @cols = split(', ', $header);
    foreach (@$rows) {
        my ($name, $row) = parse_row($_);
    }
}
