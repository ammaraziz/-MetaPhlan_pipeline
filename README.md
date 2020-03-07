##  MetaPhlan pipeline for automated submission of jobs to PBS schedular 

This pipeline will run MetaPhlan and then StrainPhlan to detect species specific markers in sequencing data. 

### Usage

To run the script, simple call:

    ./stp.sh 

`.fastq` files are automatically detected and ran through the pipeline. 

When generating the marker files for Strainphlan, metaphlan detects Bm and Bp when the samples only contain Bp.

The workaround for this is to recode all Bm samples as actually Bp. This can be done by using the pickle package in python and readingi n the .pkl file. 

Code is found in ~/candidature/aim2/metaphlan/modify_pkl.py

Once this is done, the new .pkl file needs to be stored in it's own folder in metaphlan. 
