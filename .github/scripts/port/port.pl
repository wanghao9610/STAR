#!/usr/bin/env perl
# Port the neutral skill source under .agents/skills into six harness trees.
#
#   port.pl check|write|regen TREE [TREE ...]
#
# A Markdown body is adapted in two stages.  The Claude rules and overrides turn
# the neutral source into Claude wording; another harness then applies its own
# existing Claude-to-harness rules and overrides.  Frontmatter stays owned by
# each harness.  Shell scripts are copied without prose substitutions.
use strict;
use warnings;
use File::Basename qw(dirname);
use File::Path qw(make_path);

binmode(STDOUT, ':encoding(UTF-8)');
binmode(STDERR, ':encoding(UTF-8)');

my $ROOT = $ENV{PORT_ROOT} or die "PORT_ROOT unset\n";
my $mode = shift // 'check';
my @requested = @ARGV or die "no trees given\n";
my @ORDER = qw(claude cursor dsh kimi-code pi qwen);
my %VALID = map { $_ => 1 } @ORDER;
die "unknown mode: $mode\n" unless $mode =~ /\A(?:check|write|regen)\z/;
for my $tree (@requested) {
    die "unknown tree: $tree\n" unless $VALID{$tree};
}
my %wanted = map { $_ => 1 } @requested;
my @trees = grep { $wanted{$_} } @ORDER;
my $SOURCE_ROOT = '.agents/skills';

# ---------------------------------------------------------------- file helpers
sub slurp {
    my ($path) = @_;
    open my $fh, '<:encoding(UTF-8)', $path or return undef;
    local $/;
    my $text = <$fh>;
    close $fh;
    return $text;
}

sub split_fm {
    my ($text) = @_;
    return ('', $text) unless $text =~ /\A---\n/;
    my $at = index($text, "\n---\n", 4);
    return ('', $text) if $at < 0;
    return (substr($text, 0, $at + 5), substr($text, $at + 5));
}

sub write_file {
    my ($path, $rel, $text) = @_;
    make_path(dirname($path));
    unlink $path or die "cannot replace link $path\n" if -l $path;
    open my $fh, '>:encoding(UTF-8)', $path or die "cannot write $path\n";
    print {$fh} $text;
    close $fh;
    chmod 0755, $path if $rel =~ /\.sh\z/;
}

sub rel_list {
    my @out;
    my $base = "$ROOT/$SOURCE_ROOT";
    my @stack = ($base);
    while (my $dir = pop @stack) {
        opendir my $dh, $dir or next;
        for my $entry (readdir $dh) {
            next if $entry eq '.' or $entry eq '..';
            my $path = "$dir/$entry";
            if (-d $path) {
                push @stack, $path;
            } elsif ($entry =~ /\.(?:md|sh)\z/) {
                push @out, $path;
            }
        }
        closedir $dh;
    }
    s{^\Q$base/\E}{} for @out;
    return sort @out;
}

# ---------------------------------------------------------------- rules
sub load_rules {
    my ($tree) = @_;
    my $path = "$ROOT/.github/scripts/port/$tree.rules";
    open my $fh, '<:encoding(UTF-8)', $path or die "missing rules: $path\n";
    my @rules;
    while (my $line = <$fh>) {
        chomp $line;
        next if $line =~ /^\s*#/ or $line !~ /\t/;
        my ($pattern, $replacement) = split /\t/, $line, 2;
        $replacement = '' unless defined $replacement;
        push @rules, [$pattern, $replacement];
    }
    close $fh;
    return \@rules;
}

sub apply_rules {
    my ($body, $rules) = @_;
    for my $rule (@$rules) {
        my ($pattern, $replacement) = @$rule;
        $body =~ s/$pattern/$replacement/g;
    }
    return $body;
}

