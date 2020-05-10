
function(add_metric target component_name metric_type run_mode)

  # add_metric creates a runner script for new metrics executables, so that `run_metrics.sh`
  # can later find and run all available metrics generators. add_metric resembles the CTest
  # function add_test in taking a build target and the command line arguments (here stored
  # in extra_args) to run the executable. For instance, semantic segmentation metrics
  # may provide the path to a dataset as extra_args. The component_name variable is the same
  # as the component_name from the MetricsManager, it is used to identify the area of development
  # from which this metrics run derives (e.g. segmentation, lane tracking, etc). Another extra arg
  # can be provided for the path to the executable. For example, path to a python executable
  if(NOT (${metric_type} STREQUAL runtime OR ${metric_type} STREQUAL algorithm OR ${metric_type} STREQUAL analytics))
    message(FATAL_ERROR "metric_type must be runtime, algorithm or analytics")
  endif()

  if(NOT (${run_mode} STREQUAL online OR ${run_mode} STREQUAL offline))
    message(FATAL_ERROR "run_mode must be online or offline")
  endif()

  execute_process(COMMAND uname -m COMMAND tr -d '\n' OUTPUT_VARIABLE BUILD_MACHINE_ARCH)
  execute_process(COMMAND git rev-parse --verify HEAD COMMAND tr -d '\n' OUTPUT_VARIABLE COMMIT_ID)
  execute_process(COMMAND git --no-pager show -s --format=%an HEAD COMMAND tr -d '\n' OUTPUT_VARIABLE AUTHOR)
  set(BUILD_MACHINE_ID $ENV{NODE_NAME})

  # get branch name using rev-parse only if it isn't set in Jenkins
  set(BRANCH_NAME $ENV{BRANCH_NAME})
  if(NOT BRANCH_NAME)
    execute_process(COMMAND git rev-parse --abbrev-ref HEAD COMMAND tr -d '\n' OUTPUT_VARIABLE BRANCH_NAME)
  endif()

  # for PRs extract branch name being PRed. CHANGE_BRANCH set by Jenkins
  string(SUBSTRING ${BRANCH_NAME} 0 2 BRANCH_NAME_PREFIX)
  if(BRANCH_NAME_PREFIX STREQUAL "PR")
    set(BRANCH_NAME $ENV{CHANGE_BRANCH})
  endif()

  if(NOT DEFINED METRICS_RESULTS_DIR)
    message(FATAL_ERROR "Please define METRICS_RESULTS_DIR")
  endif()

  message("Adding ${component_name} metric with
          build_machine_arch: ${BUILD_MACHINE_ARCH} build_machine_id: ${BUILD_MACHINE_ID}
          commit_id: ${COMMIT_ID} author: ${AUTHOR} branch_name: ${BRANCH_NAME}")

  if(${ARGC} GREATER 5) # if executable path is provided.
    set(EXECUTABLE ${ARGV5})
  else()
    set(EXECUTABLE ${CMAKE_CURRENT_BINARY_DIR}/${target})
  endif()

  # named using target for uniqueness
  set(TARGET_PATH "${CMAKE_CURRENT_BINARY_DIR}/${target}.${component_name}.${metric_type}.${run_mode}.run")
  set(METRIC_RESULTS_PATH "${METRICS_RESULTS_DIR}/${target}.${component_name}.${metric_type}.${run_mode}.metric.json")

  set(extra_args ${ARGV4})

  # Write runner script to disk.
  file(WRITE ${TARGET_PATH} "#!/bin/bash
set -ex
${EXECUTABLE} \\
--save_on_end ${METRIC_RESULTS_PATH} \\
--author ${AUTHOR} \\
--commit_id ${COMMIT_ID} \\
--branch_name ${BRANCH_NAME} \\
--component_name ${component_name} \\
--metric_type ${metric_type} \\
--run_mode ${run_mode} \\
--build_machine_arch ${BUILD_MACHINE_ARCH} \\
--build_machine_id ${BUILD_MACHINE_ID} \\
${extra_args}"
    )
  # Makes this runner script executable for later usage
  execute_process(
    COMMAND chmod +x ${TARGET_PATH}
  )

endfunction()
