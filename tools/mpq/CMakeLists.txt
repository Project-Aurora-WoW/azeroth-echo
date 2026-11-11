cmake_minimum_required(VERSION 3.20)
project(mpqcli CXX)

if (NOT DEFINED STORMLIB_SOURCE_DIR)
    set(STORMLIB_SOURCE_DIR "E:/tools/StormLib")
endif()

set(STORM_USE_BUNDLED_LIBRARIES ON CACHE BOOL "" FORCE)
set(STORM_BUILD_TESTS OFF CACHE BOOL "" FORCE)
add_subdirectory("${STORMLIB_SOURCE_DIR}" stormlib EXCLUDE_FROM_ALL)

add_executable(mpqcli mpqcli.cpp)
target_compile_definitions(mpqcli PRIVATE WDK_BUILD _CRT_SECURE_NO_WARNINGS)
set_target_properties(mpqcli PROPERTIES CXX_STANDARD 17 CXX_STANDARD_REQUIRED ON)
target_link_libraries(mpqcli PRIVATE storm)
