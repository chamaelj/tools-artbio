#!/usr/bin/env python

import sys
import argparse


def Parser():
    the_parser = argparse.ArgumentParser()
    the_parser.add_argument(
        '--input', action="store", type=str, help="input miRBase GFF3 file")
    the_parser.add_argument(
        '--output', action="store", type=str, help="output GFF3 file with converted mature mir coordinates")
    args = the_parser.parse_args()
    return args

GFF3_header= '''
##gff-version 3
##generated by mature_mir_gff_translation.py
#
# Chromosomal coordinates of microRNAs ** relative to the hairpin precursors **
# microRNAs:               miRBase current_version
# genome-build-id:         check http://mirbase.org/
#
# Hairpin precursor sequences have type "miRNA_primary_transcript". 
# Note, these sequences do not represent the full primary transcript, 
# rather a predicted stem-loop portion that includes the precursor 
# miRNA. Mature sequences have type "miRNA".
#

'''

def load_gff_in_dict(gff_input_file):
    '''
    Reads the gff3 file and return a dictionary of dictionaries
    with keys equal to standard gff3 fields (9)
    Note that the key of the primary dictionary is the ID
    '''
    gff_dict = {}
    for line in open(gff_input_file, "r"):
        if line[0]=="#":
            continue
        gff_fields=line[:-1].split("\t")
        ID=gff_fields[8].split("ID=")[1].split(";")[0]
        gff_dict[ID] = {}
        gff_dict[ID]["seqid"]=gff_fields[0]
        gff_dict[ID]["source"]=gff_fields[1]
        gff_dict[ID]["type"]=gff_fields[2]
        gff_dict[ID]["start"]=gff_fields[3]
        gff_dict[ID]["end"]=gff_fields[4]
        gff_dict[ID]["score"]=gff_fields[5]
        gff_dict[ID]["strand"]=gff_fields[6]
        gff_dict[ID]["phase"]=gff_fields[7]
        gff_dict[ID]["attributes"]=gff_fields[8]
    return gff_dict
    

def genome_to_mir_gff(gff_dict, output):
    '''
    Converts seqid field from chromosome to item Name
    Then converts coordinates relative to "miRNA_primary_transcript"
    Note that GFF files are 1-based coordinates
    '''
    for key in gff_dict:
        name=gff_dict[key]["attributes"].split("Name=")[1].split(";")[0]
        gff_dict[key]["seqid"]=name
        if "Derives_from=" in gff_dict[key]["attributes"]:
            parent_ID=gff_dict[key]["attributes"].split("Derives_from=")[1].split(";")[0]
            gff_dict[key]["start"]=str(int(gff_dict[key]["start"]) - int(gff_dict[parent_ID]["start"]) + 1)
            gff_dict[key]["end"]=str(int(gff_dict[key]["end"]) - int(gff_dict[parent_ID]["start"]) + 1)
    hairpins={}
    matures={}
    for key in gff_dict:  ## treats miRNA_primary_transcript coordinates in a second loop to avoid errors in conversion
        if gff_dict[key]["type"]=="miRNA_primary_transcript":
            gff_dict[key]["end"]=str(int(gff_dict[key]["end"]) - int(gff_dict[key]["start"]) + 1)
            gff_dict[key]["start"]="1"
            # now, do a dict[ID]=Name but only for miRNA_primary_transcript
            hairpins[key]=gff_dict[key]["attributes"].split("Name=")[1].split(";")[0]
        else:
            matures[key]=gff_dict[key]["attributes"].split("Name=")[1].split(";")[0]
    with open(output, "w") as output:
        output.write(GFF3_header)
        for ID in sorted(hairpins, key=hairpins.get):
            output.write("\t".join([gff_dict[ID]["seqid"], gff_dict[ID]["source"],
                gff_dict[ID]["type"], gff_dict[ID]["start"], gff_dict[ID]["end"],
                gff_dict[ID]["score"], gff_dict[ID]["strand"], gff_dict[ID]["phase"],
                gff_dict[ID]["attributes"]]))
            output.write("\n")
            for id in sorted(matures, key=matures.get, reverse=True):
                if ID in gff_dict[id]["attributes"]:
                    output.write("\t".join([gff_dict[id]["seqid"], gff_dict[id]["source"],
                        gff_dict[id]["type"], gff_dict[id]["start"], gff_dict[id]["end"],
                        gff_dict[id]["score"], gff_dict[id]["strand"],
                        gff_dict[id]["phase"], gff_dict[id]["attributes"]]))
                    output.write("\n")


def main(infile, outfile):
    gff_dict = load_gff_in_dict(infile)
    genome_to_mir_gff(gff_dict, outfile)


if __name__ == "__main__":
    args = Parser()
    main(args.input, args.output)