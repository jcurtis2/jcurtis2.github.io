# run from inside gnuplot with:
# load "<filename>.gnuplot"
# or from the commandline with:
# gnuplot -persist <filename>.gnuplot

set logscale
set xlabel "diameter / m"
set ylabel "number concentration / (1/m^3)"

set xrange [1e-9:1e-6]
set yrange [1e7:1e11]

plot "out/brownian_part_0001_aero_size_num.txt" using 1:2 title "particle single t = 0 hours", \
     "out/brownian_part_0001_aero_size_num.txt" using 1:14 title "particle single t = 12 hours", \
     "out/brownian_part_0001_aero_size_num.txt" using 1:26 title "particle single t = 24 hours", \
     "out/brownian_part_aero_size_num_average.txt" using 1:2 with lines title "particle average t = 0 hours", \
     "out/brownian_part_aero_size_num_average.txt" using 1:14 with lines title "particle average t = 12 hours", \
     "out/brownian_part_aero_size_num_average.txt" using 1:26 with lines title "particle average t = 24 hours", \
     "out/brownian_sect_aero_size_num.txt" using 1:2 with lines title "sectional t = 0 hours", \
     "out/brownian_sect_aero_size_num.txt" using 1:14 with lines title "sectional t = 12 hours", \
     "out/brownian_sect_aero_size_num.txt" using 1:26 with lines title "sectional t = 24 hours"
