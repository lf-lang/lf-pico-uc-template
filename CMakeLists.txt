cmake_minimum_required(VERSION 3.20.0)
include(${CMAKE_CURRENT_SOURCE_DIR}/pico-sdk/pico_sdk_init.cmake)
project(reactor-uc-pico)
set(PLATFORM "PICO" CACHE STRING "Platform to target")

if (NOT DEFINED LF_MAIN)
  set(LF_MAIN "Blink")
endif()

if (NOT DEFINED LOG_LEVEL)
  set(LOG_LEVEL "LF_LOG_LEVEL_DEBUG")
endif()

pico_sdk_init()

if (NOT DEFINED FEDERATE)
  include(${CMAKE_CURRENT_SOURCE_DIR}/src-gen/${LF_MAIN}/CMakeLists.txt)
else()
  include(${CMAKE_CURRENT_SOURCE_DIR}/src-gen/${LF_MAIN}/${FEDERATE}/Include.cmake)
endif()

add_subdirectory($ENV{REACTOR_UC_PATH} ${CMAKE_CURRENT_BINARY_DIR}/reactor-uc)
target_compile_definitions(reactor-uc PUBLIC LF_LOG_LEVEL_ALL=${LOG_LEVEL})
target_compile_definitions(reactor-uc PUBLIC LF_LOG_LEVEL_PLATFORM=LF_LOG_LEVEL_WARN)
target_compile_definitions(reactor-uc PUBLIC LF_COLORIZE_LOGS=0)
target_compile_definitions(reactor-uc PUBLIC NETWORK_CHANNEL_UART)
target_compile_definitions(reactor-uc PUBLIC PLATFORM_PICO)

include($ENV{REACTOR_UC_PATH}/cmake/lfc.cmake)

lf_setup()
lf_run_lfc(${CMAKE_CURRENT_SOURCE_DIR}/src ${LF_MAIN})
lf_build_generated_code(${LF_MAIN_TARGET} ${CMAKE_CURRENT_SOURCE_DIR}/src-gen/${LF_MAIN})

target_link_libraries(${LF_MAIN_TARGET} PUBLIC pico_stdlib pico_sync)
pico_enable_stdio_usb(${LF_MAIN_TARGET} 1)
pico_enable_stdio_uart(${LF_MAIN_TARGET} 1)
