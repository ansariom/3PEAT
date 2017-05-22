#!/bin/bash

########################################################################################
# * Copyright (c) 2014 Oregon State University
# * Authors: Taj Morton
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

#if [ $# -ne 3 ]; then
#    echo "Usage: ./3PEAT.sh [ModelName] [sequences.fa] [locations.bed]"
#    echo " * ModelName: One of NP, BR, WP, ALL"
#    echo " * sequences.fa: A FASTA file containing one or more sequences."
#    echo "   Each sequence must contain 10001 nucleotides."
#    echo " * locations.bed: A BED file defining the location of each sequence"
#    echo "   in the genome."
#    exit 1
#fi

#modelName="$1"
modelFilename=$1
seqsFile="$2"
locsFile="$3"
tfbsFile=$4
scoreCutoffsFile=$5
roeFwd=$6
roeRev=$7
nucsScanFromTSS=$8
outputDir=$9

upstream_len=5000
LOGLIK_PATH="LogLikScanner"
#roeFwd="ROEs/$modelName/all.0thresh.seqlocalbgfast250.fwd.halfwidths.new9T5P.table"
#roeRev="ROEs/$modelName/all.0thresh.seqlocalbgfast250.rev.halfwidths.new9T5P.table"
#modelFilename="Models/$modelName.model"

# This varibale indicats the range that you want to consider in your scan
# -nucsScanFromTSS to +nucsScanFromTSS
# 0 -> pnly scan for 1 location which is 0 (tss-mode)
# 2 -> from -2 to 2
#nucsScanFromTSS=100
nucsAfterTSS=5000
let "wig_start_loc = $upstream_len - $nucsScanFromTSS"
wig_step=1
bgWin=250
smoothHalfWin=2

#outputDir=output
seqsBasename="`basename $seqsFile`"
scansOut="$outputDir/$seqsBasename.features"
resultsDir="$outputDir/classification/$seqsBasename"
scriptOutputDir="$outputDir/classifier_stdout/$seqsBasename"
wigDir="$outputDir/scans/$seqsBasename"

function rdatToMM() {
    infile="$1"
    outfile="$2"
    ./Scripts/Rdat_to_sparse_test_noclass.pl "$infile" "$outfile"
}

function generateScans() {
    outLocation=`readlink -f $1`
    #outLocation=`$1`
    thisDir=/nfs0/BPP/Megraw_Lab/mitra/Projects/3PEAT_model/5_3PEAT_scan

    for seqName in `grep '^>' $thisDir/$seqsFile |sed -e 's/^>\([^[:space:]]\+\).*$/\1/'`; do
        cd "$LOGLIK_PATH/classes"
        #java loglikscan.SumScoreVarsSeqLocalBG2FastWVEF_MP "Range 1 -$nucsScanFromTSS $nucsScanFromTSS" $nucsAfterTSS $roeFwd $roeRev $thisDir/$seqsFile $scoreCutoffsFile $tfbsFile $bgWin $outLocation/$seqName.Rdat "$seqName"

        cd "$thisDir"
        #rdatToMM "$outLocation/$seqName.Rdat" "$outLocation/$seqName.mm"
    done
}

function classifyExample() {
    modelFilename="$1"
    featuresFile="$2"
    resultsFile="$3"
    outputFile="$4"

    echo l1_logreg_classify -p "$modelFilename" "$featuresFile" "$resultsFile" 2>&1 | tee "$outputFile"
    l1_logreg_classify -p "$modelFilename" "$featuresFile" "$resultsFile" 2>&1 | tee "$outputFile"
}

function smoothScan() {
    resultsFile="$1"
    outputFile="$2"
    smoothWin="$3"

    ./Scripts/results_to_smoothed_results.pl "$smoothWin" "$resultsFile" "$outputFile"
}

function resultsToWig() {
    resultsFile="$1"
    locsFile="$2"
    wigDir="$3"
    ./Scripts/results_to_wig3.pl $wig_start_loc $wig_step "$resultsFile" "$locsFile"  "$wigDir"
}

mkdir -p $scansOut
generateScans $scansOut

mkdir -p "$resultsDir"
mkdir -p "$outputDir"
mkdir -p "$scriptOutputDir"
mkdir -p "$wigDir"
for peak in $scansOut/*.mm; do
    peak_name=`basename $peak`
    classifyExample "$modelFilename" "$peak" "$resultsDir/$peak_name.result" "$scriptOutputDir/$peak_name.output"

    if [ ! -f "$resultsDir/$peak_name.result" ]; then
        echo "Classification failed."
        echo "Is l1_logreg_classify installed, and can it be called from the current directory?"
        echo "Check $outputDir/$peak_name.output for more error information."
    else
        smoothScan "$resultsDir/$peak_name.result" "$resultsDir/$peak_name.result.smoothed" "$smoothHalfWin" 
        resultsToWig "$resultsDir/$peak_name.result.smoothed" "$locsFile" "$wigDir"
    fi
done

