cmake_minimum_required(VERSION 2.6.4)
# Require 2.6.4 due to -I/usr/include behavior:
# http://www.cmake.org/Bug/view.php?id=8598
# http://gcc.gnu.org/bugzilla/show_bug.cgi?id=35707
# http://www.cmake.org/Bug/view.php?id=8408
project(PARTMC Fortran C)

set(PACKAGE_BUGREPORT "mwest@illinois.edu")
set(PACKAGE_NAME "PartMC")
set(PACKAGE_STRING "PartMC 2.3.0")
set(PACKAGE_TARNAME "partmc")
set(PACKAGE_VERSION "2.3.0")

######################################################################
# options

option(ENABLE_GSL "Enable GSL library for random number generation" OFF)
option(ENABLE_MOSAIC "Enable MOSAIC chemistry support" OFF)
option(ENABLE_MPI "Enable MPI parallel support" OFF)
option(ENABLE_SUNDIALS "Enable SUNDIALS solver for condensation support" OFF)
option(ENABLE_C_SORT "Enable C sorting routines" OFF)

######################################################################
# CPack

set(CPACK_SOURCE_GENERATOR "TGZ")
SET(CPACK_SOURCE_PACKAGE_FILE_NAME "${PACKAGE_TARNAME}-${PACKAGE_VERSION}")
set(CPACK_SOURCE_IGNORE_FILES "${CPACK_SOURCE_IGNORE_FILES};/.*~$;/[.].*/;/build/;/figures/;/scenarios/[^12].*/;/doc/condensation/;/doc/deposition/;/doc/ship_track/;/old/;/tool/;/TODO")

include(CPack)

######################################################################
# NetCDF

find_path(NETCDF_INCLUDE_DIR netcdf.mod NETCDF.mod
  DOC "NetCDF include directory (must contain netcdf.mod)"
  PATHS
  $ENV{NETCDF_HOME}/include
  /usr/lib/gfortran/modules
  /usr/lib64/gfortran/modules
  /opt/local/include)
find_library(NETCDF_C_LIB netcdf
  DOC "NetCDF C library"
  PATHS $ENV{NETCDF_HOME}/lib /opt/local/lib)
find_library(NETCDF_FORTRAN_LIB netcdff
  DOC "NetCDF Fortran library"
  PATHS $ENV{NETCDF_HOME}/lib /opt/local/lib)
set(NETCDF_LIBS ${NETCDF_C_LIB})
if(NETCDF_FORTRAN_LIB)
  set(NETCDF_LIBS ${NETCDF_LIBS} ${NETCDF_FORTRAN_LIB})
endif()
include_directories(${NETCDF_INCLUDE_DIR})

######################################################################
# GSL

if(ENABLE_GSL)
  find_path(GSL_INCLUDE_DIR gsl/gsl_math.h
    DOC "GSL include directory (must have gsl/ subdir)"
    PATHS $ENV{GSL_HOME}/include /opt/local/include)
  find_library(GSL_LIB gsl
    DOC "GSL library"
    PATHS $ENV{GSL_HOME}/lib /opt/local/lib)
  find_library(GSL_CBLAS_LIB gslcblas
    DOC "GSL CBLAS library"
    PATHS $ENV{GSL_HOME}/lib /opt/local/lib)
  find_library(M_LIB m
    DOC "standard C math library")
  set(GSL_SRC src/rand_gsl.c)
  set(GSL_LIBS ${GSL_LIB} ${GSL_CBLAS_LIB} ${M_LIB})
  include_directories(${GSL_INCLUDE_DIR})
  add_definitions(-DPMC_USE_GSL)
endif()

######################################################################
# C sort

if(ENABLE_C_SORT)
  set(C_SORT_SRC src/sort.c)
  add_definitions(-DPMC_USE_C_SORT)
endif()

######################################################################
# MOSAIC

if(ENABLE_MOSAIC)
  find_path(MOSAIC_INCLUDE_DIR module_data_mosaic_main.mod
    DOC "MOSAIC include directory"
    PATHS $ENV{MOSAIC_HOME}/datamodules $ENV{MOSAIC_HOME}/include)
  find_library(MOSAIC_LIB mosaic
    DOC "MOSAIC library"
    PATHS $ENV{MOSAIC_HOME} $ENV{MOSAIC_HOME}/lib)
  include_directories(${MOSAIC_INCLUDE_DIR})
  add_definitions(-DPMC_USE_MOSAIC)
endif()

