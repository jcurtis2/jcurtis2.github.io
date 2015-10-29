# run from inside gnuplot with:
# load "<filename>.gnuplot"
# or from the commandline with:
# gnuplot -persist <filename>.gnuplot

set xlabel "time / h"
set ylabel "number concentration / (1/m^3)"
set y2label "mass concentration / (kg/m^3)"

set ytics nomirror
set y2tics

set yrange [0:*]
set y2range [0:*]

set key right center

plot "out/sect_aero_time.txt" using ($1/3600):2 axes x1y1 with lines linewidth 5 title "num sect", \
     "out/parallel_mix_0001_0001_aero_time.txt" using ($1/3600):2 axes x1y1 with lines notitle, \
     "out/parallel_mix_0001_0002_aero_time.txt" using ($1/3600):2 axes x1y1 with lines notitle, \
     "out/parallel_mix_0001_0003_aero_time.txt" using ($1/3600):2 axes x1y1 with lines notitle, \
     "out/parallel_mix_0001_0004_aero_time.txt" using ($1/3600):2 axes x1y1 with lines notitle, \
     "out/sect_aero_time.txt" using ($1/3600):3 axes x1y2 with lines linewidth 5 title "mass sect", \
     "out/parallel_mix_0001_0001_aero_time.txt" using ($1/3600):3 axes x1y2 with lines notitle, \
     "out/parallel_mix_0001_0002_aero_time.txt" using ($1/3600):3 axes x1y2 with lines notitle, \
     "out/parallel_mix_0001_0003_aero_time.txt" using ($1/3600):3 axes x1y2 with lines notitle, \
     "out/parallel_mix_0001_0004_aero_time.txt" using ($1/3600):3 axes x1y2 with lines notitle
