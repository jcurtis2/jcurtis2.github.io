! Copyright (C) 2005-2015 Nicole Riemer and Matthew West
! Licensed under the GNU General Public License version 2 or (at your
! option) any later version. See the file COPYING for details.

!> \file
!> The pmc_bin_grid module.

!> The bin_grid_t structure and associated subroutines.
module pmc_bin_grid

  use pmc_constants
  use pmc_util
  use pmc_spec_file
  use pmc_mpi
  use pmc_netcdf
#ifdef PMC_USE_MPI
  use mpi
#endif

  !> Invalid type of bin grid.
  integer, parameter :: BIN_GRID_TYPE_INVALID = 0
  !> Logarithmically spaced bin grid.
  integer, parameter :: BIN_GRID_TYPE_LOG = 1
  !> Linearly spaced bin grid.
  integer, parameter :: BIN_GRID_TYPE_LINEAR = 2

  !> 1D grid, either logarithmic or linear.
  !!
  !! The grid of bins is logarithmically spaced in volume, an
  !! assumption that is quite heavily incorporated into the code. At
  !! some point in the future it would be nice to relax this
  !! assumption.
  type bin_grid_t
     !> Type of grid spacing (BIN_GRID_TYPE_LOG, etc).
     integer :: type
     !> Number of bins.
     integer :: n_bin
     !> Bin centers.
     real(kind=dp), allocatable :: centers(:)
     !> Bin edges.
     real(kind=dp), allocatable :: edges(:)
     !> Bin widths.
     real(kind=dp), allocatable :: widths(:)
  end type bin_grid_t

