set(CMAKE_MODULE_PATH "${CMAKE_CURRENT_LIST_DIR}")

function(lumpdk_lib_install target internal)

  if(NOT EXISTS ${LUMINCAR_LIBS})
    message(FATAL_ERROR "LUMINCAR_LIBS Directory MISSING: ${LUMINCAR_LIBS}")
  endif()

  if(NOT EXISTS ${LUMPDK_LIBS})
    message(FATAL_ERROR "LUMPDK_LIBS Directory MISSING: ${LUMPDK_LIBS}")
  endif()

  if (UNIX)
    set(TARGET_PATH ${CMAKE_CURRENT_BINARY_DIR}/lib${target}.so)
  elseif (WIN32)
    set(TARGET_NAME ${target}.dll)
    set(TARGET_NAME_LIB ${target}.lib)

    set(TARGET_PATH ${CMAKE_CURRENT_BINARY_DIR}/$<CONFIG>/${TARGET_NAME})
    set(TARGET_PATH_LIB ${CMAKE_CURRENT_BINARY_DIR}/$<CONFIG/${TARGET_NAME_LIB})

    set(TARGET_PATH_DIR ${CMAKE_CURRENT_BINARY_DIR}/$<CONFIG>)
    set(EXTERNAL_BUILD_COPY_PATH ${LUMPDK_LIBS}/$<CONFIG>)
  endif()

  if(CMAKE_BUILD_TYPE MATCHES RELEASE)
    if (UNIX AND NOT QNXNTO)
      add_custom_command(
        TARGET ${target}
        POST_BUILD ${target}
        COMMAND strip --strip-all -R .note -R .comment ${TARGET_PATH}
        COMMENT "Stripping symbols of ${target}"
        )
    elseif (WIN32)
      message("TODO: consider stripping Windows builds")
    endif()
  endif()

  # TODO: do we need to support this sort of internal build on Windows?
  # TODO: also, qnx? probably more so
  if(${internal} STREQUAL "internal_future")
    target_compile_definitions(${target}
      PRIVATE
      -DLUM_PDK_BUILD_INTERNAL=1
      -DLUM_PDK_BUILD_INTERNAL_FUTURE=1
      -DBUILD_TYPE_RELEASE=${BUILD_TYPE_RELEASE}
      )

    add_custom_command(
      TARGET ${target}
      POST_BUILD ${target}
      COMMAND cp ${TARGET_PATH} ${LUMINCAR_LIBS}
      COMMENT "Copying lib${target}.so to ${LUMINCAR_LIBS}"
      )
  elseif(${internal} STREQUAL "internal")
    target_compile_definitions(${target}
      PRIVATE
      -DLUM_PDK_BUILD_INTERNAL=1
      -DLUM_PDK_BUILD_INTERNAL_FUTURE=0
      -DBUILD_TYPE_RELEASE=${BUILD_TYPE_RELEASE}
      )

    if (WIN32)
      message(STATUS "Copying ${TARGET_PATH_DIR} to ${EXTERNAL_BUILD_COPY_PATH}")

      add_custom_command(
        TARGET ${PROJECT_NAME} POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E copy_directory
        ${TARGET_PATH_DIR}
        ${EXTERNAL_BUILD_COPY_PATH}
      )
    elseif(UNIX)
      add_custom_command(
        TARGET ${target}
        POST_BUILD ${target}
        COMMAND cp ${TARGET_PATH} ${LUMINCAR_LIBS}
        COMMENT "Copying lib${target}.so to ${LUMINCAR_LIBS}"
        )
    endif()
  else()
    target_compile_definitions(${target}
      PRIVATE
      -DLUM_PDK_BUILD_INTERNAL=0
      -DLUM_PDK_BUILD_INTERNAL_FUTURE=0
      -DBUILD_TYPE_RELEASE=${BUILD_TYPE_RELEASE}
      )

    if (WIN32)
      message(STATUS "Copying ${TARGET_PATH_DIR} to ${EXTERNAL_BUILD_COPY_PATH}")

      add_custom_command(
        TARGET ${PROJECT_NAME} POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E copy_directory
        ${TARGET_PATH_DIR}
        ${EXTERNAL_BUILD_COPY_PATH}
      )
    elseif(UNIX)
      add_custom_command(
        TARGET ${target}
        POST_BUILD ${target}
        COMMAND cp ${TARGET_PATH} ${LUMPDK_LIBS}
        COMMENT "Copying lib${target}.so to ${LUMPDK_LIBS}"
        )
    endif()
  endif()
endfunction()

function(ecu_target_install target internal)
  if(NOT EXISTS ${ECU_NODES})
    file(MAKE_DIRECTORY ${ECU_NODES})
  endif()

  set(TARGET_PATH ${CMAKE_CURRENT_BINARY_DIR}/${target})

  add_custom_command(
    TARGET ${target}
    POST_BUILD ${target}
    COMMAND cp ${TARGET_PATH} ${ECU_NODES}
    COMMENT "Copying ${target} to ${ECU_NODES}"
    )
endfunction()

macro(lum_add_test name)
  add_test(${name} ${name})
  set_tests_properties(${name} PROPERTIES ENVIRONMENT "PATH=${LUMPDK_LIBS}/Release;$ENV{PATH}" )
endmacro()

macro(lum_disable_test name)
    set_tests_properties(${name} PROPERTIES DISABLED 1)
endmacro()