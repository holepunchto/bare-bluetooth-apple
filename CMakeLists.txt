cmake_minimum_required(VERSION 4.0)

find_package(cmake-bare REQUIRED PATHS node_modules/cmake-bare)

project(bare_bluetooth_apple C OBJC)

add_bare_module(bare_bluetooth_apple)

target_sources(
  ${bare_bluetooth_apple}
  PRIVATE
    binding.m
)

target_link_libraries(
  ${bare_bluetooth_apple}
  PUBLIC
    "-framework CoreBluetooth"
)
