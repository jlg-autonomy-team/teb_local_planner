include(FindPackageHandleStandardArgs)

set(_SuiteSparse_ROOT_HINTS
  ${SuiteSparse_ROOT}
  $ENV{SuiteSparse_ROOT}
  ${SUITESPARSE_ROOT}
  $ENV{SUITESPARSE_ROOT}
)

set(_SuiteSparse_INCLUDE_HINTS)
set(_SuiteSparse_LIBRARY_HINTS)

foreach(_root IN LISTS _SuiteSparse_ROOT_HINTS)
  if(_root)
    list(APPEND _SuiteSparse_INCLUDE_HINTS
      "${_root}/include"
      "${_root}/include/suitesparse"
    )
    list(APPEND _SuiteSparse_LIBRARY_HINTS
      "${_root}/lib"
      "${_root}/lib64"
    )
  endif()
endforeach()

# Standard system locations are also searched automatically by find_path()
# and find_library().
find_path(SuiteSparse_INCLUDE_DIR
  NAMES cholmod.h
  HINTS ${_SuiteSparse_INCLUDE_HINTS}
  PATH_SUFFIXES suitesparse
)

find_library(SuiteSparse_CONFIG_LIBRARY
  NAMES suitesparseconfig SuiteSparse_config
  HINTS ${_SuiteSparse_LIBRARY_HINTS}
)

find_library(SuiteSparse_CHOLMOD_LIBRARY
  NAMES cholmod
  HINTS ${_SuiteSparse_LIBRARY_HINTS}
)

find_library(SuiteSparse_UMFPACK_LIBRARY
  NAMES umfpack
  HINTS ${_SuiteSparse_LIBRARY_HINTS}
)

find_library(SuiteSparse_SPQR_LIBRARY
  NAMES spqr
  HINTS ${_SuiteSparse_LIBRARY_HINTS}
)

# Required SuiteSparse dependencies used by CHOLMOD, UMFPACK, and SPQR.
find_library(SuiteSparse_AMD_LIBRARY
  NAMES amd
  HINTS ${_SuiteSparse_LIBRARY_HINTS}
)

find_library(SuiteSparse_CAMD_LIBRARY
  NAMES camd
  HINTS ${_SuiteSparse_LIBRARY_HINTS}
)

find_library(SuiteSparse_CCOLAMD_LIBRARY
  NAMES ccolamd
  HINTS ${_SuiteSparse_LIBRARY_HINTS}
)

find_library(SuiteSparse_COLAMD_LIBRARY
  NAMES colamd
  HINTS ${_SuiteSparse_LIBRARY_HINTS}
)

# Optional SuiteSparse components.
find_library(SuiteSparse_BTF_LIBRARY
  NAMES btf
  HINTS ${_SuiteSparse_LIBRARY_HINTS}
)

find_library(SuiteSparse_CXSPARSE_LIBRARY
  NAMES cxsparse csparse
  HINTS ${_SuiteSparse_LIBRARY_HINTS}
)

find_library(SuiteSparse_KLU_LIBRARY
  NAMES klu
  HINTS ${_SuiteSparse_LIBRARY_HINTS}
)

# METIS is external to SuiteSparse but can be used by CHOLMOD/SPQR.
find_library(SuiteSparse_METIS_LIBRARY
  NAMES metis
  HINTS ${_SuiteSparse_LIBRARY_HINTS}
)

# Optional numerical dependencies. SuiteSparse shared libraries often already
# carry these as transitive dependencies, but they are needed for static
# linking.
find_package(BLAS QUIET)
find_package(LAPACK QUIET)
find_package(Threads QUIET)

if(NOT SuiteSparse_FIND_COMPONENTS)
  set(SuiteSparse_FIND_COMPONENTS CHOLMOD)
endif()

# Required variables common to all SuiteSparse components.
set(_SuiteSparse_REQUIRED_VARS
  SuiteSparse_INCLUDE_DIR
  SuiteSparse_CONFIG_LIBRARY
  SuiteSparse_AMD_LIBRARY
  SuiteSparse_CAMD_LIBRARY
  SuiteSparse_CCOLAMD_LIBRARY
  SuiteSparse_COLAMD_LIBRARY
)