######################################################################
# MPI

if(ENABLE_MPI)
  add_definitions(-DPMC_USE_MPI)
endif()

######################################################################
# SUNDIALS

if(ENABLE_SUNDIALS)
  find_path(SUNDIALS_INCLUDE_DIR cvode/cvode.h
    DOC "SUNDIALS include directory (must have cvode/, sundials/, nvector/ subdirs)"
    PATHS $ENV{SUNDIALS_HOME}/include /opt/local/include)
  find_library(SUNDIALS_NVECSERIAL_LIB sundials_nvecserial
    DOC "SUNDIALS serial vector library"
    PATHS $ENV{SUNDIALS_HOME}/lib /opt/local/lib)
  find_library(SUNDIALS_CVODE_LIB sundials_cvode
    DOC "SUNDIALS CVODE library"
    PATHS $ENV{SUNDIALS_HOME}/lib /opt/local/lib)
  set(SUNDIALS_LIBS ${SUNDIALS_NVECSERIAL_LIB} ${SUNDIALS_CVODE_LIB})
  set(SUNDIALS_SRC src/condense_solver.c)
  include_directories(${SUNDIALS_INCLUDE_DIR})
  add_definitions(-DPMC_USE_SUNDIALS)
endif()

######################################################################
# tests

enable_testing()
add_custom_target(copy_test ALL ${CMAKE_COMMAND} -E copy_directory ${CMAKE_SOURCE_DIR}/test ${CMAKE_BINARY_DIR}/test_run)
set_property(DIRECTORY PROPERTY ADDITIONAL_MAKE_CLEAN_FILES test_run)

add_test(test_additive_1 ${CMAKE_BINARY_DIR}/test_run/additive/test_additive_1.sh)
add_test(test_additive_2 ${CMAKE_BINARY_DIR}/test_run/additive/test_additive_2.sh)
set_tests_properties(test_additive_2 PROPERTIES DEPENDS test_additive_1)

add_test(test_average_01 ${CMAKE_BINARY_DIR}/test_run/average/test_average_01.sh)
add_test(test_average_02 ${CMAKE_BINARY_DIR}/test_run/average/test_average_02.sh)
set_tests_properties(test_average_02 PROPERTIES DEPENDS test_average_01)
add_test(test_average_03 ${CMAKE_BINARY_DIR}/test_run/average/test_average_03.sh)
set_tests_properties(test_average_03 PROPERTIES DEPENDS test_average_02)
add_test(test_average_04 ${CMAKE_BINARY_DIR}/test_run/average/test_average_04.sh)
set_tests_properties(test_average_04 PROPERTIES DEPENDS test_average_03)
add_test(test_average_05 ${CMAKE_BINARY_DIR}/test_run/average/test_average_05.sh)
set_tests_properties(test_average_05 PROPERTIES DEPENDS test_average_04)
add_test(test_average_06 ${CMAKE_BINARY_DIR}/test_run/average/test_average_06.sh)
set_tests_properties(test_average_06 PROPERTIES DEPENDS test_average_05)
add_test(test_average_07 ${CMAKE_BINARY_DIR}/test_run/average/test_average_07.sh)
set_tests_properties(test_average_07 PROPERTIES DEPENDS test_average_06)
add_test(test_average_08 ${CMAKE_BINARY_DIR}/test_run/average/test_average_08.sh)
set_tests_properties(test_average_08 PROPERTIES DEPENDS test_average_07)
add_test(test_average_09 ${CMAKE_BINARY_DIR}/test_run/average/test_average_09.sh)
set_tests_properties(test_average_09 PROPERTIES DEPENDS test_average_08)
add_test(test_average_10 ${CMAKE_BINARY_DIR}/test_run/average/test_average_10.sh)
set_tests_properties(test_average_10 PROPERTIES DEPENDS test_average_09)
add_test(test_average_11 ${CMAKE_BINARY_DIR}/test_run/average/test_average_11.sh)
set_tests_properties(test_average_11 PROPERTIES DEPENDS test_average_10)
add_test(test_average_12 ${CMAKE_BINARY_DIR}/test_run/average/test_average_12.sh)
set_tests_properties(test_average_12 PROPERTIES DEPENDS test_average_11)
add_test(test_average_13 ${CMAKE_BINARY_DIR}/test_run/average/test_average_13.sh)
set_tests_properties(test_average_13 PROPERTIES DEPENDS test_average_12)
add_test(test_average_14 ${CMAKE_BINARY_DIR}/test_run/average/test_average_14.sh)
set_tests_properties(test_average_14 PROPERTIES DEPENDS test_average_13)
add_test(test_average_15 ${CMAKE_BINARY_DIR}/test_run/average/test_average_15.sh)
set_tests_properties(test_average_15 PROPERTIES DEPENDS test_average_14)
add_test(test_average_16 ${CMAKE_BINARY_DIR}/test_run/average/test_average_16.sh)
set_tests_properties(test_average_16 PROPERTIES DEPENDS test_average_15)
add_test(test_average_17 ${CMAKE_BINARY_DIR}/test_run/average/test_average_17.sh)
set_tests_properties(test_average_17 PROPERTIES DEPENDS test_average_16)
add_test(test_average_18 ${CMAKE_BINARY_DIR}/test_run/average/test_average_18.sh)
set_tests_properties(test_average_18 PROPERTIES DEPENDS test_average_17)
add_test(test_average_19 ${CMAKE_BINARY_DIR}/test_run/average/test_average_19.sh)
set_tests_properties(test_average_19 PROPERTIES DEPENDS test_average_18)
add_test(test_average_20 ${CMAKE_BINARY_DIR}/test_run/average/test_average_20.sh)
set_tests_properties(test_average_20 PROPERTIES DEPENDS test_average_19)

