# run from inside gnuplot with:
# load "<filename>.gnuplot"
# or from the commandline with:
# gnuplot -persist <filename>.gnuplot

set logscale
set xlabel "diameter / m"
set ylabel "number concentration / (1/m^3)"

plot "out/bidisperse_part_0001_aero_size_num.txt" using 1:2 with linespoints title "particle initial condition"