foreach(_component IN LISTS SuiteSparse_FIND_COMPONENTS)
  string(TOUPPER "${_component}" _component_upper)

  if(_component_upper STREQUAL "CHOLMOD")
    if(SuiteSparse_CHOLMOD_LIBRARY)
      set(SuiteSparse_CHOLMOD_FOUND TRUE)
      list(APPEND _SuiteSparse_REQUIRED_VARS
        SuiteSparse_CHOLMOD_LIBRARY
      )
    else()
      set(SuiteSparse_CHOLMOD_FOUND FALSE)
    endif()

  elseif(_component_upper STREQUAL "UMFPACK")
    if(SuiteSparse_UMFPACK_LIBRARY)
      set(SuiteSparse_UMFPACK_FOUND TRUE)
      list(APPEND _SuiteSparse_REQUIRED_VARS
        SuiteSparse_UMFPACK_LIBRARY
      )
    else()
      set(SuiteSparse_UMFPACK_FOUND FALSE)
    endif()

  elseif(_component_upper STREQUAL "SPQR")
    if(SuiteSparse_SPQR_LIBRARY)
      set(SuiteSparse_SPQR_FOUND TRUE)
      list(APPEND _SuiteSparse_REQUIRED_VARS
        SuiteSparse_SPQR_LIBRARY
      )
    else()
      set(SuiteSparse_SPQR_FOUND FALSE)
    endif()

  elseif(_component_upper STREQUAL "METIS")
    if(SuiteSparse_METIS_LIBRARY)
      set(SuiteSparse_METIS_FOUND TRUE)
    else()
      set(SuiteSparse_METIS_FOUND FALSE)
    endif()

    # METIS becomes required only when explicitly listed as a component.
    list(APPEND _SuiteSparse_REQUIRED_VARS
      SuiteSparse_METIS_LIBRARY
    )

  else()
    set(SuiteSparse_${_component}_FOUND FALSE)
    message(WARNING
      "Unknown SuiteSparse component requested: ${_component}"
    )
  endif()
endforeach()

find_package_handle_standard_args(SuiteSparse
  REQUIRED_VARS ${_SuiteSparse_REQUIRED_VARS}
  HANDLE_COMPONENTS
)

if(NOT SuiteSparse_FOUND)
  return()
endif()

function(_SuiteSparse_add_imported_target target_name library_path)
  if(library_path AND NOT TARGET "${target_name}")
    add_library("${target_name}" UNKNOWN IMPORTED)

    set_target_properties("${target_name}" PROPERTIES
      IMPORTED_LOCATION "${library_path}"
      INTERFACE_INCLUDE_DIRECTORIES "${SuiteSparse_INCLUDE_DIR}"
    )
  endif()
endfunction()

# Base targets.
_SuiteSparse_add_imported_target(
  SuiteSparse::config
  "${SuiteSparse_CONFIG_LIBRARY}"
)

_SuiteSparse_add_imported_target(
  SuiteSparse::amd
  "${SuiteSparse_AMD_LIBRARY}"
)

_SuiteSparse_add_imported_target(
  SuiteSparse::camd
  "${SuiteSparse_CAMD_LIBRARY}"
)

_SuiteSparse_add_imported_target(
  SuiteSparse::ccolamd
  "${SuiteSparse_CCOLAMD_LIBRARY}"
)

_SuiteSparse_add_imported_target(
  SuiteSparse::colamd
  "${SuiteSparse_COLAMD_LIBRARY}"
)

# Optional component targets.
_SuiteSparse_add_imported_target(
  SuiteSparse::METIS
  "${SuiteSparse_METIS_LIBRARY}"
)

_SuiteSparse_add_imported_target(
  SuiteSparse::BTF
  "${SuiteSparse_BTF_LIBRARY}"
)

_SuiteSparse_add_imported_target(
  SuiteSparse::CXSparse
  "${SuiteSparse_CXSPARSE_LIBRARY}"
)

_SuiteSparse_add_imported_target(
  SuiteSparse::KLU
  "${SuiteSparse_KLU_LIBRARY}"
)

_SuiteSparse_add_imported_target(
  SuiteSparse::CHOLMOD
  "${SuiteSparse_CHOLMOD_LIBRARY}"
)

_SuiteSparse_add_imported_target(
  SuiteSparse::UMFPACK
  "${SuiteSparse_UMFPACK_LIBRARY}"
)