# ------------------------------------------------------------- anchored spans
# Record shape, using line counts so source and replacement text need no escaping:
#   ### <relative path>
#   --- <n>
#   <n source lines after the applicable substitution table>
#   +++ <m>
#   <m harness lines>
sub load_overrides {
    my ($tree) = @_;
    my $path = "$ROOT/.github/scripts/port/$tree.overrides";
    return {} unless -f $path;
    open my $fh, '<:encoding(UTF-8)', $path or die "cannot read $path\n";
    my (%overrides, $rel);
    while (my $line = <$fh>) {
        chomp $line;
        if ($line =~ /^### (.+)$/) {
            $rel = $1;
            next;
        }
        if ($line =~ /^--- (\d+)$/) {
            defined $rel or die "$path: record without a relative path\n";
            my $old_count = $1;
            my @old = map {
                my $item = <$fh>;
                defined $item or die "$path: truncated source span in $rel\n";
                chomp $item;
                $item;
            } (1 .. $old_count);
            my $header = <$fh>;
            defined $header or die "$path: truncated record in $rel\n";
            chomp $header;
            $header =~ /^\+\+\+ (\d+)$/ or die "$path: malformed record in $rel\n";
            my $new_count = $1;
            my @new = map {
                my $item = <$fh>;
                defined $item or die "$path: truncated replacement span in $rel\n";
                chomp $item;
                $item;
            } (1 .. $new_count);
            push @{ $overrides{$rel} }, [\@old, \@new];
        }
    }
    close $fh;
    return \%overrides;
}

sub apply_overrides {
    my ($body, $records, $rel, $tree, $errors) = @_;
    return $body unless $records;
    my @lines = split /\n/, $body, -1;
    my $cursor = 0;
    for my $record (@$records) {
        my ($old, $new) = @$record;
        my $count = scalar @$old;
        if (!$count) {
            push @$errors, "$tree  $rel\n      override has an empty source anchor";
            next;
        }
        my $found = -1;
        for (my $at = $cursor; $at + $count <= @lines; $at++) {
            my $matches = 1;
            for my $offset (0 .. $count - 1) {
                if ($lines[$at + $offset] ne $old->[$offset]) {
                    $matches = 0;
                    last;
                }
            }
            if ($matches) {
                $found = $at;
                last;
            }
        }
        if ($found < 0) {
            push @$errors, sprintf(
                "%s  %s\n      this override no longer finds its neutral-source anchor:\n      %s",
                $tree, $rel, substr($old->[0], 0, 150)
            );
            next;
        }
        splice @lines, $found, $count, @$new;
        $cursor = $found + scalar @$new;
    }
    return join("\n", @lines);
}

# --------------------------------------------------------------- transformation
my %SOURCE;
my @rels = rel_list();
$SOURCE{$_} = slurp("$ROOT/$SOURCE_ROOT/$_") for @rels;

sub load_adapters {
    my ($tree) = @_;
    return {
        claude_rules     => load_rules('claude'),
        claude_overrides => load_overrides('claude'),
        tree_rules       => $tree eq 'claude' ? [] : load_rules($tree),
        tree_overrides   => $tree eq 'claude' ? {} : load_overrides($tree),
    };
}

sub generate {
    my ($rel, $tree, $adapters, $errors, $skip_override) = @_;
    my $source = $SOURCE{$rel};
    return undef unless defined $source;
    my (undef, $body) = split_fm($source);
    return $body unless $rel =~ /\.md\z/;

    $body = apply_rules($body, $adapters->{claude_rules});
    if (!defined $skip_override || $skip_override ne 'claude') {
        $body = apply_overrides(
            $body, $adapters->{claude_overrides}{$rel}, $rel, 'claude', $errors
        );
    }
    if ($tree ne 'claude') {
        $body = apply_rules($body, $adapters->{tree_rules});
        if (!defined $skip_override || $skip_override ne $tree) {
            $body = apply_overrides(
                $body, $adapters->{tree_overrides}{$rel}, $rel, $tree, $errors
            );
        }
    }
    return $body;
}

sub link_to_source {
    my ($rel) = @_;
    my $up = ($rel =~ tr{/}{}) + 2;
    return ('../' x $up) . "$SOURCE_ROOT/$rel";
}

sub replace_with_link {
    my ($path, $rel) = @_;
    make_path(dirname($path));
    unlink $path or die "cannot replace $path\n" if -e $path || -l $path;
    symlink(link_to_source($rel), $path) or die "cannot link $path\n";
}

