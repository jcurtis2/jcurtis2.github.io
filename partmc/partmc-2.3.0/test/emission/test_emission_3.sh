#!/bin/bash

# exit on error
set -e
# turn on command echoing
set -v
# make sure that the current directory is the one where this script is
cd ${0%/*}

../../extract_aero_time out/emission_part_0001
../../extract_sectional_aero_time out/emission_exact

../../numeric_diff --by col --rel-tol 0.1 out/emission_exact_aero_time.txt out/emission_part_0001_aero_time.txt
