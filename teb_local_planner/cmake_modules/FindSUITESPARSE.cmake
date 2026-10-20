
# - Find SuiteSparse (CHOLMOD, AMD, CAMD, COLAMD, CCOLAMD, and suitesparseconfig)
# Output variables:
#   SUITESPARSE_FOUND
#   SUITESPARSE_INCLUDE_DIRS
#   SUITESPARSE_LIBRARIES

find_path(CHOLMOD_INCLUDE_DIR
  NAMES cholmod.h
  PATHS
    /usr/local/include
    /usr/local/include/suitesparse
    /usr/include
    /usr/include/suitesparse
  PATH_SUFFIXES cholmod
)

set(SUITESPARSE_SEARCH_LIB_PATHS
  /usr/local/lib
  /usr/lib
  /usr/lib/aarch64-linux-gnu
  /usr/lib/x86_64-linux-gnu
)

find_library(CHOLMOD_LIB NAMES cholmod PATHS ${SUITESPARSE_SEARCH_LIB_PATHS} NO_DEFAULT_PATH)
find_library(AMD_LIB NAMES amd PATHS ${SUITESPARSE_SEARCH_LIB_PATHS} NO_DEFAULT_PATH)
find_library(COLAMD_LIB NAMES colamd PATHS ${SUITESPARSE_SEARCH_LIB_PATHS} NO_DEFAULT_PATH)
find_library(CAMD_LIB NAMES camd PATHS ${SUITESPARSE_SEARCH_LIB_PATHS} NO_DEFAULT_PATH)
find_library(CCOLAMD_LIB NAMES ccolamd PATHS ${SUITESPARSE_SEARCH_LIB_PATHS} NO_DEFAULT_PATH)
find_library(SUITESPARSECONFIG_LIB NAMES suitesparseconfig PATHS ${SUITESPARSE_SEARCH_LIB_PATHS} NO_DEFAULT_PATH)

# Fallback searches if NO_DEFAULT_PATH missed standard roots
if(NOT CHOLMOD_LIB)
  find_library(CHOLMOD_LIB NAMES cholmod)
  find_library(AMD_LIB NAMES amd)
  find_library(COLAMD_LIB NAMES colamd)
  find_library(CAMD_LIB NAMES camd)
  find_library(CCOLAMD_LIB NAMES ccolamd)
  find_library(SUITESPARSECONFIG_LIB NAMES suitesparseconfig)
endif()

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(SUITESPARSE
  DEFAULT_MSG
  CHOLMOD_INCLUDE_DIR
  CHOLMOD_LIB
)

if(SUITESPARSE_FOUND)
  set(SUITESPARSE_INCLUDE_DIRS ${CHOLMOD_INCLUDE_DIR})
  set(SUITESPARSE_LIBRARIES
    ${CHOLMOD_LIB}
    ${AMD_LIB}
    ${COLAMD_LIB}
  )
  if(CAMD_LIB)
    list(APPEND SUITESPARSE_LIBRARIES ${CAMD_LIB})
  endif()
  if(CCOLAMD_LIB)
    list(APPEND SUITESPARSE_LIBRARIES ${CCOLAMD_LIB})
  endif()
  if(SUITESPARSECONFIG_LIB)
    list(APPEND SUITESPARSE_LIBRARIES ${SUITESPARSECONFIG_LIB})
  endif()

  if(NOT TARGET SuiteSparse::CHOLMOD)
    add_library(SuiteSparse::CHOLMOD INTERFACE IMPORTED)
    set_target_properties(SuiteSparse::CHOLMOD PROPERTIES
      INTERFACE_INCLUDE_DIRECTORIES "${SUITESPARSE_INCLUDE_DIRS}"
      INTERFACE_LINK_LIBRARIES "${SUITESPARSE_LIBRARIES}"
    )
  endif()
endif()

