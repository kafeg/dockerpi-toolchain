# https://github.com/Pro/raspi-toolchain/blob/master/Toolchain-rpi.cmake
# https://github.com/Microsoft/vcpkg/issues/4401
# https://stackoverflow.com/questions/58777810/how-to-integrate-vcpkg-in-linux-with-cross-build-toolchain-as-well-as-sysroot



# RASPI ROOTFS should point to the local directory which contains all the libraries and includes from the target raspi.

# General params
set (RASPBERRY_VERSION RASPBERRY_VERSION_TPL)
set (SYSROOT_PATH SYSROOT_PATH_TPL)
set (TOOLCHAIN_DIR TOOLCHAIN_DIR_TPL)

message(STATUS "Using RasPi version:  ${RASPBERRY_VERSION}")
message(STATUS "Using sysroot path:   ${SYSROOT_PATH}")
message(STATUS "Using toolchain path: ${TOOLCHAIN_DIR}")

set(TOOLCHAIN_HOST "arm-linux-gnueabihf")
set(TOOLCHAIN_CC "${TOOLCHAIN_HOST}-gcc")
set(TOOLCHAIN_CXX "${TOOLCHAIN_HOST}-g++")
set(TOOLCHAIN_LD "${TOOLCHAIN_HOST}-ld")
set(TOOLCHAIN_AR "${TOOLCHAIN_HOST}-ar")
set(TOOLCHAIN_RANLIB "${TOOLCHAIN_HOST}-ranlib")
set(TOOLCHAIN_STRIP "${TOOLCHAIN_HOST}-strip")
set(TOOLCHAIN_NM "${TOOLCHAIN_HOST}-nm")

set(CMAKE_CROSSCOMPILING TRUE)
set(CMAKE_SYSROOT "${SYSROOT_PATH}")

# Define name of the target system
set(CMAKE_SYSTEM_NAME "Linux")
set (CMAKE_SYSTEM_VERSION 10)
if(RASPBERRY_VERSION VERSION_GREATER 2)
    set(CMAKE_SYSTEM_PROCESSOR "aarch64")
elseif(RASPBERRY_VERSION VERSION_GREATER 1)
    set(CMAKE_SYSTEM_PROCESSOR "armv7")
else()
    set(CMAKE_SYSTEM_PROCESSOR "arm")
endif()

# Define the compiler
set(CMAKE_C_COMPILER ${TOOLCHAIN_CC})
set(CMAKE_CXX_COMPILER ${TOOLCHAIN_CXX})

# List of library dirs where LD has to look. Pass them directly through gcc. LD_LIBRARY_PATH is not evaluated by arm-*-ld
set(LIB_DIRS 
    "${TOOLCHAIN_DIR}/arm-linux-gnueabihf/lib"
    "${TOOLCHAIN_DIR}/lib"
    "${SYSROOT_PATH}/opt/vc/lib"
    "${SYSROOT_PATH}/lib/${TOOLCHAIN_HOST}"
    "${SYSROOT_PATH}/usr/local/lib"
    "${SYSROOT_PATH}/usr/lib/${TOOLCHAIN_HOST}"
    "${SYSROOT_PATH}/usr/lib"
    "${SYSROOT_PATH}/usr/lib/${TOOLCHAIN_HOST}/blas"
    "${SYSROOT_PATH}/usr/lib/${TOOLCHAIN_HOST}/lapack"
)
# You can additionally check the linker paths if you add the flags ' -Xlinker --verbose'
set(COMMON_FLAGS "-I${SYSROOT_PATH}/usr/include -I${SYSROOT_PATH}/usr/include/arm-linux-gnueabihf ")
foreach(LIB ${LIB_DIRS})
    set(COMMON_FLAGS "${COMMON_FLAGS} -L${LIB} -Wl,-rpath-link,${LIB}")
endforeach()

set(CMAKE_PREFIX_PATH "${CMAKE_PREFIX_PATH};${SYSROOT_PATH}/usr/lib/${TOOLCHAIN_HOST}")

if(RASPBERRY_VERSION VERSION_GREATER 2)
    set(CMAKE_C_FLAGS "-mcpu=cortex-a53 -mfpu=neon-vfpv4 -mfloat-abi=hard ${COMMON_FLAGS}" CACHE STRING "Flags for Raspberry PI 3")
    set(CMAKE_CXX_FLAGS "${CMAKE_C_FLAGS}" CACHE STRING "Flags for Raspberry PI 3")
elseif(RASPBERRY_VERSION VERSION_GREATER 1)
    set(CMAKE_C_FLAGS "-mcpu=cortex-a7 -mfpu=neon-vfpv4 -mfloat-abi=hard ${COMMON_FLAGS}" CACHE STRING "Flags for Raspberry PI 2")
    set(CMAKE_CXX_FLAGS "${CMAKE_C_FLAGS}" CACHE STRING "Flags for Raspberry PI 2")
else()
    set(CMAKE_C_FLAGS "-mcpu=arm1176jzf-s -mfpu=vfp -mfloat-abi=hard ${COMMON_FLAGS}" CACHE STRING "Flags for Raspberry PI 1 B+ Zero")
    set(CMAKE_CXX_FLAGS "${CMAKE_C_FLAGS}" CACHE STRING "Flags for Raspberry PI 1 B+ Zero")
endif()

set(CMAKE_FIND_ROOT_PATH "${CMAKE_INSTALL_PREFIX};${CMAKE_PREFIX_PATH};${CMAKE_SYSROOT}")

# CMAKE_SYSROOT is cmake 3.0+ only
set (CMAKE_SYSROOT ${SYSROOT_PATH})
set (CMAKE_UNAME ${CMAKE_SYSROOT}/bin/uname)

# search for programs in the build host directories
set (CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
# for libraries and headers in the target directories
set (CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set (CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
set (CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)

# resetting pkg-config paths
set(ENV{PKG_CONFIG_DIR} "")
set(ENV{PKG_CONFIG_LIBDIR} "${CMAKE_SYSROOT}/usr/lib/pkgconfig:${CMAKE_SYSROOT}/usr/local/lib/pkgconfig:${CMAKE_SYSROOT}/usr/lib/aarch64-linux-gnu/pkgconfig:${CMAKE_SYSROOT}/usr/share/pkgconfig")
set(ENV{PKG_CONFIG_SYSROOT_DIR} ${CMAKE_SYSROOT})