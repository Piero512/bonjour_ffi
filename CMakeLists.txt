cmake_minimum_required(VERSION 3.10)
project(async_tests C CXX)
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} "${CMAKE_SOURCE_DIR}/cmake/")
configure_file(CMakeLists.txt.in libuv-download/CMakeLists.txt)

execute_process(COMMAND "${CMAKE_COMMAND}"  .
        WORKING_DIRECTORY "${CMAKE_BINARY_DIR}/libuv-download"
        )
execute_process(COMMAND "${CMAKE_COMMAND}" --build . --config=Release
        WORKING_DIRECTORY "${CMAKE_BINARY_DIR}/libuv-download"
        )

execute_process(COMMAND "${CMAKE_COMMAND}" --install .  --prefix=${CMAKE_BINARY_DIR}/libuv-install --config=Release
        WORKING_DIRECTORY "${CMAKE_BINARY_DIR}/libuv-download"
        )
# Download JSON
include(FetchContent)

FetchContent_Declare(json URL https://github.com/nlohmann/json/releases/download/v3.10.5/json.tar.xz)
FetchContent_MakeAvailable(json)



add_library(ffi_test SHARED src/msgport_adapter.cpp src/msgport_adapter.h src/dart_headers/dart_api_dl.c)


find_package(Threads REQUIRED)
find_package(libuv
        CONFIG
        REQUIRED
        COMPONENTS uv uv_a
        HINTS ${CMAKE_CURRENT_BINARY_DIR}/libuv-install/)
include_directories(${CMAKE_CURRENT_BINARY_DIR}/libuv-install/include)
find_package(Bonjour REQUIRED)
target_link_libraries(ffi_test Threads::Threads uv_a nlohmann_json::nlohmann_json ${BONJOUR_LIBRARIES})
