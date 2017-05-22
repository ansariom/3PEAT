#!/usr/bin/perl

########################################################################################
# * Copyright (c) 2014 Oregon State University
# * Authors: Molly Megraw, Taj Morton
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

# Reads seq locations from bed file rather than seqdef file.
# Takes seqlabel from file name

$shift = shift;
$step = shift;
$inFile = shift; # input directory
$bedFile = shift; # bed file
$outdir = shift; # directory for output files

@dirparts = split(/\//, $inFile);
$fname = pop(@dirparts);
@extparts = split(/\./, $fname);
$seqlab = $extparts[0];

$wigFile = "$seqlab.wig"; # output wig file

# process bed file
%seqhash = ();
open(IN, $bedFile) || die "Can't open $bedFile";
while (<IN>) {
    $line = $_;
    chomp($line);
    
    @arr = split(/\t/, $line);

    $id = $arr[3];
    $chr = $arr[0];
    $strand = $arr[5];
    $start = $arr[1];

    $seqhash{$id}{'chr'} = $chr;
    $seqhash{$id}{'strand'} = $strand;
    $seqhash{$id}{'start'} = $start;
}
close(IN);

# process results file
open(IN, "$inFile") || die "Can't open $inFile";
    
# read through header
while (<IN> =~ /^\%/) {
}

# read value vector
@arr = ();
$cnt = 0;
while (<IN>) {
    $line = $_;
    chomp($line);
    $line =~ s/^\s+//; # remove leading whitespace
    $arr[$cnt] = $line;
    $cnt++;
}

close(IN);

$length = $#arr;

# print wig file

$header="track type=wiggle_0 name=\"3PEAT\" description=\"TSS Probability\" visibility=full viewLimits=0.0:1.0 autoScale=off maxHeightPixels=200:190:100 color=255,0,0 yLineMark=0.5 yLineOnOff=on";

print "$outdir/$wigFile";
open(OUT, ">$outdir/$wigFile");
if (exists($seqhash{$seqlab})) {
    $chr = $seqhash{$seqlab}{'chr'};
    $strand = $seqhash{$seqlab}{'strand'};
    $start = $seqhash{$seqlab}{'start'} + $shift;
    $end = $start + $length;
    $browserpos = "browser position $chr:$start-$end";

    print OUT "$header\n";

    print OUT "fixedStep chrom=$chr start=$start step=$step\n";

    if ($strand eq "+") {
	for ($i=0; $i<=$#arr; $i++) {
	    printf OUT "%.15g\n", $arr[$i];
	}
    }
    else {
	for ($i=$#arr; $i>=0; $i--) {
	    printf OUT "%.15g\n", $arr[$i];
	}
    }
}
close(OUT);

