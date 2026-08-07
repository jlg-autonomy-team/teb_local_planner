cmake_minimum_required(VERSION 3.5)
project(teb_local_planner)

# Set to Release in order to speed up the program significantly
set(CMAKE_BUILD_TYPE Release) #None, Debug, Release, RelWithDebInfo, MinSizeRel
option(TEB_DISABLE_LTO
  "Disable LTO/IPO for teb_local_planner only" ON)

if(TEB_DISABLE_LTO)
  foreach(flag_var
      CMAKE_C_FLAGS
      CMAKE_CXX_FLAGS
      CMAKE_EXE_LINKER_FLAGS
      CMAKE_SHARED_LINKER_FLAGS
      CMAKE_MODULE_LINKER_FLAGS)

    set(_teb_saved_${flag_var} "${${flag_var}}")

    string(REGEX REPLACE
      "(^|[ \t])(-flto([=][^ \t]+)?|-ipo)([ \t]|$)"
      "\\1\\4"
      ${flag_var}
      "${${flag_var}}")
  endforeach()
  set(TEB_USE_FULL_LTO OFF CACHE BOOL
    "Use full LTO for teb_local_planner"
    FORCE
  )
endif()

option(TEB_USE_FULL_LTO
  "Use full LTO for teb_local_planner" OFF)

if(TEB_USE_FULL_LTO)
  # Remove inherited LTO/IPO flags while preserving every other flag.
  foreach(_flag_var
      CMAKE_C_FLAGS
      CMAKE_CXX_FLAGS
      CMAKE_EXE_LINKER_FLAGS
      CMAKE_SHARED_LINKER_FLAGS
      CMAKE_MODULE_LINKER_FLAGS)

    string(REGEX REPLACE
      "(^|[ \t])(-flto([=][^ \t]+)?|-ipo)([ \t]|$)"
      "\\1\\4"
      ${_flag_var}
      "${${_flag_var}}")
  endforeach()

endif()


# Default to C++14
if(NOT CMAKE_CXX_STANDARD)
  set(CMAKE_CXX_STANDARD 14)
endif()

#if(CMAKE_COMPILER_IS_GNUCXX OR CMAKE_CXX_COMPILER_ID MATCHES "Clang")
#  add_compile_options(-Wall -Wextra -Wpedantic)
#endif()

## Find catkin macros and libraries
find_package(ament_cmake REQUIRED)
find_package(costmap_converter REQUIRED)
find_package(dwb_critics REQUIRED)
find_package(nav_2d_utils REQUIRED)
find_package(nav2_core REQUIRED)
find_package(nav2_costmap_2d REQUIRED)
find_package(nav2_util REQUIRED)
#find_package(interactive_markers REQUIRED)
find_package(geometry_msgs REQUIRED)
find_package(nav_msgs REQUIRED)
find_package(rclcpp REQUIRED)
find_package(rclcpp_action REQUIRED)
find_package(rclcpp_lifecycle REQUIRED)
find_package(std_msgs REQUIRED)
find_package(pluginlib REQUIRED)
find_package(teb_msgs REQUIRED)
find_package(tf2 REQUIRED)
find_package(tf2_eigen REQUIRED)
find_package(tf2_geometry_msgs REQUIRED)
find_package(tf2_ros REQUIRED)
find_package(visualization_msgs REQUIRED)
find_package(builtin_interfaces REQUIRED)

message(STATUS "System: ${CMAKE_SYSTEM}")
cmake_policy(SET CMP0072 NEW)
set(OpenGL_GL_PREFERENCE GLVND)

find_package(g2o CONFIG REQUIRED)
find_package(Boost REQUIRED)
list(PREPEND CMAKE_MODULE_PATH
  "${CMAKE_CURRENT_SOURCE_DIR}/cmake_modules"
)

