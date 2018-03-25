#!/usr/bin/env perl
use strict;
use warnings;

use FindBin qw($Bin);
use File::Basename;
use lib "$Bin/../../../lib";

use Test::More tests => 1;

my $module = 'ABSX::Actor::Console';
use_ok($module);