add_test(test_bidisperse_1 ${CMAKE_BINARY_DIR}/test_run/bidisperse/test_bidisperse_1.sh)

add_test(test_brownian_1 ${CMAKE_BINARY_DIR}/test_run/brownian/test_brownian_1.sh)
add_test(test_brownian_2 ${CMAKE_BINARY_DIR}/test_run/brownian/test_brownian_2.sh)
set_tests_properties(test_brownian_2 PROPERTIES DEPENDS test_brownian_1)
add_test(test_brownian_3 ${CMAKE_BINARY_DIR}/test_run/brownian/test_brownian_3.sh)
set_tests_properties(test_brownian_3 PROPERTIES DEPENDS test_brownian_2)
add_test(test_brownian_4 ${CMAKE_BINARY_DIR}/test_run/brownian/test_brownian_4.sh)
set_tests_properties(test_brownian_4 PROPERTIES DEPENDS test_brownian_3)

if(ENABLE_SUNDIALS)
  add_test(test_condense_1 ${CMAKE_BINARY_DIR}/test_run/condense/test_condense_1.sh)
  add_test(test_condense_2 ${CMAKE_BINARY_DIR}/test_run/condense/test_condense_2.sh)
  set_tests_properties(test_condense_2 PROPERTIES DEPENDS test_condense_1)
endif()

add_test(test_emission_1 ${CMAKE_BINARY_DIR}/test_run/emission/test_emission_1.sh)
add_test(test_emission_2 ${CMAKE_BINARY_DIR}/test_run/emission/test_emission_2.sh)
set_tests_properties(test_emission_2 PROPERTIES DEPENDS test_emission_1)
add_test(test_emission_3 ${CMAKE_BINARY_DIR}/test_run/emission/test_emission_3.sh)
set_tests_properties(test_emission_3 PROPERTIES DEPENDS test_emission_2)

add_test(test_loss_1 ${CMAKE_BINARY_DIR}/test_run/loss/test_loss_1.sh)
add_test(test_loss_2 ${CMAKE_BINARY_DIR}/test_run/loss/test_loss_2.sh)
set_tests_properties(test_loss_2 PROPERTIES DEPENDS test_loss_1)
add_test(test_loss_3 ${CMAKE_BINARY_DIR}/test_run/loss/test_loss_3.sh)
add_test(test_loss_4 ${CMAKE_BINARY_DIR}/test_run/loss/test_loss_4.sh)
set_tests_properties(test_loss_4 PROPERTIES DEPENDS test_loss_3)

add_test(test_nucleate_1 ${CMAKE_BINARY_DIR}/test_run/nucleate/test_nucleate_1.sh)
add_test(test_nucleate_2 ${CMAKE_BINARY_DIR}/test_run/nucleate/test_nucleate_2.sh)
set_tests_properties(test_nucleate_2 PROPERTIES DEPENDS test_nucleate_1)

