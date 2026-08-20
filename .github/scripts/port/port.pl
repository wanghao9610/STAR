#!/usr/bin/env perl
# Transform engine behind port.sh. One .claude skill file body becomes the same
# file's body in another tree by (1) an ordered substitution table that carries
# that harness's vocabulary and (2) an override list holding every span where the
# tree says something Claude's text does not.
#
#   port.pl check|write|regen  TREE [TREE ...]
#
# Reads   <root>/.claude/skills/**.md            the one authored copy
#         <root>/.github/scripts/port/T.rules    ordered pattern -> replacement
#         <root>/.github/scripts/port/T.overrides  anchored per-tree spans
# Writes  nothing in check; the tree's bodies in write; T.overrides in regen.
#
# Frontmatter is NOT generated. Each harness tunes its own `description` to its
# own length limit and its own trigger wording, and check_consistency.sh already
# holds the frontmatter invariants. Everything below the closing `---` is generated.
#
# A file whose text comes out the same for a tree and for .agents is not written
# twice. The real file lives in .agents/skills, and the tree carries a relative
# symlink at the same path. Which files those are is nobody's list: a tree links
# a file exactly when the body generated for it equals the body generated for
# .agents and the two carry the same frontmatter. That is why no SKILL.md is
# ever a link — each harness tunes its own description — and why a rubric that
# names no tool always is. check and write both decide it fresh, so a rewording
# that makes a shared file harness-specific turns its links back into files, and
# one that removes the last tool name from a file turns the files into links.
#
# --write always brings .agents/skills up to date first, whatever --tree names,
# since it is where the shared text physically lives and every link points at it.
use strict;
use warnings;

binmode(STDOUT, ':encoding(UTF-8)');
binmode(STDERR, ':encoding(UTF-8)');

my $ROOT = $ENV{PORT_ROOT} or die "PORT_ROOT unset\n";
my $mode = shift // 'check';
my @trees = @ARGV or die "no trees given\n";

# The authored text as it stood before this run wrote anything. A file all seven
# trees word the same way physically lives in .agents/skills and .claude/skills
# reaches it through a link, so writing the hub first would destroy the very text
# the other trees are generated from — and a file that has just stopped being
# shared, because someone put a tool name in it, would be normalised into the
# neutral wording instead of splitting into seven. Everything reads this snapshot.
my %SRC;

# ---------------------------------------------------------------- file helpers
sub slurp { my ($p) = @_; open my $fh, '<:encoding(UTF-8)', $p or return undef;
            local $/; my $t = <$fh>; close $fh; return $t }

# Split a file into (frontmatter-including-delimiters, body).
sub split_fm {
    my ($t) = @_;
    return ('', $t) unless $t =~ /\A---\n/;
    my $i = index($t, "\n---\n", 4);
    return ('', $t) if $i < 0;
    return (substr($t, 0, $i + 5), substr($t, $i + 5));
}

# The one writer. A skill's scripts are executable in every tree — the checker
# fails a tree where one is not — and a file written here has just replaced a
# link, so the mode has to be set rather than inherited.
sub write_file {
    my ($path, $rel, $text) = @_;
    open my $fh, '>:encoding(UTF-8)', $path or die "cannot write $path\n";
    print $fh $text;
    close $fh;
    chmod 0755, $path if $rel =~ /\.sh\z/;
}

sub rel_list {
    my @out;
    my @stack = ("$ROOT/.claude/skills");
    while (my $d = pop @stack) {
        opendir my $dh, $d or next;
        for my $e (readdir $dh) {
            next if $e eq '.' or $e eq '..';
            my $p = "$d/$e";
            if (-d $p) { push @stack, $p } elsif ($e =~ /\.(?:md|sh)\z/) { push @out, $p }
        }
        closedir $dh;
    }
    s{^\Q$ROOT/.claude/skills/\E}{} for @out;
    return sort @out;
}

# ---------------------------------------------------------------- rules
sub load_rules {
    my ($tree) = @_;
    my $p = "$ROOT/.github/scripts/port/$tree.rules";
    open my $fh, '<:encoding(UTF-8)', $p or die "missing rules: $p\n";
    my @r;
    while (my $l = <$fh>) {
        chomp $l;
        next if $l =~ /^\s*#/ or $l !~ /\t/;
        my ($pat, $rep) = split /\t/, $l, 2;
        $rep = '' unless defined $rep;
        push @r, [$pat, $rep];
    }
    close $fh;
    return \@r;
}

