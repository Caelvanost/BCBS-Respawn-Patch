cmake_minimum_required(VERSION 3.24)

# The universal CommonLib build is linked statically so the released SKSE DLL
# does not require extra vcpkg runtime DLLs.
if(NOT DEFINED CMAKE_MSVC_RUNTIME_LIBRARY)
    set(CMAKE_MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>")
endif()
if(NOT DEFINED VCPKG_TARGET_TRIPLET)
    set(VCPKG_TARGET_TRIPLET "x64-windows-static" CACHE STRING "")
endif()

file(READ "${CMAKE_CURRENT_SOURCE_DIR}/VERSION" BCBS_VERSION)
string(STRIP "${BCBS_VERSION}" BCBS_VERSION)

project(
    BCBSRespawnPatch
    VERSION ${BCBS_VERSION}
    LANGUAGES CXX
)

set(CMAKE_CXX_STANDARD 23)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

include(FetchContent)

# Pin the MIT CommonLibSSE-NG universal-runtime fork to a known revision.
# This revision supports Address Library formats 2 (Skyrim 1.6.x) and 5
# (Skyrim 1.7.x), including runtime constants for 1.6.1170 and 1.7.104.
set(FETCHCONTENT_BASE_DIR "${CMAKE_CURRENT_SOURCE_DIR}/.deps" CACHE PATH "FetchContent dependency cache")
set(BCBS_COMMONLIB_REPOSITORY "https://github.com/Zzyxz/CommonLibSSE-NG.git" CACHE STRING "Universal CommonLibSSE-NG repository")
set(BCBS_COMMONLIB_TAG "6fcfb68af0870e345a3656ac6da371a694fdb374" CACHE STRING "Pinned universal CommonLibSSE-NG revision")

FetchContent_Declare(
    commonlibsse_universal
    GIT_REPOSITORY ${BCBS_COMMONLIB_REPOSITORY}
    GIT_TAG ${BCBS_COMMONLIB_TAG}
    GIT_SHALLOW FALSE
)

FetchContent_GetProperties(commonlibsse_universal)
if(NOT commonlibsse_universal_POPULATED)
    FetchContent_Populate(commonlibsse_universal)
endif()

# Skyrim 1.6.x and 1.7.x are both AE-family runtimes. We intentionally do not
# enable 1.5.97 or VR in this build.
set(BUILD_TESTS OFF CACHE BOOL "" FORCE)
set(ENABLE_SKYRIM_SE OFF CACHE BOOL "" FORCE)
set(ENABLE_SKYRIM_AE ON CACHE BOOL "" FORCE)
set(ENABLE_SKYRIM_VR OFF CACHE BOOL "" FORCE)

add_subdirectory(
    "${commonlibsse_universal_SOURCE_DIR}/extern/CommonLibSSE"
    "${CMAKE_BINARY_DIR}/CommonLibSSE"
)

add_library(${PROJECT_NAME} SHARED
    src/PCH.h
    src/main.cpp
)

target_precompile_headers(${PROJECT_NAME}
    PRIVATE
        src/PCH.h
)

target_link_libraries(${PROJECT_NAME}
    PRIVATE
        CommonLibSSE::CommonLibSSE
)

target_compile_options(${PROJECT_NAME}
    PRIVATE
        /utf-8
)

target_compile_definitions(${PROJECT_NAME}
    PRIVATE
        WIN32_LEAN_AND_MEAN
        NOMINMAX
        BCBS_PLUGIN_NAME="BCBS Respawn Patch"
        BCBS_PLUGIN_AUTHOR="Caelvanost"
        BCBS_PLUGIN_VERSION_MAJOR=${PROJECT_VERSION_MAJOR}
        BCBS_PLUGIN_VERSION_MINOR=${PROJECT_VERSION_MINOR}
        BCBS_PLUGIN_VERSION_PATCH=${PROJECT_VERSION_PATCH}
)
