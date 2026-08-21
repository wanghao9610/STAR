#!/usr/bin/env perl
# Drop override records from a port.pl overrides file, by the file they belong to
# and a substring of their first source line.
#
#   perl drop_records.pl <overrides-file> '<rel>::<substring>' ...
#
# The format is line-counted rather than delimited, so a record cannot be matched
# with a line-oriented tool: read it the way port.pl does, then write back what
# was not asked for. Each record is preceded by its own `### <rel>` header, which
# goes with it.
use strict;
use warnings;
use utf8;

binmode(STDOUT, ':encoding(UTF-8)');
my $file = shift or die "usage: drop_records.pl <overrides-file> '<rel>::<substring>' ...\n";
# Arguments arrive as bytes; the records are read as characters. Decode so a
# substring carrying ≤ or Chinese matches.
my @want = map { my $x = $_; utf8::decode($x); $x } @ARGV;
@want or die "no records named\n";

open my $fh, '<:encoding(UTF-8)', $file or die "cannot read $file: $!\n";
my (@out, $rel, $dropped) = ((), '', 0);
while (my $l = <$fh>) {
    if ($l =~ /^### (.+)\n$/ && $l !~ /^### Step /) { $rel = $1; push @out, $l; next }
    if ($l =~ /^--- (\d+)$/) {
        my $head = $l;
        my @old = map { scalar <$fh> } (1 .. $1);
        my $sep = <$fh>;
        $sep =~ /^\+\+\+ (\d+)$/ or die "$file: malformed record in $rel\n";
        my @new = map { scalar <$fh> } (1 .. $1);
        my $hit = 0;
        for my $w (@want) {
            my ($r, $s) = split /::/, $w, 2;
            $hit = 1 if $rel eq $r && defined $old[0] && index($old[0], $s) >= 0;
        }
        if ($hit) { $dropped++; pop @out if @out && $out[-1] =~ /^### /; next }
        push @out, $head, @old, $sep, @new;
        next;
    }
    push @out, $l;
}
close $fh;

open my $o, '>:encoding(UTF-8)', $file or die "cannot write $file: $!\n";
print $o @out;
close $o;
print "dropped $dropped record(s) from $file\n";