sub apply_rules {
    my ($body, $rules) = @_;
    for my $r (@$rules) {
        my ($pat, $rep) = @$r;
        $body =~ s/$pat/$rep/g;
    }
    return $body;
}

# ---------------------------------------------------------------- overrides
# Record shape, line counts instead of delimiters so no text needs escaping:
#   ### <relative path>
#   --- <n>
#   <n source lines, as they read after the substitution table>
#   +++ <m>
#   <m lines as this tree reads>
sub load_overrides {
    my ($tree) = @_;
    my $p = "$ROOT/.github/scripts/port/$tree.overrides";
    return {} unless -f $p;
    open my $fh, '<:encoding(UTF-8)', $p or die "cannot read $p\n";
    my (%ov, $rel);
    while (my $l = <$fh>) {
        chomp $l;
        if    ($l =~ /^### (.+)$/) { $rel = $1; next }
        elsif ($l =~ /^--- (\d+)$/) {
            my $n = $1;
            my @old = map { my $x = <$fh>; chomp $x; $x } (1 .. $n);
            my $h = <$fh>; chomp $h;
            $h =~ /^\+\+\+ (\d+)$/ or die "$p: malformed record in $rel\n";
            my @new = map { my $x = <$fh>; chomp $x; $x } (1 .. $1);
            push @{ $ov{$rel} }, [\@old, \@new];
        }
    }
    close $fh;
    return \%ov;
}

sub apply_overrides {
    my ($body, $recs, $rel, $tree, $errs) = @_;
    return $body unless $recs;
    my @lines = split /\n/, $body, -1;
    my $cursor = 0;
    for my $rec (@$recs) {
        my ($old, $new) = @$rec;
        my $n = scalar @$old;
        my $at = -1;
        for (my $i = $cursor; $i + $n <= @lines; $i++) {
            my $hit = 1;
            for my $k (0 .. $n - 1) { if ($lines[$i + $k] ne $old->[$k]) { $hit = 0; last } }
            if ($hit) { $at = $i; last }
        }
        if ($at < 0) {
            push @$errs, sprintf("%s  %s\n      the tree rewrote this line and the source no longer carries it:\n      %s",
                                 $tree, $rel, substr($old->[0], 0, 150));
            next;
        }
        splice @lines, $at, $n, @$new;
        $cursor = $at + scalar @$new;
    }
    return join("\n", @lines);
}

# ---------------------------------------------------------------- generate
sub generate {
    my ($rel, $tree, $rules, $ov, $errs) = @_;
    my $src = $SRC{$rel};
    return undef unless defined $src;
    my (undef, $body) = split_fm($src);
    # A skill's scripts are one shared file in all seven trees — check_consistency
    # holds that as an invariant — so nothing here rewrites them: a substitution
    # table aimed at prose has no business inside a shell script, and the file
    # coming out unchanged is what puts it on the shared side of the line below.
    return $body unless $rel =~ /\.md\z/;
    $body = apply_rules($body, $rules);
    $body = apply_overrides($body, $ov->{$rel}, $rel, $tree, $errs);
    return $body;
}

# ---------------------------------------------------------------- the hub
# Where a shared file physically lives, and the relative path a tree's link to it
# must hold: out of the file's own directory to the project root, then back down.
my $HUB = 'agents';

sub link_target {
    my ($rel) = @_;
    my $up = ($rel =~ tr{/}{}) + 2;
    return ('../' x $up) . ".$HUB/skills/$rel";
}

# ---------------------------------------------------------------- modes
my @rels = rel_list();
$SRC{$_} = slurp("$ROOT/.claude/skills/$_") for @rels;
my $bad = 0;

# The hub's own bodies, generated once: every other tree compares against them to
# decide file-or-link. In write mode the hub is written here rather than in its
# own pass below, so a --tree run that does not name it still links at current
# text. Errors go to a sink — the hub reports its own in its pass.
my (%hub_body, %hub_fm);
{
    my $rules = load_rules($HUB);
    my $ov    = ($mode eq 'regen') ? {} : load_overrides($HUB);
    my @sink;
    for my $rel (@rels) {
        my $target = "$ROOT/.$HUB/skills/$rel";
        my $tt = slurp($target);
        next unless defined $tt;
        my ($tfm, $tbody) = split_fm($tt);
        my $gen = generate($rel, $HUB, $rules, $ov, \@sink);
        next unless defined $gen;
        $hub_fm{$rel}   = $tfm;
        $hub_body{$rel} = $gen;
        next unless $mode eq 'write' && $gen ne $tbody;
        write_file($target, $rel, $tfm . $gen);
    }
}

for my $tree (@trees) {
    # .claude is the authored copy, so it has no spans to record against itself;
    # it is in the list for the files it shares with the hub, nothing else.
    next if $mode eq 'regen' && $tree eq 'claude';
    my $rules = load_rules($tree);
    my $ov    = ($mode eq 'regen') ? {} : load_overrides($tree);
    my (@errs, @mismatch, @newov);
    my ($ok, $missing, $linked, $relinked, $unlinked) = (0, 0, 0, 0, 0);

    for my $rel (@rels) {
        my $target = "$ROOT/.$tree/skills/$rel";
        my $tt = slurp($target);
        unless (defined $tt) {
            $missing++;
            push @errs, sprintf("%s  %s\n      no such file in this tree", $tree, $rel);
            next;
        }
        my ($tfm, $tbody) = split_fm($tt);
        my $gen = generate($rel, $tree, $rules, $ov, \@errs);

        # File or link. The hub holds every shared file itself; any other tree
        # links at it exactly when its own text comes out the same, frontmatter
        # included. Both sides are decided from the generated text, so a file
        # becomes a link and a link becomes a file on their own as the wording
        # moves — neither is recorded anywhere to fall out of date.
        if ($mode ne 'regen') {
            my $held  = -l $target ? readlink($target) : undef;
            if ($tree eq $HUB) {
                if (defined $held) {
                    push @errs, sprintf("%s  %s\n      the hub holds the real file; this is a link to %s",
                                        $tree, $rel, $held);
                    next;
                }
            } else {
                my $want = defined $hub_body{$rel}
                        && $gen eq $hub_body{$rel}
                        && $tfm eq $hub_fm{$rel};
                my $wanted = link_target($rel);
                if ($want && defined $held && $held eq $wanted) { $linked++; $ok++; next }
                if ($want) {
                    if ($mode eq 'write') {
                        unlink $target or die "cannot replace $target\n";
                        symlink($wanted, $target) or die "cannot link $target\n";
                        $linked++; $relinked++; $ok++;
                    } else {
                        push @errs, sprintf("%s  %s\n      .%s carries this same text, so this must be a link into it%s",
                                            $tree, $rel, $HUB,
                                            defined $held ? ", not a link to $held" : "");
                    }
                    next;
                }
                if (defined $held) {
                    if ($mode eq 'write') {
                        unlink $target or die "cannot replace $target\n";
                        write_file($target, $rel, $tfm . $gen);
                        $unlinked++; $ok++;
                    } else {
                        push @errs, sprintf("%s  %s\n      a link into .%s, but this tree no longer words it the same way",
                                            $tree, $rel, $HUB);
                    }
                    next;
                }
            }
        }

        if ($mode eq 'regen') {
            # Every span the substitution table could not reach becomes a record.
            push @newov, [$rel, $gen, $tbody] if $gen ne $tbody;
            $ok++;
            next;
        }
        if ($gen eq $tbody) { $ok++; next }
        push @mismatch, [$rel, $gen, $tbody];
        write_file($target, $rel, $tfm . $gen) if $mode eq 'write';
    }

    if ($mode eq 'regen') {
        my $p = "$ROOT/.github/scripts/port/$tree.overrides";
        open my $fh, '>:encoding(UTF-8)', $p or die "cannot write $p\n";
        print $fh <<"HDR";
# Generated by: bash .github/scripts/port.sh --regen --tree $tree
# Every span in the $tree tree that its vocabulary table cannot produce from the
# .claude text — i.e. every place this harness genuinely says something else.
# A record is anchored by the source lines themselves, so editing one of those
# lines in .claude makes port.sh --check fail here by name instead of silently
# leaving this tree behind. Re-port the span, then regenerate this file.
HDR
        my $n = 0;
        for my $m (@newov) {
            my ($rel, $gen, $tbody) = @$m;
            for my $h (hunks($gen, $tbody)) {
                my ($old, $new) = @$h;
                print $fh "### $rel\n";
                print $fh "--- ", scalar(@$old), "\n", map { "$_\n" } @$old;
                print $fh "+++ ", scalar(@$new), "\n", map { "$_\n" } @$new;
                $n++;
            }
        }
        close $fh;
        printf "%-11s regen: %d override records over %d files\n", ".$tree", $n, scalar(@newov);
        next;
    }

    my $verb = $mode eq 'write' ? 'rewritten' : 'differ';
    printf "%-11s %3d / %3d reproduced   %3d shared with .%s   %s %d   unanchored %d\n",
           ".$tree", $ok, scalar(@rels), $linked, $HUB, $verb, scalar(@mismatch), scalar(@errs);
    printf "%-11s %d file(s) became links, %d link(s) became files\n", '', $relinked, $unlinked
        if $relinked || $unlinked;
    for my $e (@errs) { print "      ! $e\n"; $bad = 1 }
    if ($mode eq 'check') {
        for my $m (@mismatch) {
            my ($rel, $gen, $tbody) = @$m;
            $bad = 1;
            print "      FAIL .$tree/skills/$rel\n";
            my @h = hunks($gen, $tbody);
            for my $h (@h[0 .. ($#h < 2 ? $#h : 2)]) {
                print "        generated: ", substr($h->[0][0] // '(nothing)', 0, 140), "\n";
                print "        in tree:   ", substr($h->[1][0] // '(nothing)', 0, 140), "\n";
            }
            print "        (", scalar(@h), " differing spans)\n" if @h > 3;
        }
    }
}
exit($bad ? 1 : 0);

# ---------------------------------------------------------------- diff
# Minimal line-level hunks between two texts: longest common subsequence over
# lines, then each maximal run of non-common lines becomes one (old, new) pair.
sub hunks {
    my ($a, $b) = @_;
    my @A = split /\n/, $a, -1;
    my @B = split /\n/, $b, -1;
    # trim the common head and tail first — these files agree almost everywhere,
    # so the quadratic table below only ever sees the part that actually moved.
    my ($h, $t) = (0, 0);
    $h++ while $h < @A && $h < @B && $A[$h] eq $B[$h];
    $t++ while $t < @A - $h && $t < @B - $h && $A[$#A - $t] eq $B[$#B - $t];
    my @a2 = @A[$h .. $#A - $t];
    my @b2 = @B[$h .. $#B - $t];
    return () unless @a2 || @b2;

    # LCS on the trimmed middle
    my @L;
    for my $i (0 .. scalar(@a2)) { $L[$i][scalar(@b2)] = 0 }
    for my $j (0 .. scalar(@b2)) { $L[scalar(@a2)][$j] = 0 }
    for (my $i = $#a2 + 1 - 1; $i >= 0; $i--) {
        for (my $j = $#b2 + 1 - 1; $j >= 0; $j--) {
            $L[$i][$j] = $a2[$i] eq $b2[$j] ? 1 + $L[$i+1][$j+1]
                       : ($L[$i+1][$j] >= $L[$i][$j+1] ? $L[$i+1][$j] : $L[$i][$j+1]);
        }
    }
    my (@out, @po, @pn);
    my ($i, $j) = (0, 0);
    my $start = 0;
    my $flush = sub {
        push @out, [$start, [@po], [@pn]] if @po || @pn;
        @po = (); @pn = ();
    };
    while ($i < @a2 && $j < @b2) {
        if ($a2[$i] eq $b2[$j]) { $flush->(); $i++; $j++; $start = $i }
        elsif ($L[$i+1][$j] >= $L[$i][$j+1]) { push @po, $a2[$i++] }
        else { push @pn, $b2[$j++] }
    }
    push @po, @a2[$i .. $#a2] if $i <= $#a2;
    push @pn, @b2[$j .. $#b2] if $j <= $#b2;
    $flush->();

    # A pure insertion has no source lines to anchor it, and an empty anchor
    # matches anywhere. Give it neighbouring unchanged lines — enough of them to
    # include something that is not a blank line, and never reaching into a
    # neighbouring record's span — so the record says where the tree adds its
    # sentence and still fails loudly once the source around it is reworded.
    for my $k (0 .. $#out) {
        my ($at, $po, $pn) = @{ $out[$k] };
        next if @$po;
        my $prev_end = $k > 0 ? $out[$k-1][0] + scalar(@{ $out[$k-1][1] }) : 0;
        my $next_at  = $k < $#out ? $out[$k+1][0] : scalar(@a2);
        my @ctx;
        my $i = $at;
        while ($i > $prev_end && !grep { /\S/ } @ctx) { $i--; unshift @ctx, $a2[$i] }
        if (!grep { /\S/ } @ctx) {                      # nothing usable behind it
            @ctx = ();
            my $j = $at;
            while ($j < $next_at && !grep { /\S/ } @ctx) { push @ctx, $a2[$j]; $j++ }
            push @$po, @ctx; push @$pn, @ctx;
        } else {
            unshift @$po, @ctx; unshift @$pn, @ctx;
        }
    }
    return map { [$_->[1], $_->[2]] } @out;
}