if(NOT EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/cmake_modules/FindSUITESPARSE.cmake")
  message(FATAL_ERROR
    "Expected SuiteSparse finder at "
    "${CMAKE_CURRENT_SOURCE_DIR}/cmake_modules/FindSUITESPARSE.cmake"
 )
endif()

find_package(SuiteSparse_config CONFIG REQUIRED)
find_package(AMD CONFIG REQUIRED)
find_package(COLAMD CONFIG REQUIRED)
find_package(CAMD CONFIG REQUIRED)
find_package(CCOLAMD CONFIG REQUIRED)
find_package(CHOLMOD CONFIG REQUIRED)
find_package(UMFPACK CONFIG REQUIRED)
find_package(SPQR CONFIG REQUIRED)

# Eigen3 FindScript Backward compatibility (ubuntu saucy)
# Since FindEigen.cmake is deprecated starting from jade.
if (EXISTS "FindEigen3.cmake")
  find_package(Eigen3 REQUIRED)
  set(Eigen_INCLUDE_DIRS ${Eigen3_INCLUDE_DIRS})
elseif (EXISTS "FindEigen.cmake")
  find_package(Eigen REQUIRED)
elseif (EXISTS "FindEigen.cmake")
  message(WARNING "No findEigen cmake script found. You must provde one of them,
  e.g. by adding it to ${PROJECT_SOURCE_DIR}/cmake_modules.")
endif (EXISTS "FindEigen3.cmake")

set(EXTERNAL_INCLUDE_DIRS ${Eigen_INCLUDE_DIRS} ${G2O_INCLUDE_DIR} ${CHOLMOD_INCLUDE_DIR} ${UMFPACK_INCLUDE_DIR} ${SPQR_INCLUDE_DIR}) 
set(EXTERNAL_LIBS ${Boost_LIBRARIES} ${G2O_LIBRARIES} ${CHOLMOD_LIBRARY} ${UMFPACK_LIBRARY} ${SPQR_LIBRARY})

###########
## Build ##
###########

include_directories(
  include
  ${Boost_INCLUDE_DIRS}
  ${EXTERNAL_INCLUDE_DIRS}
)

## Build the teb_local_planner library

add_library(teb_local_planner SHARED
   src/timed_elastic_band.cpp
   src/optimal_planner.cpp
   src/obstacles.cpp
   src/visualization.cpp
   src/recovery_behaviors.cpp
   src/teb_config.cpp
   src/homotopy_class_planner.cpp
   src/teb_local_planner_ros.cpp
   src/graph_search.cpp
)

# Work around the Intel optimizer crash only for the translation unit that triggers it.
set_source_files_properties(src/teb_config.cpp
  PROPERTIES COMPILE_OPTIONS "-qno-opt-dynamic-align"
)

set(ament_dependencies
    costmap_converter
    dwb_critics
    nav_2d_utils
    nav2_core
    nav2_costmap_2d
    nav2_util
    geometry_msgs
    nav_msgs
    rclcpp
    rclcpp_action
    rclcpp_lifecycle
    std_msgs
    pluginlib
    teb_msgs
    tf2
    tf2_eigen
    tf2_geometry_msgs
    tf2_ros
    visualization_msgs
    builtin_interfaces
)
ament_target_dependencies(teb_local_planner
   ${ament_dependencies}
)
target_link_libraries(teb_local_planner
   ${EXTERNAL_LIBS}
)

target_compile_definitions(teb_local_planner PUBLIC "PLUGINLIB__DISABLE_BOOST_FUNCTIONS")

if(TEB_USE_FULL_LTO)
  set_property(TARGET teb_local_planner
    PROPERTY INTERPROCEDURAL_OPTIMIZATION OFF)

  target_compile_options(teb_local_planner
    PRIVATE
      -flto=full)

  target_link_options(teb_local_planner
    PRIVATE
      -flto=full)
endif()

if(TEB_DISABLE_LTO)
  set_property(TARGET teb_local_planner
    PROPERTY INTERPROCEDURAL_OPTIMIZATION OFF)

  target_compile_options(teb_local_planner
  PUBLIC
  -march=$ENV{OPTARCH}
  -mtune=$ENV{OPTARCH}
  -fPIC 
  -include stdint.h 
  -D_GNU_SOURCE 
  -qopenmp 
  -qopt-for-throughput=multi-job 
    )

    target_compile_options(teb_local_planner
      PRIVATE
      -fno-lto
    )
    target_link_options(teb_local_planner
        PRIVATE
          -fuse-ld=lld
          -fno-lto
          -Wl,--apply-dynamic-relocs,-Bsymbolic,--emit-relocs,--export-dynamic,--fat-lto-objects,--no-as-needed,--no-gc-sections,-use-intel-optimized-headers)

endif()

#############
## Install ##
#############

## Mark executables and/or libraries for installation
install(TARGETS teb_local_planner
   DESTINATION lib
)

## Mark cpp header files for installation
install(DIRECTORY include/
   DESTINATION include/
)

## Mark other files for installation (e.g. launch and bag files, etc.)
install(FILES
  teb_local_planner_plugin.xml
  DESTINATION share
  )

install(PROGRAMS scripts/cmd_vel_to_ackermann_drive.py DESTINATION lib/${PROJECT_NAME})

install(DIRECTORY params DESTINATION share/${PROJECT_NAME})

ament_export_include_directories(include)
ament_export_libraries(teb_local_planner)
ament_export_dependencies(${ament_dependencies})
pluginlib_export_plugin_description_file(nav2_core teb_local_planner_plugin.xml)

#############
## Testing ##
#############

if(BUILD_TESTING)
  find_package(ament_cmake_gtest REQUIRED)
  #ament_add_gtest(homotopy_class_planner_test
  #    test/homotopy_class_planner_test.cpp
  #)
  #target_link_libraries(homotopy_class_planner_test
  #    teb_local_planner
  #)
endif()

ament_package()