contains

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

  !> Allocates a bin_grid.
  subroutine bin_grid_allocate(bin_grid)

    !> Bin grid.
    type(bin_grid_t), intent(out) :: bin_grid

    bin_grid%type = BIN_GRID_TYPE_INVALID
    bin_grid%n_bin = 0
    allocate(bin_grid%centers(0))
    allocate(bin_grid%edges(0))
    allocate(bin_grid%widths(0))

  end subroutine bin_grid_allocate

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

  !> Allocates a bin_grid.
  subroutine bin_grid_allocate_size(bin_grid, n_bin)

    !> Bin grid.
    type(bin_grid_t), intent(out) :: bin_grid
    !> Number of bins.
    integer, intent(in) :: n_bin

    bin_grid%type = BIN_GRID_TYPE_INVALID
    bin_grid%n_bin = n_bin
    allocate(bin_grid%centers(n_bin))
    allocate(bin_grid%edges(n_bin + 1))
    allocate(bin_grid%widths(n_bin))

  end subroutine bin_grid_allocate_size

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

  !> Frees all memory.
  subroutine bin_grid_deallocate(bin_grid)

    !> Bin_grid to free.
    type(bin_grid_t), intent(inout) :: bin_grid

    deallocate(bin_grid%centers)
    deallocate(bin_grid%edges)
    deallocate(bin_grid%widths)

  end subroutine bin_grid_deallocate

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

  !> Copies a bin grid.
  subroutine bin_grid_copy(bin_grid_from, bin_grid_to)

    !> Bin_grid to copy from.
    type(bin_grid_t), intent(in) :: bin_grid_from
    !> Bin_grid to copy to.
    type(bin_grid_t), intent(inout) :: bin_grid_to

    call bin_grid_deallocate(bin_grid_to)
    call bin_grid_allocate_size(bin_grid_to, bin_grid_from%n_bin)
    bin_grid_to%type = bin_grid_from%type
    bin_grid_to%n_bin = bin_grid_from%n_bin
    bin_grid_to%centers = bin_grid_from%centers
    bin_grid_to%edges = bin_grid_from%edges
    bin_grid_to%widths = bin_grid_from%widths

  end subroutine bin_grid_copy

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

  !> Convert a concentration f(vol)d(vol) to f(ln(r))d(ln(r))
  !> where vol = 4/3 pi r^3.
  subroutine vol_to_lnr(r, f_vol, f_lnr)

    !> Radius (m).
    real(kind=dp), intent(in) :: r
    !> Concentration as a function of volume.
    real(kind=dp), intent(in) :: f_vol
    !> Concentration as a function of ln(r).
    real(kind=dp), intent(out) :: f_lnr

    f_lnr = f_vol * 4d0 * const%pi * r**3

  end subroutine vol_to_lnr

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

  !> Generates the bin grid given the range and number of bins.
  subroutine bin_grid_make(bin_grid, type, n_bin, min, max)

    !> New bin grid.
    type(bin_grid_t), intent(inout) :: bin_grid
    !> Type of bin grid.
    integer, intent(in) :: type
    !> Number of bins.
    integer, intent(in) :: n_bin
    !> Minimum edge value.
    real(kind=dp), intent(in) :: min
    !> Minimum edge value.
    real(kind=dp), intent(in) :: max

    real(kind=dp) :: c1, c2

    call assert_msg(538534122, n_bin >= 0, &
         "bin_grid requires a non-negative n_bin, not: " &
         // trim(integer_to_string(n_bin)))
    if (n_bin > 0) then
       if (type == BIN_GRID_TYPE_LOG) then
          call assert_msg(966541762, min > 0d0, &
               "log bin_grid requires a positive min value, not: " &
               // trim(real_to_string(min)))
       end if
       call assert_msg(711537859, min < max, &
            "bin_grid requires min < max, not: " &
            // trim(real_to_string(min)) // " and " &
            // trim(real_to_string(max)))
    end if
    call bin_grid_deallocate(bin_grid)
    call bin_grid_allocate_size(bin_grid, n_bin)
    bin_grid%type = type
    if (n_bin == 0) return
    if (type == BIN_GRID_TYPE_LOG) then
       call logspace(min, max, bin_grid%edges)
       c1 = exp(interp_linear_disc(log(min), log(max), 2 * n_bin + 1, 2))
       c2 = exp(interp_linear_disc(log(min), log(max), 2 * n_bin + 1, &
            2 * n_bin))
       call logspace(c1, c2, bin_grid%centers)
       bin_grid%widths = (log(max) - log(min)) / real(n_bin, kind=dp)
    elseif (bin_grid%type == BIN_GRID_TYPE_LINEAR) then
       call linspace(min, max, bin_grid%edges)
       c1 = interp_linear_disc(min, max, 2 * n_bin + 1, 2)
       c2 = interp_linear_disc(min, max, 2 * n_bin + 1, 2 * n_bin)
       call linspace(c1, c2, bin_grid%centers)
       bin_grid%widths = (max - min) / real(n_bin, kind=dp)
    else
       call die_msg(678302366, "unknown bin_grid type: " &
            // trim(integer_to_string(bin_grid%type)))
    end if

  end subroutine bin_grid_make

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

  !> Find the bin number that contains a given value.
  !!
  !! If a particle is below the smallest bin then its bin number is
  !! 0. If a particle is above the largest bin then its bin number is
  !! <tt>n_bin + 1</tt>.
  integer function bin_grid_find(bin_grid, val)

    !> Bin_grid.
    type(bin_grid_t), intent(in) :: bin_grid
    !> Value to locate bin for.
    real(kind=dp), intent(in) :: val

    call assert(448215689, bin_grid%n_bin >= 0)
    bin_grid_find = 0
    if (bin_grid%n_bin == 0) return
    if (bin_grid%type == BIN_GRID_TYPE_LOG) then
       bin_grid_find = logspace_find(bin_grid%edges(1), &
            bin_grid%edges(bin_grid%n_bin + 1), bin_grid%n_bin + 1, val)
    elseif (bin_grid%type == BIN_GRID_TYPE_LINEAR) then
       bin_grid_find = linspace_find(bin_grid%edges(1), &
            bin_grid%edges(bin_grid%n_bin + 1), bin_grid%n_bin + 1, val)
    else
       call die_msg(348908641, "unknown bin_grid type: " &
            // trim(integer_to_string(bin_grid%type)))
    end if

  end function bin_grid_find

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

  !> Make a histogram with of the given weighted data, scaled by the
  !> bin sizes.
  function bin_grid_histogram_1d(x_bin_grid, x_data, weight_data)

    !> x-axis bin grid.
    type(bin_grid_t), intent(in) :: x_bin_grid
    !> Data values on the x-axis.
    real(kind=dp), intent(in) :: x_data(:)
    !> Data value weights.
    real(kind=dp), intent(in) :: weight_data(size(x_data))

    !> Return histogram.
    real(kind=dp) :: bin_grid_histogram_1d(x_bin_grid%n_bin)

    integer :: i_data, x_bin

    bin_grid_histogram_1d = 0d0
    do i_data = 1,size(x_data)
       x_bin = bin_grid_find(x_bin_grid, x_data(i_data))
       if ((x_bin >= 1) .and. (x_bin <= x_bin_grid%n_bin)) then
          bin_grid_histogram_1d(x_bin) = bin_grid_histogram_1d(x_bin) &
               + weight_data(i_data) / x_bin_grid%widths(x_bin)
       end if
    end do

  end function bin_grid_histogram_1d

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

  !> Make a 2D histogram with of the given weighted data, scaled by
  !> the bin sizes.
  function bin_grid_histogram_2d(x_bin_grid, x_data, y_bin_grid, y_data, &
       weight_data)

    !> x-axis bin grid.
    type(bin_grid_t), intent(in) :: x_bin_grid
    !> Data values on the x-axis.
    real(kind=dp), intent(in) :: x_data(:)
    !> y-axis bin grid.
    type(bin_grid_t), intent(in) :: y_bin_grid
    !> Data values on the y-axis.
    real(kind=dp), intent(in) :: y_data(size(x_data))
    !> Data value weights.
    real(kind=dp), intent(in) :: weight_data(size(x_data))

    !> Return histogram.
    real(kind=dp) :: bin_grid_histogram_2d(x_bin_grid%n_bin, y_bin_grid%n_bin)

    integer :: i_data, x_bin, y_bin

    bin_grid_histogram_2d = 0d0
    do i_data = 1,size(x_data)
       x_bin = bin_grid_find(x_bin_grid, x_data(i_data))
       y_bin = bin_grid_find(y_bin_grid, y_data(i_data))
       if ((x_bin >= 1) .and. (x_bin <= x_bin_grid%n_bin) &
            .and. (y_bin >= 1) .and. (y_bin <= y_bin_grid%n_bin)) then
          bin_grid_histogram_2d(x_bin, y_bin) &
               = bin_grid_histogram_2d(x_bin, y_bin) + weight_data(i_data) &
               / x_bin_grid%widths(x_bin) / y_bin_grid%widths(y_bin)
       end if
    end do

  end function bin_grid_histogram_2d

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

  !> Read the specification for a radius bin_grid from a spec file.
  subroutine spec_file_read_radius_bin_grid(file, bin_grid)

    !> Spec file.
    type(spec_file_t), intent(inout) :: file
    !> Radius bin grid.
    type(bin_grid_t), intent(inout) :: bin_grid

    integer :: n_bin
    real(kind=dp) :: d_min, d_max

    !> \page input_format_diam_bin_grid Input File Format: Diameter Axis Bin Grid
    !!
    !! The diameter bin grid is logarithmic, consisting of
    !! \f$n_{\rm bin}\f$ bins with centers \f$c_i\f$ (\f$i =
    !! 1,\ldots,n_{\rm bin}\f$) and edges \f$e_i\f$ (\f$i =
    !! 1,\ldots,(n_{\rm bin} + 1)\f$) such that \f$e_{i+1}/e_i\f$ is a
    !! constant and \f$c_i/e_i = \sqrt{e_{i+1}/e_i}\f$. That is,
    !! \f$\ln(e_i)\f$ are uniformly spaced and \f$\ln(c_i)\f$ are the
    !! arithmetic centers.
    !!
    !! The diameter axis bin grid is specified by the parameters:
    !!   - \b n_bin (integer): The number of bins \f$n_{\rm bin}\f$.
    !!   - \b d_min (real, unit m): The left edge of the left-most bin,
    !!     \f$e_1\f$.
    !!   - \b d_max (real, unit m): The right edge of the right-most bin,
    !!     \f$e_{n_{\rm bin} + 1}\f$.
    !!
    !! See also:
    !!   - \ref spec_file_format --- the input file text format
    !!   - \ref output_format_diam_bin_grid --- the corresponding output format

    call spec_file_read_integer(file, 'n_bin', n_bin)
    call spec_file_read_real(file, 'd_min', d_min)
    call spec_file_read_real(file, 'd_max', d_max)
    call bin_grid_make(bin_grid, BIN_GRID_TYPE_LOG, n_bin, diam2rad(d_min), &
         diam2rad(d_max))

  end subroutine spec_file_read_radius_bin_grid

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

  !> Determines the number of bytes required to pack the given value.
  integer function pmc_mpi_pack_size_bin_grid(val)

    !> Value to pack.
    type(bin_grid_t), intent(in) :: val

    pmc_mpi_pack_size_bin_grid = &
         pmc_mpi_pack_size_integer(val%type) &
         + pmc_mpi_pack_size_integer(val%n_bin) &
         + pmc_mpi_pack_size_real_array(val%centers) &
         + pmc_mpi_pack_size_real_array(val%edges) &
         + pmc_mpi_pack_size_real_array(val%widths)

  end function pmc_mpi_pack_size_bin_grid

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

  !> Packs the given value into the buffer, advancing position.
  subroutine pmc_mpi_pack_bin_grid(buffer, position, val)

    !> Memory buffer.
    character, intent(inout) :: buffer(:)
    !> Current buffer position.
    integer, intent(inout) :: position
    !> Value to pack.
    type(bin_grid_t), intent(in) :: val

#ifdef PMC_USE_MPI
    integer :: prev_position

    prev_position = position
    call pmc_mpi_pack_integer(buffer, position, val%type)
    call pmc_mpi_pack_integer(buffer, position, val%n_bin)
    call pmc_mpi_pack_real_array(buffer, position, val%centers)
    call pmc_mpi_pack_real_array(buffer, position, val%edges)
    call pmc_mpi_pack_real_array(buffer, position, val%widths)
    call assert(385455586, &
         position - prev_position <= pmc_mpi_pack_size_bin_grid(val))
#endif

  end subroutine pmc_mpi_pack_bin_grid

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

  !> Unpacks the given value from the buffer, advancing position.
  subroutine pmc_mpi_unpack_bin_grid(buffer, position, val)

    !> Memory buffer.
    character, intent(inout) :: buffer(:)
    !> Current buffer position.
    integer, intent(inout) :: position
    !> Value to pack.
    type(bin_grid_t), intent(inout) :: val

#ifdef PMC_USE_MPI
    integer :: prev_position

    prev_position = position
    call pmc_mpi_unpack_integer(buffer, position, val%type)
    call pmc_mpi_unpack_integer(buffer, position, val%n_bin)
    call pmc_mpi_unpack_real_array_alloc(buffer, position, val%centers)
    call pmc_mpi_unpack_real_array_alloc(buffer, position, val%edges)
    call pmc_mpi_unpack_real_array_alloc(buffer, position, val%widths)
    call assert(741838730, &
         position - prev_position <= pmc_mpi_pack_size_bin_grid(val))
#endif

  end subroutine pmc_mpi_unpack_bin_grid

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

  !> Check whether all processors have the same value.
  logical function pmc_mpi_allequal_bin_grid(val)

    !> Value to compare.
    type(bin_grid_t), intent(inout) :: val

#ifdef PMC_USE_MPI
    if (.not. pmc_mpi_allequal_integer(val%type)) then
       pmc_mpi_allequal_bin_grid = .false.
       return
    end if

    if (.not. pmc_mpi_allequal_integer(val%n_bin)) then
       pmc_mpi_allequal_bin_grid = .false.
       return
    end if

    if (val%n_bin == 0) then
       pmc_mpi_allequal_bin_grid = .true.
       return
    end if

    if (pmc_mpi_allequal_real(val%edges(1)) &
         .and. pmc_mpi_allequal_real(val%edges(val%n_bin))) then
       pmc_mpi_allequal_bin_grid = .true.
    else
       pmc_mpi_allequal_bin_grid = .false.
    end if
#else
    pmc_mpi_allequal_bin_grid = .true.
#endif

  end function pmc_mpi_allequal_bin_grid

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

  !> Write a bin grid dimension to the given NetCDF file if it is
  !> not already present and in any case return the associated dimid.
  subroutine bin_grid_netcdf_dim(bin_grid, ncid, dim_name, unit, dimid, &
       long_name, scale)

    !> Bin_grid structure.
    type(bin_grid_t), intent(in) :: bin_grid
    !> NetCDF file ID, in data mode.
    integer, intent(in) :: ncid
    !> Dimension name.
    character(len=*), intent(in) :: dim_name
    !> Units for the grid.
    character(len=*), intent(in) :: unit
    !> Dimid of the grid dimension.
    integer, intent(out) :: dimid
    !> Long dimension name to use.
    character(len=*), intent(in), optional :: long_name
    !> Factor to scale grid by before output.
    real(kind=dp), intent(in), optional :: scale

    integer :: status, varid, dimid_edges, varid_edges, varid_widths, i
    real(kind=dp) :: centers(bin_grid%n_bin), edges(bin_grid%n_bin + 1)
    real(kind=dp) :: widths(bin_grid%n_bin)
    character(len=(len_trim(dim_name)+10)) :: dim_name_edges
    character(len=255) :: use_long_name

    status = nf90_inq_dimid(ncid, dim_name, dimid)
    if (status == NF90_NOERR) return
    if (status /= NF90_EBADDIM) call pmc_nc_check(status)

    ! dimension not defined, so define now define it

    dim_name_edges = trim(dim_name) // "_edges"
    if (present(long_name)) then
       call assert_msg(125084459, len_trim(long_name) <= len(use_long_name), &
            "long_name is longer than " &
            // trim(integer_to_string(len(use_long_name))))
       use_long_name = trim(long_name)
    else
       call assert_msg(660927086, len_trim(dim_name) <= len(use_long_name), &
            "dim_name is longer than " &
            // trim(integer_to_string(len(use_long_name))))
       use_long_name = trim(dim_name)
    end if

    call pmc_nc_check(nf90_redef(ncid))
    call pmc_nc_check(nf90_def_dim(ncid, dim_name, bin_grid%n_bin, dimid))
    call pmc_nc_check(nf90_def_dim(ncid, dim_name_edges, bin_grid%n_bin + 1, &
         dimid_edges))
    call pmc_nc_check(nf90_enddef(ncid))

    centers = bin_grid%centers
    edges = bin_grid%edges
    widths = bin_grid%widths
    if (bin_grid%type == BIN_GRID_TYPE_LOG) then
       if (present(scale)) then
          centers = centers * scale
          edges = edges * scale
       end if
       call pmc_nc_write_real_1d(ncid, centers, dim_name, (/ dimid /), &
            unit=unit, long_name=(trim(use_long_name) // " grid centers"), &
            description=("logarithmically spaced centers of " &
            // trim(use_long_name) // " grid, so that " // trim(dim_name) &
            // "(i) is the geometric mean of " // trim(dim_name_edges) &
            // "(i) and " // trim(dim_name_edges) // "(i + 1)"))
       call pmc_nc_write_real_1d(ncid, edges, dim_name_edges, &
            (/ dimid_edges /), unit=unit, &
            long_name=(trim(use_long_name) // " grid edges"), &
            description=("logarithmically spaced edges of " &
            // trim(use_long_name) // " grid, with one more edge than center"))
       call pmc_nc_write_real_1d(ncid, widths, trim(dim_name) // "_widths", &
            (/ dimid /), unit="1", &
            long_name=(trim(use_long_name) // " grid widths"), &
            description=("base-e logarithmic widths of " &
            // trim(use_long_name) // " grid, with " // trim(dim_name) &
            // "_widths(i) = ln(" // trim(dim_name_edges) // "(i + 1) / " &
            // trim(dim_name_edges) // "(i))"))
    elseif (bin_grid%type == BIN_GRID_TYPE_LINEAR) then
       if (present(scale)) then
          centers = centers * scale
          edges = edges * scale
          widths = widths * scale
       end if
       call pmc_nc_write_real_1d(ncid, centers, dim_name, (/ dimid /), &
            unit=unit, long_name=(trim(use_long_name) // " grid centers"), &
            description=("linearly spaced centers of " // trim(use_long_name) &
            // " grid, so that " // trim(dim_name) // "(i) is the mean of " &
            // trim(dim_name_edges) // "(i) and " // trim(dim_name_edges) &
            // "(i + 1)"))
       call pmc_nc_write_real_1d(ncid, edges, dim_name_edges, &
            (/ dimid_edges /), unit=unit, &
            long_name=(trim(use_long_name) // " grid edges"), &
            description=("linearly spaced edges of " &
            // trim(use_long_name) // " grid, with one more edge than center"))
       call pmc_nc_write_real_1d(ncid, widths, trim(dim_name) // "_widths", &
            (/ dimid /), unit=unit, &
            long_name=(trim(use_long_name) // " grid widths"), &
            description=("widths of " // trim(use_long_name) &
            // " grid, with " // trim(dim_name) // "_widths(i) = " &
            // trim(dim_name_edges) // "(i + 1) - " // trim(dim_name_edges) &
            // "(i)"))
    else
       call die_msg(942560572, "unknown bin_grid type: " &
            // trim(integer_to_string(bin_grid%type)))
    end if

  end subroutine bin_grid_netcdf_dim

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

  !> Write a bin grid to the given NetCDF file.
  subroutine bin_grid_output_netcdf(bin_grid, ncid, dim_name, unit, &
       long_name, scale)

    !> Bin_grid structure.
    type(bin_grid_t), intent(in) :: bin_grid
    !> NetCDF file ID, in data mode.
    integer, intent(in) :: ncid
    !> Dimension name.
    character(len=*), intent(in) :: dim_name
    !> Units for the grid.
    character(len=*), intent(in) :: unit
    !> Long dimension name to use.
    character(len=*), intent(in), optional :: long_name
    !> Factor to scale grid by before output.
    real(kind=dp), intent(in), optional :: scale

    integer :: dimid

    call bin_grid_netcdf_dim(bin_grid, ncid, dim_name, unit, dimid, &
         long_name, scale)

  end subroutine bin_grid_output_netcdf

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

  !> Read full state.
  subroutine bin_grid_input_netcdf(bin_grid, ncid, dim_name, scale)

    !> bin_grid to read.
    type(bin_grid_t), intent(inout) :: bin_grid
    !> NetCDF file ID, in data mode.
    integer, intent(in) :: ncid
    !> Dimension name.
    character(len=*), intent(in) :: dim_name
    !> Factor to scale grid by after input.
    real(kind=dp), intent(in), optional :: scale

    integer :: dimid, varid, n_bin, type
    character(len=1000) :: name, description
    real(kind=dp), allocatable :: edges(:)

    call pmc_nc_check(nf90_inq_dimid(ncid, dim_name, dimid))
    call pmc_nc_check(nf90_Inquire_Dimension(ncid, dimid, name, n_bin))
    call pmc_nc_check(nf90_inq_varid(ncid, dim_name, varid))
    call pmc_nc_check(nf90_get_att(ncid, varid, "description", description))

    allocate(edges(n_bin + 1))
    call pmc_nc_read_real_1d(ncid, edges, dim_name // "_edges")

    if (starts_with(description, "logarithmically")) then
       type = BIN_GRID_TYPE_LOG
    elseif (starts_with(description, "linearly")) then
       type = BIN_GRID_TYPE_LINEAR
    else
       call die_msg(792158584, "cannot identify grid type for NetCDF " &
            // "dimension: " // trim(dim_name))
    end if

    if (present(scale)) then
       call bin_grid_make(bin_grid, type, n_bin, scale * edges(1), &
            scale * edges(n_bin + 1))
    else
       call bin_grid_make(bin_grid, type, n_bin, edges(1), edges(n_bin + 1))
    end if

    deallocate(edges)

  end subroutine bin_grid_input_netcdf

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

end module pmc_bin_grid
