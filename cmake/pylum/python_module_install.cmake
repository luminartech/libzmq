function(python_module_install target pymdk_module_output_name output_path)

  if(NOT EXISTS ${output_path})
    message(FATAL_ERROR "Missing output directory: ${output_path}")
  endif()


  # pybind requires that the created target has the same name as the module.
  # The following are the important functions that pybind11_add_module carryout to make sure python module
  # is installed correctly:
  # 1) Make the output name of the target same as the name used to create the module in PYBIND11_MODULE
  set_target_properties(${PROJECT_NAME} PROPERTIES OUTPUT_NAME "${pymdk_module_output_name}")
  # 2) Do not have any prefix like "lib" to make sure it is same as the module name
  set_target_properties(${PROJECT_NAME} PROPERTIES PREFIX "")

  # set target path
  set(TARGET_PATH ${CMAKE_CURRENT_BINARY_DIR}/${pymdk_module_output_name}.so)

  # install module to the install path
  add_custom_command(
  TARGET ${PROJECT_NAME}
  POST_BUILD ${PROJECT_NAME}
  COMMAND cp ${TARGET_PATH} ${output_path}
  COMMENT "Installing python module. Copying module ${pymdk_module_output_name}.so to ${output_path}"
  )

endfunction()