if(ENABLE_MOSAIC)
  add_test(test_mosaic_1 ${CMAKE_BINARY_DIR}/test_run/mosaic/test_mosaic_1.sh)
  add_test(test_mosaic_2 ${CMAKE_BINARY_DIR}/test_run/mosaic/test_mosaic_2.sh)
  set_tests_properties(test_mosaic_2 PROPERTIES DEPENDS test_mosaic_1)
  add_test(test_mosaic_3 ${CMAKE_BINARY_DIR}/test_run/mosaic/test_mosaic_3.sh)
  set_tests_properties(test_mosaic_3 PROPERTIES DEPENDS test_mosaic_2)
  add_test(test_mosaic_4 ${CMAKE_BINARY_DIR}/test_run/mosaic/test_mosaic_4.sh)
  set_tests_properties(test_mosaic_4 PROPERTIES DEPENDS test_mosaic_3)
  add_test(test_mosaic_5 ${CMAKE_BINARY_DIR}/test_run/mosaic/test_mosaic_5.sh)
  set_tests_properties(test_mosaic_5 PROPERTIES DEPENDS test_mosaic_4)
  add_test(test_mosaic_6 ${CMAKE_BINARY_DIR}/test_run/mosaic/test_mosaic_6.sh)
  set_tests_properties(test_mosaic_6 PROPERTIES DEPENDS test_mosaic_5)
endif()

if(ENABLE_MPI)
  add_test(test_parallel_1 ${CMAKE_BINARY_DIR}/test_run/parallel/test_parallel_1.sh)
  #add_test(test_parallel_2 ${CMAKE_BINARY_DIR}/test_run/parallel/test_parallel_2.sh)
  #set_tests_properties(test_parallel_2 PROPERTIES DEPENDS test_parallel_1)
  add_test(test_parallel_3 ${CMAKE_BINARY_DIR}/test_run/parallel/test_parallel_3.sh)
  set_tests_properties(test_parallel_3 PROPERTIES DEPENDS test_parallel_1)
  #set_tests_properties(test_parallel_3 PROPERTIES DEPENDS test_parallel_2)
  #add_test(test_parallel_4 ${CMAKE_BINARY_DIR}/test_run/parallel/test_parallel_4.sh)
  #set_tests_properties(test_parallel_4 PROPERTIES DEPENDS test_parallel_3)
endif()

add_test(test_rand_1 ${CMAKE_BINARY_DIR}/test_run/rand/test_rand_1.sh)
add_test(test_rand_2 ${CMAKE_BINARY_DIR}/test_run/rand/test_rand_2.sh)
set_tests_properties(test_rand_2 PROPERTIES DEPENDS test_rand_1)
add_test(test_rand_3 ${CMAKE_BINARY_DIR}/test_run/rand/test_rand_3.sh)
set_tests_properties(test_rand_3 PROPERTIES DEPENDS test_rand_2)
add_test(test_rand_4 ${CMAKE_BINARY_DIR}/test_run/rand/test_rand_4.sh)
set_tests_properties(test_rand_4 PROPERTIES DEPENDS test_rand_3)
add_test(test_rand_5 ${CMAKE_BINARY_DIR}/test_run/rand/test_rand_5.sh)
set_tests_properties(test_rand_5 PROPERTIES DEPENDS test_rand_4)
add_test(test_rand_6 ${CMAKE_BINARY_DIR}/test_run/rand/test_rand_6.sh)
set_tests_properties(test_rand_6 PROPERTIES DEPENDS test_rand_5)
add_test(test_rand_7 ${CMAKE_BINARY_DIR}/test_run/rand/test_rand_7.sh)
set_tests_properties(test_rand_7 PROPERTIES DEPENDS test_rand_6)
add_test(test_rand_8 ${CMAKE_BINARY_DIR}/test_run/rand/test_rand_8.sh)
set_tests_properties(test_rand_8 PROPERTIES DEPENDS test_rand_7)

add_test(test_sedi_1 ${CMAKE_BINARY_DIR}/test_run/sedi/test_sedi_1.sh)
add_test(test_sedi_2 ${CMAKE_BINARY_DIR}/test_run/sedi/test_sedi_2.sh)
set_tests_properties(test_sedi_2 PROPERTIES DEPENDS test_sedi_1)

######################################################################
# partmc library

