# TODO: be nice if we could aggregate these from the toolchain files
set(LUMPDK_SUPPORTED_TARGET_TRIPLES "x86_64_linux_gcc" "aarch64_linux_gcc" "x86_64_windows10_msvc")
set(LUMPDK_SUPPORTED_UNIX_TARGET_TRIPLES "x86_64_linux_gcc" "aarch64_linux_gcc")
set(LUMPDK_SUPPORTED_WINDOWS_TARGET_TRIPLES "x86_64_windows10_msvc")
set(LUMPDK_SUPPORTED_QNX_TARGET_TRIPLES "aarch64_qnx_gcc")

macro(verify_supported_platform)

if (NOT (DEFINED LUMPDK_TARGET_TRIPLET))
  message(FATAL_ERROR "LumPDK target triplet not set, here's what cmake knows about the current platform: ${CMAKE_SYSTEM_NAME} / ${CMAKE_SYSTEM_PROCESSOR}")
else()
  message("LumPDK target triplet: ${LUMPDK_TARGET_TRIPLET}")
endif()
endmacro()

function(check_project_supports_target_triple triples supported)
    if (${LUMPDK_TARGET_TRIPLET} IN_LIST triples)
        set(${supported} 1 PARENT_SCOPE)
    else()
        set(${supported} 0 PARENT_SCOPE)
    endif()
endfunction()

macro(skip_if_target_triple_not_supported proj triples)
    set(supported 0)

    check_project_supports_target_triple("${triples}" supported)

    if(NOT ${supported})
        message("${proj} does not support ${LUMPDK_TARGET_TRIPLET}, skipping configuration!")
        return()
    endif()
endmacro()

function(configure_default_project name)

  target_include_directories(${name}
      PRIVATE
      ${LUMPDK_INCLUDE}
      ${LUMPDK_THIRD_PARTY}
  )

  if (WIN32)
    configure_default_windows_project(${name})
  elseif(UNIX AND NOT APPLE)
    configure_default_linux_project(${name})
  else()
    message(FATAL_ERROR "Unknown platform, unable to configure default project")
  endif()
endfunction()

function(configure_default_linux_project name)

  set_property(TARGET ${name} PROPERTY LINKER_LANGUAGE CXX)

  # This doesn't seem to work on QNX, maybe a bug in cmake; down below we explicitly set the version as a compiler option
  set(CMAKE_CXX_STANDARD 14)
  set(CMAKE_CXX_STANDARD_REQUIRED ON)
  set(CMAKE_CXX_EXTENSIONS OFF)

  target_compile_options(${name}
    PRIVATE
    -Wall -Wextra -Wpedantic -Werror -Wcast-align
  )

  if (QNXNTO)

    # Noting here that even though qnx uses gcc/g++, by default it uses llvm's c++ stdlib
    target_compile_options(${name}
      PRIVATE
      -Wno-attributes -std=c++${CMAKE_CXX_STANDARD}
    )

    target_compile_definitions(${name} PRIVATE _QNX_SOURCE)
  endif(QNXNTO)

endfunction()

function(configure_default_windows_project name)
message("Configuring Windows for ${name}")
    macro(get_WIN32_WINNT version)
        if(CMAKE_SYSTEM_VERSION)
            set(ver ${CMAKE_SYSTEM_VERSION})
            string(REGEX MATCH "^([0-9]+).([0-9])" ver ${ver})
            string(REGEX MATCH "^([0-9]+)" verMajor ${ver})
            # Check for Windows 10, b/c we'll need to convert to hex 'A'.
            if("${verMajor}" MATCHES "10")
                set(verMajor "A")
                string(REGEX REPLACE "^([0-9]+)" ${verMajor} ver ${ver})
            endif()
            # Remove all remaining '.' characters.
            string(REPLACE "." "" ver ${ver})
            # Prepend each digit with a zero.
            string(REGEX REPLACE "([0-9A-Z])" "0\\1" ver ${ver})
            set(${version} "0x${ver}")
        endif()
    endmacro()

    get_WIN32_WINNT(ver)
    add_definitions(-D_WIN32_WINNT=${ver})

    target_compile_definitions(${name}
        PUBLIC
            -DBUILDING_DLL=1
            -D_SCL_SECURE_NO_WARNINGS=1
            -D_CRT_SECURE_NO_WARNINGS=1
            -D_WIN32_WINNT=${ver}
            -DNOMINMAX)

    if ("${CMAKE_CXX_COMPILER_ID}" STREQUAL "MSVC")
        target_compile_options(${name}
            PRIVATE
                /MP         # Parallel building
                /Zo         # Enhance optimized debugging
                /W4
                /bigobj
        )

        # Reduce RelWithDebInfo executable bloat
        # set_target_properties(${name} PROPERTIES
            # LINK_FLAGS_RELWITHDEBINFO "/OPT:REF /OPT:ICF /INCREMENTAL:NO")

        # # Debugging helpers
        # configure_file(${CMAKE_SOURCE_DIR}/scripts/Microsoft.Cpp.x64.user.props.in
            # ${CMAKE_BINARY_DIR}/Microsoft.Cpp.x64.user.props)
        # set_target_properties(${name} PROPERTIES
            # VS_USER_PROPS ${CMAKE_BINARY_DIR}/Microsoft.Cpp.x64.user.props)
        # set_target_properties(${name} PROPERTIES
            # VS_DEBUGGER_WORKING_DIRECTORY "${CMAKE_SOURCE_DIR}/bin")
        # set_property(DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR} PROPERTY
            # VS_STARTUP_PROJECT ${name})

        set_target_properties(${name} PROPERTIES
            VS_DEBUGGER_WORKING_DIRECTORY "${LUMPDK_LIBS}/$<CONFIG>")
    endif("${CMAKE_CXX_COMPILER_ID}" STREQUAL "MSVC")
endfunction()
