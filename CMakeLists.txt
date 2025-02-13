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

pico_sdk_init()

set(LF_MAIN_TARGET ${LF_MAIN})
add_executable(${LF_MAIN_TARGET})

include($ENV{REACTOR_UC_PATH}/cmake/lfc.cmake)

lf_setup()
lf_run_lfc(${CMAKE_CURRENT_SOURCE_DIR}/src ${LF_MAIN})
lf_build_generated_code(${LF_MAIN_TARGET} ${CMAKE_CURRENT_SOURCE_DIR}/src-gen/${LF_MAIN})

target_link_libraries(${LF_MAIN_TARGET} PUBLIC pico_stdlib pico_sync)
pico_enable_stdio_usb(${LF_MAIN_TARGET} 1)
pico_enable_stdio_uart(${LF_MAIN_TARGET} 1)