#!/bin/bash

# exit on error
set -e
# turn on command echoing
set -v
# make sure that the current directory is the one where this script is
cd ${0%/*}

../../extract_aero_size --mass --dmin 1e-7 --dmax 1 --nbin 100 out/sedi_part_0001
../../extract_sectional_aero_size --mass out/sedi_sect

../../numeric_diff --by col --rel-tol 0.7 out/sedi_sect_aero_size_mass.txt out/sedi_part_0001_aero_size_mass.txt
