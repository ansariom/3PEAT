#!/usr/bin/perl

########################################################################################
# * Copyright (c) 2014 Oregon State University
# * Authors: Molly Megraw
# *
# * This program is distributed under the terms listed in the
# * LICENSE file included with this software. 
# *
# * IN NO EVENT SHALL OREGON STATE UNIVERSITY BE LIABLE TO ANY PARTY FOR DIRECT,
# * INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES, INCLUDING LOST PROFITS,
# * ARISING OUT OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF OREGON
# * STATE UNIVERSITY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE. OREGON STATE
# * UNIVERSITY SPECIFICALLY DISCLAIMS ANY WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
# * THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# * AND ANY STATUTORY WARRANTY OF NON-INFRINGEMENT. THE SOFTWARE PROVIDED HEREUNDER
# * IS ON AN "AS IS" BASIS, AND OREGON STATE UNIVERSITY HAS NO OBLIGATIONS TO
# * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS. 
# *
# * Contact: megrawm@science.oregonstate.edu
########################################################################################

$hw = shift; # half-window size over which to smooth
$res = shift; # results file
$outfile = shift; # output file

open(OUT, ">$outfile");
open(IN, "$res") || die "Can't open $res";
# read through header
$line = <IN>;
while ($line =~ /^\%/) {
    print OUT $line;
    $line = <IN>;
}
print OUT $line;
# read value vector
@arr = ();
for $i ( 0 .. 2*$hw) {
    $line = <IN>;
    chomp($line);
    $line =~ s/^\s+//; # remove leading whitespace
    $arr[$i] = $line;
    if ($i < $hw) { print OUT " $arr[$i]\n"; }
}
@sorted = sort {$a <=> $b} @arr;
$median = $sorted[($#sorted / 2)];
print OUT " $median\n";

while (<IN>) {
    $line = $_;
    chomp($line);
    $line =~ s/^\s+//; # remove leading whitespace
    shift(@arr);
    push(@arr, $line);
    @sorted = sort {$a <=> $b} @arr;
    $median = $sorted[($#sorted / 2)];
    print OUT " $median\n";
}
for $i ( ($#arr - $hw + 1) .. $#arr) {
    print OUT " $arr[$i]\n";
}

close(IN);
close(OUT);
