#!/bin/bash

name_ref=train_ath.LEAF_test_OS.LEAF_peatPWMs
db=data/$name_ref
peat_pwms=$db/PEAT_pwms.txt
peat_zero_cutoffs=$db/PEAT_zero_pwm.txt

input_fasta=$db/in_fasta.fa
input_loc_bed=$db/in_fasta.bed

model_file=$db/model.model
roe_fwd_tbl=$db/roe_fwd.table
roe_rev_tbl=$db/roe_rev.table

scan_region_length=10 # half width of scan regin centered at TSS (zero)
upstream_len=5000
downstream_len=5000
loglik_path=/nfs0/BPP/Megraw_Lab/mitra/software/LogLikScanner
working_dir=/nfs0/BPP/Megraw_Lab/mitra/Projects/3PEAT_model/exe
scripts_dir=/nfs0/BPP/Megraw_Lab/mitra/Projects/3PEAT_model/exe/software/scripts
l1logreg_path=/nfs0/BPP/Megraw_Lab/mitra/software/3PEAT_Model/l1_logreg-0.8.2-i686-pc-linux-gnu

### Paralle processing for many FASTA seqs
###########################################

nseqs=1000  # number of seqs in each inputfile for parallel execution
let "nlocs=$nseqs/2"

outdir=output/$name_ref

if [ ! -d $outdir ];then
        mkdir -p $outdir
fi

seqs_outdir=$outdir/Sequences/$test_dataset
if [ ! -d $seqs_outdir ]; then
	mkdir -p $seqs_outdir
fi
seq_prefix=$seqs_outdir/seq.
loc_prefix=$seqs_outdir/loc.

split -d -l $nseqs $input_fasta $seq_prefix
split -d -l $nlocs $input_loc_bed $loc_prefix


count=1
ncpu=40
for seqfile in `ls $seqs_outdir/seq*`; do
	if [ $count -lt $ncpu ]; then
		filename=$(basename "$seqfile")
		i="${filename##*.}"
		bedfile=$loc_prefix"$i"
		echo $bedfile
		echo $seqfile
 		software/3PEAT_Scan.sh $model_file $seqfile $bedfile $peat_pwms $peat_zero_cutoffs $roe_fwd_tbl $roe_rev_tbl $scan_region_length $upstream_len $outdir $loglik_path $working_dir $scripts_dir $l1logreg_path $downstream_len &
		let "count=count+1"
	else
		echo "wait for batch to complete! (submitted = $count)"
		wait
		count=1
	fi
done
wait

echo "All finished!!!"
final_outdir=$outdir/all_scans
if [ ! -d $final_outdir ]; then
	mkdir $final_outdir
fi
cp $outdir/scans/seq.*/* $final_outdir

## Cleaning up
rm -f -r $outdir/scans/



