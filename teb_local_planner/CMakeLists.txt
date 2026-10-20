cmake_minimum_required(VERSION 3.16)
project(teb_local_planner)


if(POLICY CMP0167)
  cmake_policy(SET CMP0167 NEW)

# Set to Release in order to speed up the program significantly
set(CMAKE_BUILD_TYPE Release) #None, Debug, Release, RelWithDebInfo, MinSizeRel

endif()

if(NOT CMAKE_BUILD_TYPE)
  set(CMAKE_BUILD_TYPE Release)
endif()

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Module path for custom find modules
list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/cmake_modules")

# Ament dependencies
find_package(ament_cmake REQUIRED)
find_package(costmap_converter REQUIRED)
find_package(dwb_critics REQUIRED)
find_package(nav_2d_utils REQUIRED)
find_package(nav2_core REQUIRED)
find_package(nav2_costmap_2d REQUIRED)
find_package(nav2_util REQUIRED)
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


# Math and optimization dependencies
find_package(Boost REQUIRED COMPONENTS system thread)
find_package(Eigen3 REQUIRED)


# 1. SuiteSparse Discovery
find_package(SuiteSparse QUIET NO_MODULE)
if(NOT SuiteSparse_FOUND)
  find_package(SUITESPARSE REQUIRED)
endif()


# 2. G2O Discovery
find_package(g2o QUIET NO_MODULE)
if(NOT g2o_FOUND)
  find_package(G2O REQUIRED)
endif()


# Define core library
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

target_include_directories(teb_local_planner PUBLIC
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
  $<INSTALL_INTERFACE:include>
  ${EIGEN3_INCLUDE_DIRS}
  ${Boost_INCLUDE_DIRS}
  ${SUITESPARSE_INCLUDE_DIRS}
  ${G2O_INCLUDE_DIR}
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

ament_target_dependencies(teb_local_planner ${ament_dependencies})

# Target-based linking with fallback to raw library paths
if(TARGET SuiteSparse::CHOLMOD)
  target_link_libraries(teb_local_planner SuiteSparse::CHOLMOD)
elseif(TARGET SuiteSparse::SuiteSparse)
  target_link_libraries(teb_local_planner SuiteSparse::SuiteSparse)
else()
  target_link_libraries(teb_local_planner ${SUITESPARSE_LIBRARIES})
endif()

if(TARGET g2o::core)
  target_link_libraries(teb_local_planner g2o::core g2o::stuff)
  if(TARGET g2o::solver_cholmod)
    target_link_libraries(teb_local_planner  g2o::solver_cholmod)
  endif()
else()
  target_link_libraries(teb_local_planner  ${G2O_LIBRARIES})
endif()

target_link_libraries(teb_local_planner 
  Eigen3::Eigen
  ${Boost_LIBRARIES}
)

# Installation definitions
install(TARGETS teb_local_planner
  EXPORT export_teb_local_planner
  ARCHIVE DESTINATION lib
  LIBRARY DESTINATION lib
  RUNTIME DESTINATION bin
)

install(DIRECTORY include/ DESTINATION include/)
install(FILES teb_local_planner_plugin.xml DESTINATION share/${PROJECT_NAME})
install(PROGRAMS scripts/cmd_vel_to_ackermann_drive.py DESTINATION lib/${PROJECT_NAME})
install(DIRECTORY params DESTINATION share/${PROJECT_NAME})

# Exports
ament_export_include_directories(include)
ament_export_libraries(teb_local_planner)
ament_export_targets(export_teb_local_planner)
ament_export_dependencies(${ament_dependencies})
pluginlib_export_plugin_description_file(nav2_core teb_local_planner_plugin.xml)

if(BUILD_TESTING)
  find_package(ament_lint_auto REQUIRED)
  ament_lint_auto_find_test_dependencies()
endif()

ament_package()
