# run from inside gnuplot with:
# load "<filename>.gnuplot"
# or from the commandline with:
# gnuplot -persist <filename>.gnuplot

set logscale x
set xlabel "diameter / m"
set ylabel "mass concentration / (kg/m^3)"

set key left top

set xrange [1e-9:1e-6]
set yrange [0:1e-7]

plot "out/brownian_part_0001_aero_size_mass.txt" using 1:2 title "particle single t = 0 hours", \
     "out/brownian_part_0001_aero_size_mass.txt" using 1:14 title "particle single t = 12 hours", \
     "out/brownian_part_0001_aero_size_mass.txt" using 1:26 title "particle single t = 24 hours", \
     "out/brownian_part_aero_size_mass_average.txt" using 1:2 with lines title "particle average t = 0 hours", \
     "out/brownian_part_aero_size_mass_average.txt" using 1:14 with lines title "particle average t = 12 hours", \
     "out/brownian_part_aero_size_mass_average.txt" using 1:26 with lines title "particle average t = 24 hours", \
     "out/brownian_sect_aero_size_mass.txt" using 1:2 with lines title "sectional t = 0 hours", \
     "out/brownian_sect_aero_size_mass.txt" using 1:14 with lines title "sectional t = 12 hours", \
     "out/brownian_sect_aero_size_mass.txt" using 1:26 with lines title "sectional t = 24 hours"
