#!/bin/sh

# exit on error
set -e
# turn on command echoing
set -v

mkdir -p out

../../build/partmc urban_plume2_with_coag.spec
../../build/partmc urban_plume2_no_coag.spec

# Now run ./process.sh to process the data