# ---------------------------------------------------------------------- modes
my $bad = 0;
for my $tree (@trees) {
    # Reload for each tree.  If one command regenerates Claude first, later
    # harnesses immediately use that newly recorded neutral-to-Claude adapter.
    my $adapters = load_adapters($tree);
    my (@errors, @mismatches, @new_overrides);
    my ($ok, $linked, $relinked, $unlinked, $missing) = (0, 0, 0, 0, 0);

    for my $rel (@rels) {
        my $target = "$ROOT/.$tree/skills/$rel";
        my $current = slurp($target);
        if (!defined $current) {
            $missing++;
            push @errors, "$tree  $rel\n      no such file in this harness tree";
            next;
        }
        my ($frontmatter, $current_body) = split_fm($current);
        my $generated = generate(
            $rel, $tree, $adapters, \@errors,
            $mode eq 'regen' ? $tree : undef
        );

        if ($mode eq 'regen') {
            push @new_overrides, [$rel, $generated, $current_body]
                if $generated ne $current_body;
            $ok++;
            next;
        }

        my $desired = $frontmatter . $generated;
        my $source = $SOURCE{$rel};
        my $held_link = -l $target ? readlink($target) : undef;
        if ($desired eq $source) {
            my $wanted_link = link_to_source($rel);
            if (defined $held_link && $held_link eq $wanted_link) {
                $linked++;
                $ok++;
                next;
            }
            if ($mode eq 'write') {
                replace_with_link($target, $rel);
                $linked++;
                $relinked++;
                $ok++;
            } else {
                push @errors, sprintf(
                    "%s  %s\n      generated bytes equal %s/%s, so this must be a link%s",
                    $tree, $rel, $SOURCE_ROOT, $rel,
                    defined $held_link ? ", not a link to $held_link" : ''
                );
            }
            next;
        }

        if (defined $held_link) {
            if ($mode eq 'write') {
                write_file($target, $rel, $desired);
                $unlinked++;
                $ok++;
            } else {
                push @errors, "$tree  $rel\n      harness-specific output cannot remain a link to $held_link";
            }
            next;
        }
        if ($current eq $desired) {
            $ok++;
            next;
        }
        push @mismatches, [$rel, $desired, $current];
        if ($mode eq 'write') {
            write_file($target, $rel, $desired);
            $ok++;
        }
    }

    if ($mode eq 'regen') {
        my $path = "$ROOT/.github/scripts/port/$tree.overrides";
        my $text = "# Generated by: bash .github/scripts/port.sh --regen --tree $tree\n";
        $text .= "# Every span in .$tree that its adapter cannot produce from .agents/skills.\n";
        $text .= "# Records are anchored by neutral-source-derived lines; port.sh fails if an anchor moves.\n";
        my $records = 0;
        for my $item (@new_overrides) {
            my ($rel, $generated, $current_body) = @$item;
            my @file_hunks = hunks($generated, $current_body);
            my @roundtrip_errors;
            my $roundtrip = apply_overrides(
                $generated, \@file_hunks, $rel, $tree, \@roundtrip_errors
            );
            # A moved block can produce individually valid minimal hunks whose
            # sequential anchors do not reproduce the target. Prefer one larger,
            # exact anchor over an override file that cannot verify itself.
            if (@roundtrip_errors || $roundtrip ne $current_body) {
                @file_hunks = ([
                    [split(/\n/, $generated, -1)],
                    [split(/\n/, $current_body, -1)],
                ]);
            }
            for my $hunk (@file_hunks) {
                my ($old, $new) = @$hunk;
                $text .= "### $rel\n";
                $text .= '--- ' . scalar(@$old) . "\n" . join('', map { "$_\n" } @$old);
                $text .= '+++ ' . scalar(@$new) . "\n" . join('', map { "$_\n" } @$new);
                $records++;
            }
        }
        write_file($path, "$tree.overrides", $text);
        printf "%-11s regen: %d override records over %d files\n",
            ".$tree", $records, scalar(@new_overrides);
        next;
    }

    my $verb = $mode eq 'write' ? 'rewritten' : 'differ';
    printf "%-11s %3d / %3d reproduced   %3d linked   %s %d   errors %d\n",
        ".$tree", $ok, scalar(@rels), $linked, $verb,
        scalar(@mismatches), scalar(@errors);
    printf "%-11s %d file(s) became links, %d link(s) became files\n",
        '', $relinked, $unlinked if $relinked || $unlinked;
    for my $error (@errors) {
        print "      ! $error\n";
        $bad = 1;
    }
    if ($mode eq 'check') {
        for my $item (@mismatches) {
            my ($rel, $generated, $current) = @$item;
            $bad = 1;
            print "      FAIL .$tree/skills/$rel\n";
            my @parts = hunks($generated, $current);
            my $last = $#parts < 2 ? $#parts : 2;
            for my $index (0 .. $last) {
                my $hunk = $parts[$index];
                print "        generated: ", substr($hunk->[0][0] // '(nothing)', 0, 140), "\n";
                print "        in tree:   ", substr($hunk->[1][0] // '(nothing)', 0, 140), "\n";
            }
            print "        (", scalar(@parts), " differing spans)\n" if @parts > 3;
        }
    }
}
exit($bad ? 1 : 0);

# ----------------------------------------------------------------------- diff
# Minimal line-level hunks between two texts: longest common subsequence over
# the differing middle, followed by anchors for pure insertions.
sub hunks {
    my ($a, $b) = @_;
    my @A = split /\n/, $a, -1;
    my @B = split /\n/, $b, -1;
    my ($head, $tail) = (0, 0);
    $head++ while $head < @A && $head < @B && $A[$head] eq $B[$head];
    $tail++ while $tail < @A - $head && $tail < @B - $head
        && $A[$#A - $tail] eq $B[$#B - $tail];
    my $a_end = $#A - $tail;
    my $b_end = $#B - $tail;
    my @a2 = $head <= $a_end ? @A[$head .. $a_end] : ();
    my @b2 = $head <= $b_end ? @B[$head .. $b_end] : ();
    return () unless @a2 || @b2;

    my @length;
    for my $i (0 .. scalar(@a2)) { $length[$i][scalar(@b2)] = 0 }
    for my $j (0 .. scalar(@b2)) { $length[scalar(@a2)][$j] = 0 }
    for (my $i = $#a2; $i >= 0; $i--) {
        for (my $j = $#b2; $j >= 0; $j--) {
            $length[$i][$j] = $a2[$i] eq $b2[$j]
                ? 1 + $length[$i + 1][$j + 1]
                : ($length[$i + 1][$j] >= $length[$i][$j + 1]
                    ? $length[$i + 1][$j] : $length[$i][$j + 1]);
        }
    }
    my (@out, @old, @new);
    my ($i, $j, $start) = (0, 0, 0);
    my $flush = sub {
        push @out, [$start, [@old], [@new]] if @old || @new;
        @old = ();
        @new = ();
    };
    while ($i < @a2 && $j < @b2) {
        if ($a2[$i] eq $b2[$j]) {
            $flush->();
            $i++;
            $j++;
            $start = $i;
        } elsif ($length[$i + 1][$j] >= $length[$i][$j + 1]) {
            push @old, $a2[$i++];
        } else {
            push @new, $b2[$j++];
        }
    }
    push @old, @a2[$i .. $#a2] if $i <= $#a2;
    push @new, @b2[$j .. $#b2] if $j <= $#b2;
    $flush->();

    for my $index (0 .. $#out) {
        my ($at, $old, $new) = @{ $out[$index] };
        next if @$old;
        my $previous_end = $index > 0
            ? $out[$index - 1][0] + scalar(@{ $out[$index - 1][1] }) : 0;
        my $next_at = $index < $#out ? $out[$index + 1][0] : scalar(@a2);
        my @context;
        my $cursor = $at;
        while ($cursor > $previous_end && !grep { /\S/ } @context) {
            $cursor--;
            unshift @context, $a2[$cursor];
        }
        if (!grep { /\S/ } @context) {
            @context = ();
            $cursor = $at;
            while ($cursor < $next_at && !grep { /\S/ } @context) {
                push @context, $a2[$cursor++];
            }
            push @$old, @context;
            push @$new, @context;
        } else {
            unshift @$old, @context;
            unshift @$new, @context;
        }
    }
    return map { [$_->[1], $_->[2]] } @out;
}