_SuiteSparse_add_imported_target(
  SuiteSparse::SPQR
  "${SuiteSparse_SPQR_LIBRARY}"
)

# Select BLAS/LAPACK targets or raw library paths for static-link support.
set(_SuiteSparse_NUMERIC_LIBRARIES)

if(TARGET LAPACK::LAPACK)
  list(APPEND _SuiteSparse_NUMERIC_LIBRARIES LAPACK::LAPACK)
elseif(LAPACK_LIBRARIES)
  list(APPEND _SuiteSparse_NUMERIC_LIBRARIES ${LAPACK_LIBRARIES})
endif()

if(NOT _SuiteSparse_NUMERIC_LIBRARIES)
  if(TARGET BLAS::BLAS)
    list(APPEND _SuiteSparse_NUMERIC_LIBRARIES BLAS::BLAS)
  elseif(BLAS_LIBRARIES)
    list(APPEND _SuiteSparse_NUMERIC_LIBRARIES ${BLAS_LIBRARIES})
  endif()
endif()

if(TARGET Threads::Threads)
  list(APPEND _SuiteSparse_NUMERIC_LIBRARIES Threads::Threads)
endif()

set(_SuiteSparse_COMMON_LIBRARIES
  SuiteSparse::config
  SuiteSparse::amd
  SuiteSparse::camd
  SuiteSparse::ccolamd
  SuiteSparse::colamd
)

# CHOLMOD dependencies.
if(TARGET SuiteSparse::CHOLMOD)
  set(_SuiteSparse_CHOLMOD_LIBRARIES
    ${_SuiteSparse_COMMON_LIBRARIES}
    ${_SuiteSparse_NUMERIC_LIBRARIES}
  )

  if(TARGET SuiteSparse::METIS)
    list(APPEND _SuiteSparse_CHOLMOD_LIBRARIES
      SuiteSparse::METIS
    )
  endif()

  set_property(TARGET SuiteSparse::CHOLMOD APPEND PROPERTY
    INTERFACE_LINK_LIBRARIES
    "${_SuiteSparse_CHOLMOD_LIBRARIES}"
  )
endif()

# UMFPACK dependencies.
if(TARGET SuiteSparse::UMFPACK)
  set_property(TARGET SuiteSparse::UMFPACK APPEND PROPERTY
    INTERFACE_LINK_LIBRARIES
    "${_SuiteSparse_COMMON_LIBRARIES}"
  )
endif()

# SPQR dependencies.
if(TARGET SuiteSparse::SPQR)
  set(_SuiteSparse_SPQR_LIBRARIES
    SuiteSparse::CHOLMOD
    ${_SuiteSparse_COMMON_LIBRARIES}
    ${_SuiteSparse_NUMERIC_LIBRARIES}
  )

  if(TARGET SuiteSparse::METIS)
    list(APPEND _SuiteSparse_SPQR_LIBRARIES
      SuiteSparse::METIS
    )
  endif()

  set_property(TARGET SuiteSparse::SPQR APPEND PROPERTY
    INTERFACE_LINK_LIBRARIES
    "${_SuiteSparse_SPQR_LIBRARIES}"
  )
endif()

# Compatibility variables for older consumers.
set(SuiteSparse_INCLUDE_DIRS
  "${SuiteSparse_INCLUDE_DIR}"
)

set(SuiteSparse_LIBRARIES)

foreach(_target IN ITEMS
    SuiteSparse::CHOLMOD
    SuiteSparse::UMFPACK
    SuiteSparse::SPQR
)
  if(TARGET "${_target}")
    list(APPEND SuiteSparse_LIBRARIES "${_target}")
  endif()
endforeach()

mark_as_advanced(
  SuiteSparse_INCLUDE_DIR
  SuiteSparse_CONFIG_LIBRARY
  SuiteSparse_CHOLMOD_LIBRARY
  SuiteSparse_UMFPACK_LIBRARY
  SuiteSparse_SPQR_LIBRARY
  SuiteSparse_AMD_LIBRARY
  SuiteSparse_CAMD_LIBRARY
  SuiteSparse_CCOLAMD_LIBRARY
  SuiteSparse_COLAMD_LIBRARY
  SuiteSparse_METIS_LIBRARY
  SuiteSparse_BTF_LIBRARY
  SuiteSparse_CXSPARSE_LIBRARY
  SuiteSparse_KLU_LIBRARY
)
