cmake_minimum_required(VERSION 3.20.0)
include(${CMAKE_CURRENT_SOURCE_DIR}/pico-sdk/pico_sdk_init.cmake)
project(reactor-uc-pico)
set(PLATFORM "PICO" CACHE STRING "Platform to target")

if (NOT DEFINED LF_MAIN)
  set(LF_MAIN "Blink")
endif()

if (NOT DEFINED LOG_LEVEL)
  set(LOG_LEVEL "LF_LOG_LEVEL_WARN")
endif()

# Run LFC
set(LFC_COMMAND $ENV{REACTOR_UC_PATH}/lfc/bin/lfc-dev ${CMAKE_CURRENT_SOURCE_DIR}/src/${LF_MAIN}.lf)
execute_process(COMMAND echo "Running LFC: ${LFC_COMMAND}")
execute_process(
    COMMAND ${LFC_COMMAND}
    ECHO_OUTPUT_VARIABLE
    COMMAND_ERROR_IS_FATAL ANY
)

file(GLOB_RECURSE LF_SOURCES ${CMAKE_CURRENT_SOURCE_DIR}/src/*.lf)
set_property(DIRECTORY APPEND PROPERTY CMAKE_CONFIGURE_DEPENDS ${LF_SOURCES})
message(STATUS "Found LF sources: ${LF_SOURCES}")

pico_sdk_init()

include(src-gen/${LF_MAIN}/CMakeLists.txt)
add_subdirectory(${REACTOR_UC_PATH})
target_compile_definitions(reactor-uc PUBLIC LF_LOG_LEVEL_ALL=${LOG_LEVEL})

add_executable(${LF_MAIN} ${LFC_GEN_MAIN} ${LFC_GEN_SOURCES})
target_include_directories(${LF_MAIN} PRIVATE ${LFC_GEN_INCLUDE_DIRS})
target_link_libraries(${LF_MAIN} PUBLIC reactor-uc)
target_link_libraries(${LF_MAIN} PUBLIC pico_stdlib pico_sync)

pico_enable_stdio_usb(${LF_MAIN} 1)
pico_enable_stdio_uart(${LF_MAIN} 1)