add_library(partmclib src/aero_state.F90 src/integer_varray.F90
  src/integer_rmap.F90 src/integer_rmap2.F90 src/aero_sorted.F90
  src/aero_binned.F90 src/bin_grid.F90 src/constants.F90
  src/scenario.F90 src/env_state.F90 src/aero_mode.F90
  src/aero_dist.F90 src/aero_weight.F90 src/aero_weight_array.F90
  src/coag_kernel_additive.F90 src/coag_kernel_sedi.F90
  src/coag_kernel_constant.F90 src/coag_kernel_brown.F90
  src/coag_kernel_zero.F90 src/aero_data.F90 src/run_exact.F90
  src/run_part.F90 src/util.F90 src/stats.F90 src/run_sect.F90
  src/output.F90 src/mosaic.F90 src/gas_data.F90 src/gas_state.F90
  src/coagulation.F90 src/exact_soln.F90 src/coagulation_dist.F90
  src/coag_kernel.F90 src/spec_line.F90 src/spec_file.F90 src/rand.F90
  src/aero_particle.F90 src/aero_particle_array.F90 src/mpi.F90
  src/netcdf.F90 src/aero_info.F90 src/aero_info_array.F90
  src/nucleate.F90 src/condense.F90 ${SUNDIALS_SRC} ${GSL_SRC}
  ${C_SORT_SRC})

target_link_libraries(partmclib ${NETCDF_LIBS} ${SUNDIALS_LIBS}
  ${MOSAIC_LIB} ${GSL_LIBS})

set_target_properties(partmclib PROPERTIES OUTPUT_NAME partmc)

######################################################################
# partmc executable

add_executable(partmc src/partmc.F90)

target_link_libraries(partmc partmclib)

######################################################################
# test_bidisperse_ode

add_executable(test_bidisperse_ode
  test/bidisperse/test_bidisperse_ode.F90)

target_link_libraries(test_bidisperse_ode partmclib)

######################################################################
# test_bidisperse_extract

add_executable(test_bidisperse_extract
  test/bidisperse/test_bidisperse_extract.F90)

target_link_libraries(test_bidisperse_extract ${NETCDF_LIBS})

######################################################################
# test_nucleate_ode

add_executable(test_nucleate_ode test/nucleate/test_nucleate_ode.F90
  src/util.F90 src/constants.F90 ${C_SORT_SRC})

######################################################################
# test_poisson_sample

add_executable(test_poisson_sample test/rand/test_poisson_sample.F90
  src/util.F90 src/rand.F90 src/constants.F90 src/mpi.F90 ${GSL_SRC}
  ${C_SORT_SRC})

target_link_libraries(test_poisson_sample ${GSL_LIBS})

######################################################################
# test_binomial_sample

add_executable(test_binomial_sample test/rand/test_binomial_sample.F90
  src/util.F90 src/rand.F90 src/constants.F90 src/mpi.F90 ${GSL_SRC}
  ${C_SORT_SRC})

target_link_libraries(test_binomial_sample ${GSL_LIBS})

######################################################################
# bin_average_comp

add_executable(bin_average_comp src/bin_average_comp.F90)

target_link_libraries(bin_average_comp partmclib)

######################################################################
# bin_average_size

add_executable(bin_average_size src/bin_average_size.F90)

target_link_libraries(bin_average_size partmclib)

######################################################################
# extract_aero_*

add_executable(extract_aero_particles
  src/extract_aero_particles.F90 src/getopt.F90)
target_link_libraries(extract_aero_particles partmclib)

add_executable(extract_aero_size src/extract_aero_size.F90
  src/getopt.F90)
target_link_libraries(extract_aero_size partmclib)

add_executable(extract_aero_time src/extract_aero_time.F90
  src/getopt.F90)
target_link_libraries(extract_aero_time partmclib)

add_executable(extract_gas src/extract_gas.F90 src/getopt.F90)
target_link_libraries(extract_gas partmclib)

add_executable(extract_env src/extract_env.F90 src/getopt.F90)
target_link_libraries(extract_env partmclib)

######################################################################
# extract_sectional_*

add_executable(extract_sectional_aero_size
  src/extract_sectional_aero_size.F90 src/getopt.F90)
target_link_libraries(extract_sectional_aero_size partmclib)

add_executable(extract_sectional_aero_time
  src/extract_sectional_aero_time.F90 src/getopt.F90)
target_link_libraries(extract_sectional_aero_time partmclib)

######################################################################
# numeric_*

add_executable(numeric_diff src/numeric_diff.F90 src/getopt.F90)
target_link_libraries(numeric_diff partmclib)

add_executable(numeric_average src/numeric_average.F90)

######################################################################
# scenarios/1_urban_plume/process

add_executable(1_urban_plume_process
  scenarios/1_urban_plume/1_urban_plume_process.F90)
target_link_libraries(1_urban_plume_process partmclib)

######################################################################
