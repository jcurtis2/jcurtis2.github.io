# run from inside gnuplot with:
# load "<filename>.gnuplot"
# or from the commandline with:
# gnuplot -persist <filename>.gnuplot

set xlabel "time / s"
set ylabel "relative humidity"
set y2label "aerosol water mass concentration / (kg/m^3)"

set key bottom right

set ytics nomirror
set y2tics
set y2range [0:*]

plot "ref_condense_0001_env.txt" using 1:3 axes x1y1 with lines title "ref relative humidity", \
     "out/condense_0001_env.txt" using 1:3 axes x1y1 with points title "relative humidity", \
     "ref_condense_0001_aero_time.txt" using 1:23 axes x1y2 with lines title "ref aerosol water", \
     "out/condense_0001_aero_time.txt" using 1:23 axes x1y2 with points title "aerosol water"
