cmake_minimum_required(VERSION 4.0)

find_package(cmake-bare REQUIRED PATHS node_modules/cmake-bare)
find_package(cmake-fetch REQUIRED PATHS node_modules/cmake-fetch)
find_package(cmake-harden REQUIRED PATHS node_modules/cmake-harden)

project(bare_bluetooth_apple CXX OBJC)

fetch_package("github:holepunchto/libjstl#6b78e1e")

add_bare_module(bare_bluetooth_apple)

harden(${bare_bluetooth_apple})

target_sources(
  ${bare_bluetooth_apple}
  PRIVATE
    binding.mm
)

target_link_libraries(
  ${bare_bluetooth_apple}
  PUBLIC
    "-framework CoreBluetooth"
  PRIVATE
    jstl
)
