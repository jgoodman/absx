#!/usr/bin/env perl
use strict;
use warnings;
use FindBin qw($Bin);
use File::Find;
use File::Path;

File::Find::find(sub {
    my $file = $_;
    return unless $file =~ m/\.pm$/;

    (my $tdir = $File::Find::dir) =~ s{^\Q$Bin/../lib/ABSX/\E}{};
    $tdir = lc("t/unit/$tdir");

    (my $tfile = lc($file)) =~ s{\.pm$}{\.t};

    my $tpath = "$Bin/../$tdir/$tfile";
    return if -e $tpath;

    print "Writing stub: $tpath\n";
    File::Path::make_path("$Bin/../$tdir");

    (my $module = $File::Find::name) =~ s{^\Q$Bin/../lib/\E}{};
    $module =~ s{/}{::}g;
    $module =~ s{\.pm$}{}g;

    (my $lib = $tdir) =~ s{[^/]+/}{\.\./}g;
    $lib =~ s{/[^/]+$}{/../lib};

    open my $FH, '>', $tpath or die "$tpath: $!";;
    print $FH stub($module, $lib);
}, "$Bin/../lib/ABSX");

sub stub {
    my ($module, $lib) = @_;
<<END_TEST_SCRIPT
#!/usr/bin/env perl
use strict;
use warnings;

use FindBin qw(\$Bin);
use File::Basename;
use lib "\$Bin/$lib";

use Test::More tests => 1;

my \$module = '$module';
use_ok(\$module);
END_TEST_SCRIPT
}
