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

$testFile = shift; # Rdat neg examples file
$outFile = shift; # Output file in sparse format

$ncols = 0;
$nrows = 0;
$nnz = 0;

open(OUT, ">$outFile.matrix");

open(FILE, $testFile) || die "Can't open $testFile";
    
$hdr = <FILE>;
$hdr =~ s/^\s+//; # remove leading whitespace
@hdrarr = split(/\t/, $hdr);
if ($filei == 0) {
    $ncols = scalar(@hdrarr);
}

$linecnt = 0;
while (<FILE>) {
    $linecnt++;
    $line = $_;
    chomp($line);
    
    @linearr = split(/\t/, $line);
    $label = shift(@linearr);
    $num = scalar(@linearr);
    if ($num != $ncols) { die("Died at line $linecnt of $testFile: line doesn't have $ncols columns."); }
    $nrows++;
    for $i (0 .. $#linearr) {
	$el = $linearr[$i];
	$thisrow = $nrows;
	$thiscol = $i + 1;
	unless ($el == 0) {
	    print OUT "$thisrow $thiscol $el\n";
	    $nnz++;
	}
    }
    
}
close(FILE);

close(OUT);

open(OUT, ">$outFile.header");
print OUT "\%\%MatrixMarket matrix coordinate real general\n";
print OUT "$nrows $ncols $nnz\n";
close(OUT);

system("cat $outFile.header $outFile.matrix > $outFile");
system("rm $outFile.header $outFile.matrix");
