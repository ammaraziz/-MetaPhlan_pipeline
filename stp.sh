#!/bin/bash
#PBS -S /bin/sh
#PBS -m n
#PBS -j oe
#PBS -l ncpus=1
#PBS -l walltime=96:00:00
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

cat $DIR/ascii.txt
echo -e "\n"
sleep 1

#software vars
MTP2=/home/aaziz/bin/metaphlan2/metaphlan2.py
S2M=/home/aaziz/bin/metaphlan2/strainphlan_src/sample2markers.py
STP=/home/aaziz/bin/metaphlan2/strainphlan.py
INDEX="v21_m200"

cpus=2

echo "Detecting samples"
sequences_tmp=($(find $PWD/*_1_sequence.fastq.gz -printf "%f "))
sequences=("${sequences_tmp[@]/_[12]_sequence.fastq.gz/}")
n=${#sequences[@]}
echo "Found the following: $sequences"

#creates dependancy function 
depend_id() {
  qsub_ids=`cat qsub_ids.txt | cut -f2 | sed -e 's/^/:/' | tr -d '\n'`
  depend="-W depend=afterok${qsub_ids}"
  echo $depend
}

#make directories
if [ ! -d markerFiles ]; then
	mkdir markerFiles
fi

if [ ! -d logs ]; then
	mkdir logs
fi

if [ -s qsub_ids.txt ]; then
	rm qsub_ids.txt
fi

if [ ! -d bt2_files ]; then
	mkdir bt2_files
fi

if [ ! -d sam ]; then
	mkdir sam
fi
if [ ! -d trees ]; then
	mkdir trees
fi

#####################################
############# MetaPhlan2 ############
#####################################

# Run metaphlan2 to generate sam file
for (( i=0; i<n; i++ )); do
	if [ ! -s ${sequences[$i]}.sam ]; then
		echo -e "qsub: ${sequences[$i]} to Metaphlan2......................."
		qsub_id_MTP=$(qsub -N ${sequences[$i]}_Meta -j oe -l ncpus=$cpus,walltime=96:00:00 -v command="$MTP2 --input_type fastq "${sequences[$i]}_1_sequence.fastq.gz,${sequences[$i]}_2_sequence.fastq.gz" ${sequences[$i]}.txt --index $INDEX --bowtie2out bt2_files/${sequences[$i]}_bowtie2.txt --samout sam/${sequences[$i]}.sam --nproc $cpus" $DIR/Header.pbs);
    # Dependancies
		echo -e "meta_${sequences[$i]}\t$qsub_id_MTP" > qsub_ids.txt;
		echo -e "meta_${sequences[$i]}\t$qsub_id_MTP" >> all_IDs.txt;
		if [ -s qsub_ids.txt ]; then
			depend=$(depend_id);
		fi
    fi

# Run sample2markers.py to generate marker files 
	if [ ! -s /markerFiles/${sequences[$i]}.markers ]; then
		echo -e "qsub: ${sequences[$i]} to sample2markers.......................... \n"
	    qsub_S2M=$(qsub -N ${sequences[$i]}_S2M -j oe -l ncpus=$cpus,walltime=96:00:00 $depend -v command="$S2M --verbose --samtools_exe /usr/local/samtools-0.1.19/samtools --bcftools /usr/local/samtools-0.1.19/bcftools/bcftools --ifn_samples sam/${sequences[$i]}.sam --input_type sam --nprocs $cpus --output_dir $PWD/markerFiles/" $DIR/Header.pbs);																									   
	# Dependancies
	    echo -e "S2M_${sequences[$i]}\t$qsub_S2M" >> all_IDs.txt;
    fi
done

######################################
############# StrainPhlan ############
######################################

echo -e "qsub: StrainPhlan.................................. \n"
qsub_all=`cat all_IDs.txt | cut -f2 | sed -e 's/^/:/' | tr -d '\n'`
dependall="-W depend=afterok${qsub_all}"
qsub_STPc=$(qsub -N STP1 -j oe -l ncpus=$cpus,walltime=96:00:00 $dependall -v command="$STP --ifn_samples $PWD/markerFiles/*.markers --index $INDEX --nprocs_main $cpus --output_dir . --print_clades_only > clades.txt" $DIR/Header.pbs);




#extract markers from db, assumes it's in db_markers
#extract_markers.py --mpa_pkl $picke_db --ifn_markers  db_markers/all_markers.fasta --clade s__Bacteroides_caccae --ofn_markers db_markers/s__Bacteroides_caccae.markers.fasta

#generate alignment trees
#qsub_id=$(qsub -N STP2 -j oe -l ncpus=$cpus,walltime=96:00:00 -W depend=afterok:$qsub_STPc1 -v command="module load python/2.7.13 && $STP --keep_alignment_files --ifn_samples $PWD/markerFiles/*.markers --ifn_markers db_markers/s__Burkholderia_pseudomallei.fasta --mpa_pkl $picke_db --relaxed_parameters3 --ifn_ref_genomes ../MSHR1153.fna --output_dir trees/ --clades s__Burkholderia_pseudomallei" $DIR/Header.pbs);

#need to load: software/R_3.5.1, software/nullarbor for the below lines
#visualise using ggtree, need a slew of packages
#~/bin/metaphlan2/scripts/strainphlan_ggtree.R RAxML_bestTree.s__Burkholderia_pseudomallei.tree meta_data.txt s__Burkholderia_pseudomallei.fasta strainphlan_tree_1.png strainphlan_tree_2.png
 #PCA plot
#module load software/nullarbor
#distmat -sequence s__Burkholderia_pseudomallei.fasta -nucmethod 2 -outfile test.distmat
#~/bin/metaphlan2/scripts/strainphlan_ordination.R s__burkholderia_pseudomallei.distmat meta_data.txt strainphlan_tree_ord.png

exit 0
