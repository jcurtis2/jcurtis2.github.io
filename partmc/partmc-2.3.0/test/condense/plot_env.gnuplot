# run from inside gnuplot with:
# load "<filename>.gnuplot"
# or from the commandline with:
# gnuplot -persist <filename>.gnuplot

set xlabel "time / s"
set ylabel "temperature / K"
set y2label "relative humidity"

set key center right

set ytics nomirror
set y2tics

plot "ref_condense_0001_env.txt" using 1:2 axes x1y1 with lines title "ref temperature", \
     "out/condense_0001_env.txt" using 1:2 axes x1y1 with points title "temperature", \
     "ref_condense_0001_env.txt" using 1:3 axes x1y2 with lines title "ref relative humidity", \
     "out/condense_0001_env.txt" using 1:3 axes x1y2 with points title "relative humidity"
