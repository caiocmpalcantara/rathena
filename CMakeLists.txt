#####################################################################
#
# "Getting Started with CMake", a tutorial video by Eric Wing.
#   Part 1 of 6: http://www.youtube.com/watch?v=CLvZTyji_Uw
#   Part 2 of 6: http://www.youtube.com/watch?v=gUW-RrRQjEg
#   Part 3 of 6: http://www.youtube.com/watch?v=sz6cPhbuTk4
#   Part 4 of 6: http://www.youtube.com/watch?v=JICZOkyNXbg
#   Part 5 of 6: http://www.youtube.com/watch?v=lAiuLHy4dCk
#   Part 6 of 6: http://www.youtube.com/watch?v=fAtJNzDZdH8
#
# You can use notepad++ for syntax highlighting.
# Naming conventions:
#   WITH_*   : option to use an external package or not
#   ENABLE_* : option to use an internal feature/code or not
#   HAVE_*   : internal variable indicating if we have and are using something
#
# Maintainers: Flavio J. Saraiva (feel free to send complaints or suggestions)
#   flaviojs @ rAthena forum/irc
#   flaviojs2005 \A-T/ gmail <D.o,T> com
#   lightaisme \A-T/ gmail <D.o,T> com
#
#####################################################################


set( CMAKE_LEGACY_CYGWIN_WIN32 0 )
cmake_minimum_required( VERSION 3.13 )
project( rAthena )
if( CYGWIN )
	unset( WIN32 )
endif()
set(CMAKE_CXX_STANDARD 17) # C++17...
set(CMAKE_CXX_STANDARD_REQUIRED ON) #...is required...
#set(CMAKE_CXX_EXTENSIONS OFF) #...without compiler extensions like gnu++11

#actually this might be misleading for arm...
if( CMAKE_SIZEOF_VOID_P EQUAL 4 )
	set(architecture x86)
elseif( CMAKE_SIZEOF_VOID_P EQUAL 8 )
	set(architecture x64)
else()
	message( FATAL_ERROR "unexpected architecture (CMAKE_SIZEOF_VOID_P is ${CMAKE_SIZEOF_VOID_P})" )
endif()

set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/lib/${suffixInstallStr})
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/lib/${suffixInstallStr})
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR})
set(CMAKE_C_CREATE_SHARED_LIBRARY)
set(CMAKE_CXX_CREATE_SHARED_LIBRARY)
set(CMAKE_DEBUG_POSTFIX "d")
set(CMAKE_RELEASE_POSTFIX "r")

# Set a default build type if none was specified
set(default_build_type "Release")
if(NOT CMAKE_BUILD_TYPE AND NOT CMAKE_CONFIGURATION_TYPES)
  message(STATUS "Setting build type to '${default_build_type}' as none was specified.")
  set(CMAKE_BUILD_TYPE "${default_build_type}" CACHE
      STRING "Choose the type of build." FORCE)
  # Set the possible values of build type for cmake-gui
  set_property(CACHE CMAKE_BUILD_TYPE PROPERTY STRINGS
    "Debug" "Release" "MinSizeRel" "RelWithDebInfo")
endif()

#
# Prevent building in the source directory by default
#
option( ALLOW_SAME_DIRECTORY "Allow CMake to build in the source directory." OFF )
if( ALLOW_SAME_DIRECTORY )
elseif( "${CMAKE_CURRENT_SOURCE_DIR}" STREQUAL "${CMAKE_CURRENT_BINARY_DIR}" )
	message( FATAL_ERROR
		"Do not use the source directory to build your files, instead delete CMakeCache.txt, create a separate folder and build there.\n"
		"Example: (build in subdir 'build' and install to source dir)\n"
		"  rm -f CMakeCache.txt\n"
		"  mkdir build\n"
		"  cd build\n"
		"  cmake -G\"Unix Makefiles\" -DINSTALL_TO_SOURCE=ON -DCMAKE_BUILD_TYPE=RelWithDebInfo ..\n"
		"  make install\n"
		"  cd ..\n"
		"  rm -rf build\n"
		"To skip this check, set ALLOW_SAME_DIRECTORY to ON (-DALLOW_SAME_DIRECTORY=ON)" )
endif()


#
# Multi-threaded compilation support
#
# Include ProcessorCount module early
include(ProcessorCount)

option( ENABLE_PARALLEL_BUILD "Enable parallel compilation support (default=ON)" ON )
set( PARALLEL_BUILD_JOBS "0" CACHE STRING "Number of parallel build jobs (0=auto-detect, default=0)" )

if( ENABLE_PARALLEL_BUILD )
	# Auto-detect number of CPU cores if not specified
	if( PARALLEL_BUILD_JOBS EQUAL 0 )
		ProcessorCount(N)
		if( NOT N EQUAL 0 )
			set( PARALLEL_BUILD_JOBS ${N} CACHE STRING "Number of parallel build jobs (0=auto-detect, default=0)" FORCE )
			message( STATUS "Auto-detected ${N} CPU cores for parallel compilation" )
		else()
			set( PARALLEL_BUILD_JOBS 4 CACHE STRING "Number of parallel build jobs (0=auto-detect, default=0)" FORCE )
			message( STATUS "Could not detect CPU cores, defaulting to 4 parallel jobs" )
		endif()
	else()
		message( STATUS "Using ${PARALLEL_BUILD_JOBS} parallel build jobs" )
	endif()

	# Set parallel build properties for different generators
	if( CMAKE_GENERATOR MATCHES "Visual Studio" )
		# For Visual Studio, set the /MP flag for parallel compilation
		set( CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} /MP${PARALLEL_BUILD_JOBS}" )
		set( CMAKE_C_FLAGS "${CMAKE_C_FLAGS} /MP${PARALLEL_BUILD_JOBS}" )
		message( STATUS "Enabled Visual Studio parallel compilation with ${PARALLEL_BUILD_JOBS} jobs" )
	elseif( CMAKE_GENERATOR MATCHES "Makefiles" OR CMAKE_GENERATOR MATCHES "Ninja" )
		# For Make and Ninja generators, parallel builds are controlled at build time
		message( STATUS "Parallel compilation enabled. Use: cmake --build . -j${PARALLEL_BUILD_JOBS}" )
	endif()

	# Set global property to enable parallel builds
	set_property( GLOBAL PROPERTY JOB_POOLS compile_pool=${PARALLEL_BUILD_JOBS} )

	# Export parallel build variables for subdirectories
	set( PARALLEL_BUILD_JOBS ${PARALLEL_BUILD_JOBS} CACHE INTERNAL "Parallel build jobs for subdirectories" )
else()
	message( STATUS "Parallel compilation disabled" )
endif()


#
# Global stuff
#
set( GLOBAL_LIBRARIES ${LINK_LIBRARIES}  CACHE INTERNAL "" )# list (comma separated values)
set( GLOBAL_INCLUDE_DIRS ${INCLUDE_DIRECTORIES}  CACHE INTERNAL "" )# list (comma separated values)
set( GLOBAL_DEFINITIONS ${COMPILE_DEFINITIONS}  CACHE INTERNAL "" )# string (space separated values -DFOO=bar)
mark_as_advanced( GLOBAL_LIBRARIES  GLOBAL_INCLUDE_DIRS  GLOBAL_DEFINITIONS )
if( WIN32 )
	set_property( CACHE GLOBAL_DEFINITIONS  PROPERTY VALUE "${GLOBAL_DEFINITIONS} -DFD_SETSIZE=4096" )
endif()
if( MSVC )
	set_property( CACHE GLOBAL_LIBRARIES    PROPERTY VALUE ${GLOBAL_LIBRARIES} "oldnames.lib" "ws2_32.lib" )
	set_property( CACHE GLOBAL_DEFINITIONS  PROPERTY VALUE "${GLOBAL_DEFINITIONS} -D_CRT_SECURE_NO_DEPRECATE -D_CRT_NONSTDC_NO_DEPRECATE" )
endif()
if(CMAKE_COMPILER_IS_GNUCXX OR CMAKE_COMPILER_IS_GNUCC)
  set_property( CACHE GLOBAL_DEFINITIONS  PROPERTY VALUE "${GLOBAL_DEFINITIONS} -fno-strict-aliasing" )
  #set_property( CACHE GLOBAL_DEFINITIONS  PROPERTY VALUE "${GLOBAL_DEFINITIONS} -O2" ); #need more test to enable this
endif()

# Parallel build optimizations
if( ENABLE_PARALLEL_BUILD )
	# Enable parallel compilation for GCC/Clang
	if( CMAKE_COMPILER_IS_GNUCXX OR CMAKE_CXX_COMPILER_ID MATCHES "Clang" )
		# Use ccache if available for faster rebuilds
		find_program( CCACHE_PROGRAM ccache )
		if( CCACHE_PROGRAM )
			set_property( GLOBAL PROPERTY RULE_LAUNCH_COMPILE "${CCACHE_PROGRAM}" )
			message( STATUS "Found ccache: ${CCACHE_PROGRAM} - enabling for faster rebuilds" )
		endif()

		# Enable parallel linking if supported (gold linker or lld)
		if( CMAKE_CXX_COMPILER_ID MATCHES "GNU" )
			execute_process( COMMAND ${CMAKE_CXX_COMPILER} -fuse-ld=gold -Wl,--version ERROR_QUIET OUTPUT_VARIABLE LD_VERSION )
			if( "${LD_VERSION}" MATCHES "GNU gold" )
				set( CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -fuse-ld=gold" )
				set( CMAKE_SHARED_LINKER_FLAGS "${CMAKE_SHARED_LINKER_FLAGS} -fuse-ld=gold" )
				message( STATUS "Using GNU gold linker for faster linking" )
			endif()
		elseif( CMAKE_CXX_COMPILER_ID MATCHES "Clang" )
			execute_process( COMMAND ${CMAKE_CXX_COMPILER} -fuse-ld=lld -Wl,--version ERROR_QUIET OUTPUT_VARIABLE LD_VERSION )
			if( "${LD_VERSION}" MATCHES "LLD" )
				set( CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -fuse-ld=lld" )
				set( CMAKE_SHARED_LINKER_FLAGS "${CMAKE_SHARED_LINKER_FLAGS} -fuse-ld=lld" )
				message( STATUS "Using LLVM lld linker for faster linking" )
			endif()
		endif()
	endif()
endif()


#
# 3rd party
#
set( CMAKE_MODULE_PATH ${CMAKE_CURRENT_SOURCE_DIR}/3rdparty/cmake  CACHE INTERNAL "" )
include( CheckCSourceCompiles )
include( CheckCSourceRuns )
include( CheckIncludeFile )
include( CheckFunctionExists )
include( FindFunctionLibrary )
include( TestBigEndian )


#
# PACKETVER
#
set( PACKETVER CACHE STRING "Sets the PACKETVER define of the servers. (see src/common/mmo.h)" )
if( PACKETVER )
	set_property( CACHE GLOBAL_DEFINITIONS  PROPERTY VALUE "${GLOBAL_DEFINITIONS} -DPACKETVER=${PACKETVER}" )
	message( STATUS "Set packet version: ${PACKETVER}" )
endif()

#
# rAthena Configure Options Compatibility Layer
# This section provides CMake equivalents for traditional autotools configure options
#

# Game mode options
option( ENABLE_RENEWAL "Enable renewal mode (default=ON)" ON )
option( ENABLE_PRERE "Enable pre-renewal mode (default=OFF)" OFF )

# Validate game mode options (mutually exclusive)
if( ENABLE_RENEWAL AND ENABLE_PRERE )
	message( FATAL_ERROR "Cannot enable both renewal and pre-renewal modes. Choose one." )
endif()

if( ENABLE_PRERE )
	set_property( CACHE GLOBAL_DEFINITIONS  PROPERTY VALUE "${GLOBAL_DEFINITIONS} -DPRERE" )
	message( STATUS "Enabled pre-renewal mode" )
elseif( ENABLE_RENEWAL )
	# Renewal is the default, so we don't need to define anything special
	# The source code's renewal.hpp will handle the default RENEWAL definition
	message( STATUS "Enabled renewal mode (default)" )
endif()

# VIP features
option( ENABLE_VIP "Enable VIP features (default=OFF)" OFF )
if( ENABLE_VIP )
	set_property( CACHE GLOBAL_DEFINITIONS  PROPERTY VALUE "${GLOBAL_DEFINITIONS} -DVIP_ENABLE" )
	message( STATUS "Enabled VIP features" )
endif()

# Warning flags
option( ENABLE_WARN "Enable compiler warnings (default=OFF)" OFF )
if( ENABLE_WARN )
	if( CMAKE_C_COMPILER_ID STREQUAL "GNU" OR CMAKE_C_COMPILER_ID STREQUAL "Clang" )
		set_property( CACHE CMAKE_C_FLAGS  PROPERTY VALUE "${CMAKE_C_FLAGS} -Wall -Wextra" )
		set_property( CACHE CMAKE_CXX_FLAGS  PROPERTY VALUE "${CMAKE_CXX_FLAGS} -Wall -Wextra" )
		message( STATUS "Enabled compiler warnings" )
	endif()
endif()

# Maximum connections
set( MAXCONN CACHE STRING "Maximum connections (default=16384)" )
if( MAXCONN )
	set_property( CACHE GLOBAL_DEFINITIONS  PROPERTY VALUE "${GLOBAL_DEFINITIONS} -DFD_SETSIZE=${MAXCONN}" )
	message( STATUS "Set maximum connections to ${MAXCONN}" )
endif()

# Output executable names
set( OUTPUT_LOGIN "login-server" CACHE STRING "Login server executable name (default=login-server)" )
set( OUTPUT_CHAR "char-server" CACHE STRING "Char server executable name (default=char-server)" )
set( OUTPUT_MAP "map-server" CACHE STRING "Map server executable name (default=map-server)" )
set( OUTPUT_WEB "web-server" CACHE STRING "Web server executable name (default=web-server)" )


#
# Find git
#
message( STATUS "Detecting git" )
find_package(Git)
if(GIT_FOUND)
	if(GIT_VERSION_STRING)
		message(STATUS "Found git : ${GIT_EXECUTABLE} version (${GIT_VERSION_STRING})")
	else()
		message(STATUS "Found git : ${GIT_EXECUTABLE}")
	endif()
endif()

include(GetGitVersion)
get_git_version()

#include(GetSvnVersion)
#get_svn_version(SVN_VERSION)
#message( STATUS "SVN_VERSION: ${SVN_VERSION}" )


#
# threads
#
message( STATUS "Detecting threads library" )
set( CMAKE_THREAD_PREFER_PTHREAD 1 )
find_package(Threads REQUIRED)
if( CMAKE_THREAD_LIBS_INIT )
	message( STATUS "Adding global library: ${CMAKE_THREAD_LIBS_INIT}" )
	set_property( CACHE GLOBAL_LIBRARIES  PROPERTY VALUE ${GLOBAL_LIBRARIES} ${CMAKE_THREAD_LIBS_INIT} )
endif()
message( STATUS "Detecting threads library - done" )

message( STATUS "Check if supporting Thread local storage (TLS)" )
file( READ "${CMAKE_SOURCE_DIR}/3rdparty/cmake/tests/HAVE_TLS.c" _SOURCE )
CHECK_C_SOURCE_RUNS( "${_SOURCE}" HAVE_TLS )
if( HAVE_TLS )
	message( STATUS "Check for TLS- yes" )
	set_property( CACHE GLOBAL_DEFINITIONS  PROPERTY VALUE "${GLOBAL_DEFINITIONS} -DHAVE_TLS" )
else()
	message( STATUS "Check for TLS - no" )
endif()


#
# math library (FreeBSD/Linux/Solaris)
#
if( NOT WIN32 )
message( STATUS "Detecting math library (m)" )
CHECK_INCLUDE_FILE( math.h HAVE_MATH_H )
if( NOT HAVE_MATH_H )
	message( FATAL_ERROR "math.h not found" )
endif()
set( CMAKE_REQUIRED_LIBRARIES ${GLOBAL_LIBRARIES} )
find_function_library( floor FUNCTION_FLOOR_LIBRARIES m )
if( FUNCTION_FLOOR_LIBRARIES )
	message( STATUS "Adding global library: ${FUNCTION_FLOOR_LIBRARIES}" )
	set_property( CACHE GLOBAL_LIBRARIES  PROPERTY VALUE ${GLOBAL_LIBRARIES} ${FUNCTION_FLOOR_LIBRARIES} )
endif()
message( STATUS "Detecting math library (m) - done" )
endif()


#
# dynamic loading library (Linux)
#
if( NOT WIN32 )
message( STATUS "Detecting dynamic loading library (dl)" )
set( CMAKE_REQUIRED_LIBRARIES ${GLOBAL_LIBRARIES} )
find_function_library( dlopen FUNCTION_DLOPEN_LIBRARIES dl )
if( FUNCTION_DLOPEN_LIBRARIES )
	message( STATUS "Adding global library: ${FUNCTION_DLOPEN_LIBRARIES}" )
	set_property( CACHE GLOBAL_LIBRARIES  PROPERTY VALUE ${GLOBAL_LIBRARIES} ${FUNCTION_DLOPEN_LIBRARIES} )
endif()
message( STATUS "Detecting dynamic loading library (dl) - done" )
endif()


#
# networking library (Solaris/MinGW)
#
if( NOT MSVC )
message( STATUS "Detecting networking library (socket/nsl/ws2_32)" )
#set( CMAKE_REQUIRED_LIBRARIES ${GLOBAL_LIBRARIES} )
#find_function_library( bind FUNCTION_BIND_LIBRARIES socket ws2_32 )
#if( FUNCTION_BIND_LIBRARIES )
#	message( STATUS "Adding global library: ${FUNCTION_BIND_LIBRARIES}" )
#	set_property( CACHE GLOBAL_LIBRARIES  PROPERTY VALUE ${GLOBAL_LIBRARIES} ${FUNCTION_BIND_LIBRARIES} )
#endif()
set( CMAKE_REQUIRED_LIBRARIES ${GLOBAL_LIBRARIES} )
find_function_library( gethostbyname FUNCTION_GETHOSTBYNAME_LIBRARIES nsl )
if( FUNCTION_GETHOSTBYNAME_LIBRARIES )
	message( STATUS "Adding global library: ${FUNCTION_GETHOSTBYNAME_LIBRARIES}" )
	set_property( CACHE GLOBAL_LIBRARIES  PROPERTY VALUE ${GLOBAL_LIBRARIES} ${FUNCTION_GETHOSTBYNAME_LIBRARIES} )
endif()
message( STATUS "Detecting networking library (socket/nsl/ws2_32) - done" )
endif()

#
# enable web server?
#
option( ENABLE_WEB_SERVER "Build web-server (default=ON)" ON )

#
# Test for big endian
#
TEST_BIG_ENDIAN( BIG_ENDIAN )
if( NOT DEFINED BIG_ENDIAN )
	message( WARNING "unable to determine endianness, only LITTLE ENDIAN is supported" )
elseif( BIG_ENDIAN )
	message( FATAL_ERROR "bigendian is not supported" )
endif()


#
# Test monotonic clock
#
# CLOCK_MONOTONIC clock for clock_gettime
# Normally defines _POSIX_TIMERS > 0 and _POSIX_MONOTONIC_CLOCK (for posix
# compliant systems) and __FreeBSD_cc_version >= 500005 (for FreeBSD
# >= 5.1.0, which does not have the posix defines (ref. r11983)) would be
# checked but some systems define them even when they do not support it
# (ref. bugreport:1003).
#
message( STATUS "Check for monotonic clock" )
find_library( RT_LIBRARY rt )# (optional, rt on Debian)
mark_as_advanced( RT_LIBRARY )
set( CMAKE_REQUIRED_LIBRARIES ${GLOBAL_LIBRARIES} ${RT_LIBRARY} )
file( READ "${CMAKE_SOURCE_DIR}/3rdparty/cmake/tests/HAVE_MONOTONIC_CLOCK.c" _SOURCE )
CHECK_C_SOURCE_RUNS( "${_SOURCE}" HAVE_MONOTONIC_CLOCK )
if( HAVE_MONOTONIC_CLOCK )
	message( STATUS "Check for monotonic clock - yes" )
	set_property( CACHE GLOBAL_LIBRARIES    PROPERTY VALUE ${GLOBAL_LIBRARIES} ${RT_LIBRARY} )
	set_property( CACHE GLOBAL_DEFINITIONS  PROPERTY VALUE "${GLOBAL_DEFINITIONS} -DHAVE_MONOTONIC_CLOCK" )
else()
	message( STATUS "Check for monotonic clock - no" )
endif()


#
# Test if function exists:
#   setrlimit - used to set the socket limit
#   strnlen - string length with upper scan bound
#   getpid - process id
#   gettid - thread id
#
CHECK_FUNCTION_EXISTS( setrlimit HAVE_SETRLIMIT )
CHECK_FUNCTION_EXISTS( strnlen HAVE_STRNLEN )
CHECK_FUNCTION_EXISTS( getpid HAVE_GETPID )
CHECK_FUNCTION_EXISTS( gettid HAVE_GETTID )
foreach( define HAVE_SETRLIMIT HAVE_STRNLEN HAVE_GETPID HAVE_GETTID )
	if( ${define} )
		set_property( CACHE GLOBAL_DEFINITIONS  PROPERTY VALUE "${GLOBAL_DEFINITIONS} -D${define}" )
	endif()
endforeach()


#
# Use RDTSC instruction as a timing source (time stamp counter on x86 since Pentium) (default=OFF)
#
# Enable it when you've timing issues. (ex: in conjunction with XEN or Other Virtualization mechanisms)
# Please ensure that you've disabled dynamic CPU-Frequencys, such as power saving options.
# (On the most modern Dedicated Servers cpufreq is preconfigured, see your distribution's manual how to disable it)
#
option( ENABLE_RDTSC "use RDTSC instruction as a timing source (default=OFF)" OFF )
if( ENABLE_RDTSC )
	set_property( CACHE GLOBAL_DEFINITIONS  PROPERTY VALUE "${GLOBAL_DEFINITIONS} -DENABLE_RDTSC" )
	message( STATUS "Enabled RDTSC as a timing source" )
endif()


#
# Enable debug code (default=OFF)
# Provides compatibility with --enable-debug configure option
#
option( ENABLE_DEBUG "enable debug code (default=OFF)" OFF )
option( ENABLE_EXTRA_DEBUG_CODE "enable extra debug code (default=OFF)" OFF )

if( ENABLE_DEBUG OR ENABLE_EXTRA_DEBUG_CODE )
	set_property( CACHE GLOBAL_DEFINITIONS  PROPERTY VALUE "${GLOBAL_DEFINITIONS} -DDEBUG" )
	if( ENABLE_DEBUG )
		message( STATUS "Enabled DEBUG code (configure compatibility)" )
	endif()
	if( ENABLE_EXTRA_DEBUG_CODE )
		message( STATUS "Enabled extra DEBUG code" )
	endif()
endif()


#
# Enable EPOLL (default=OFF)
# Only for Linux - provides compatibility with --enable-epoll configure option
#
option( ENABLE_EPOLL "enable epoll(4) on Linux (default=OFF)" OFF )
option( ENABLE_EXTRA_SOCKET_POLL "enable SOCKET_EPOLL (default=OFF)" OFF )

if( ENABLE_EPOLL OR ENABLE_EXTRA_SOCKET_POLL )
	set_property( CACHE GLOBAL_DEFINITIONS  PROPERTY VALUE "${GLOBAL_DEFINITIONS} -DSOCKET_EPOLL" )
	if( ENABLE_EPOLL )
		message( STATUS "Enabled epoll (configure compatibility)" )
	endif()
	if( ENABLE_EXTRA_SOCKET_POLL )
		message( STATUS "Enabled SOCKET_EPOLL" )
	endif()
endif()


#
# Enable builtin memory manager (default=default)
#
set( MEMMGR_OPTIONS "default;yes;no" )
set( ENABLE_MEMMGR "default" CACHE STRING "enable builtin memory manager: ${MEMMGR_OPTIONS} (default=default)" )
set_property( CACHE ENABLE_MEMMGR  PROPERTY STRINGS ${MEMMGR_OPTIONS} )
if( ENABLE_MEMMGR STREQUAL "default" )
	# use source code default
elseif( ENABLE_MEMMGR STREQUAL "yes" )
	set_property( CACHE GLOBAL_DEFINITIONS  PROPERTY VALUE "${GLOBAL_DEFINITIONS} -DUSE_MEMMGR" )
	message( STATUS "Enabled the builtin memory manager" )
elseif( ENABLE_MEMMGR STREQUAL "no" )
	set_property( CACHE GLOBAL_DEFINITIONS  PROPERTY VALUE "${GLOBAL_DEFINITIONS} -DNO_MEMMGR" )
	message( STATUS "Disabled the builtin memory manager" )
else()
	message( FATAL_ERROR "invalid option ENABLE_MEMMGR=${ENABLE_MEMMGR} (valid options: ${MEMMGR_OPTIONS})" )
endif()


#
# Enable memory library (default=system)
#
set( MEMORY_OPTIONS "system;memwatch;dmalloc;gcollect" )
set( ENABLE_MEMORY "system" CACHE STRING "enable memory library: ${MEMORY_OPTIONS} (default=system)" )
set_property( CACHE ENABLE_MEMORY  PROPERTY STRINGS ${MEMORY_OPTIONS} )
if( ENABLE_MEMORY STREQUAL "system" )
	# use system functions

elseif( ENABLE_MEMORY STREQUAL "memwatch" )
	CHECK_INCLUDE_FILE( memwatch.h HAVE_MEMWATCH_H )
	find_library( MEMWATCH_LIBRARY memwatch )
	mark_as_advanced( MEMWATCH_LIBRARY )
	if( HAVE_MEMWATCH_H AND MEMWATCH_LIBRARY )
		message( STATUS "Adding global library: ${MEMWATCH_LIBRARY}" )
		set_property( CACHE GLOBAL_LIBRARIES    PROPERTY VALUE ${GLOBAL_LIBRARIES} ${MEMWATCH_LIBRARY} )
		set_property( CACHE GLOBAL_DEFINITIONS  PROPERTY VALUE "${GLOBAL_DEFINITIONS} -DMEMWATCH" )
		message( STATUS "Enabled the memory library memwatch" )
	else()
		message( FATAL_ERROR "Failed to enable the memory library memwatch" )
	endif()

elseif( ENABLE_MEMORY STREQUAL "dmalloc" )
	CHECK_INCLUDE_FILE( dmalloc.h HAVE_DMALLOC_H )
	find_library( DMALLOC_LIBRARY dmalloc )
	mark_as_advanced( DMALLOC_LIBRARY )
	if( HAVE_DMALLOC_H AND DMALLOC_LIBRARY )
		message( STATUS "Adding global library: ${DMALLOC_LIBRARY}" )
		set_property( CACHE GLOBAL_LIBRARIES    PROPERTY VALUE ${GLOBAL_LIBRARIES} ${DMALLOC_LIBRARY} )
		set_property( CACHE GLOBAL_DEFINITIONS  PROPERTY VALUE "${GLOBAL_DEFINITIONS} -DDMALLOC -DDMALLOC_FUNC_CHECK" )
		message( STATUS "Enabled the memory library dmalloc" )
	else()
		message( FATAL_ERROR "Failed to enable the memory library dmalloc" )
	endif()

elseif( ENABLE_MEMORY STREQUAL "gcollect" )
	CHECK_INCLUDE_FILE( gc.h HAVE_GC_H )
	find_library( GC_LIBRARY gc )
	mark_as_advanced( GC_LIBRARY )
	if( HAVE_GC_H AND GC_LIBRARY )
		message( STATUS "Adding global library: ${GC_LIBRARY}" )
		set_property( CACHE GLOBAL_LIBRARIES    PROPERTY VALUE ${GLOBAL_LIBRARIES} ${GC_LIBRARY} )
		set_property( CACHE GLOBAL_DEFINITIONS  PROPERTY VALUE "${GLOBAL_DEFINITIONS} -DGCOLLECT" )
		message( STATUS "Enabled the memory library gcollect" )
	else()
		message( FATAL_ERROR "Failed to enable the memory library gcollect" )
	endif()

else()
	message( FATAL_ERROR "invalid option ENABLE_MEMORY=${ENABLE_MEMORY} (valid options: ${MEMORY_OPTIONS})" )
endif()


#
# Enable profiler (default=none)
#
set( PROFILER_OPTIONS "none;gprof" )
set( ENABLE_PROFILER "none" CACHE STRING "enable profiler: ${PROFILER_OPTIONS} (default=none)" )
set_property( CACHE ENABLE_PROFILER  PROPERTY STRINGS ${PROFILER_OPTIONS} )
if( ENABLE_PROFILER STREQUAL "none" )
	# no profiler

elseif( ENABLE_PROFILER STREQUAL "gprof" )
	if( CMAKE_C_COMPILER_ID STREQUAL "GNU" )
		if( NOT HAVE_GPROF_FLAGS )
			set_property( CACHE CMAKE_C_FLAGS  PROPERTY VALUE "${CMAKE_C_FLAGS} -pg" )
			set_property( CACHE CMAKE_EXE_LINKER_FLAGS  PROPERTY VALUE "${CMAKE_EXE_LINKER_FLAGS} -pg" )
			set( HAVE_GPROF_FLAGS ON  CACHE INTERNAL "" )
		endif()
		message( STATUS "Enabled the profiler gprof" )
	else()
		message( FATAL_ERROR "Failed to enable the profiler gprof - not GNU" )
	endif()

else()
	message( FATAL_ERROR "invalid option ENABLE_PROFILER=${ENABLE_PROFILER} (valid options: ${PROFILER_OPTIONS})" )
endif()


#
# Enable extra buildbot code (default=OFF)
#
option( ENABLE_EXTRA_BUILDBOT_CODE "enable extra buildbot code (default=OFF)" OFF )
if( ENABLE_EXTRA_BUILDBOT_CODE )
	set_property( CACHE GLOBAL_DEFINITIONS  PROPERTY VALUE "${GLOBAL_DEFINITIONS} -DBUILDBOT" )
	message( STATUS "Enabled extra BUILDBOT code" )
endif()


#####################################################################
# package stuff
#
set( CPACK_PACKAGE_NAME "rAthena" )
set( CPACK_PACKAGE_DESCRIPTION_SUMMARY "MMORPG server package" )
set( CPACK_PACKAGE_VERSION ${SVNVERSION} )
set( CPACK_RESOURCE_FILE_LICENSE ${CMAKE_CURRENT_SOURCE_DIR}/LICENSE )
#set( CPACK_MONOLITHIC_INSTALL ON )
include( CPACK  OPTIONAL  RESULT_VARIABLE HAVE_CPACK )
if( HAVE_CPACK )
	option( WITH_CPACK "enable building packages with CPack ('package' target)" ON )
endif()
if( NOT WITH_CPACK )
	# empty replacements
	macro( cpack_add_component_group )
	endmacro()
	macro( cpack_add_component )
	endmacro()
	message( STATUS "Disabled package creation" )
endif()

set( Runtime "Runtime files"  CACHE INTERNAL "" )
set( Runtime_base "configurations, dbs, npcs, docs, ..."  CACHE INTERNAL "" )
set( Runtime_templates "conf/import and save (generated from conf/import-tmpl and save-tmpl)"  CACHE INTERNAL "" )
cpack_add_component_group( Runtime DESCRIPTION ${Runtime} DISPLAY_NAME "Runtime" )
cpack_add_component( Runtime_base DESCRIPTION ${Runtime_base} DISPLAY_NAME "Base files" GROUP Runtime )
cpack_add_component( Runtime_templates DESCRIPTION ${Runtime_templates} DISPLAY_NAME "Base templates" GROUP Runtime )

set( Development "Development files"  CACHE INTERNAL "" )
set( Development_base "projects, 3rdparty, sources, templates"  CACHE INTERNAL "" )
cpack_add_component_group( Development DESCRIPTION ${Development} DISPLAY_NAME "Development" )
cpack_add_component( Development_base DESCRIPTION ${Development_base} DISPLAY_NAME "Base files" GROUP Development )


#
# install stuff
#
option( INSTALL_COMPONENT_RUNTIME "install/package files needed to run the project" ON )
option( INSTALL_COMPONENT_DEVELOPMENT "install/package files needed to build the project" OFF )
option( INSTALL_TO_PATH "copy files to INSTALL_PATH" OFF )
option( INSTALL_TO_SOURCE "copy files to source directory, skips what is already there (${CMAKE_CURRENT_SOURCE_DIR})" OFF )
option( INSTALL_TO_SUBDIR "copy files to subdirectory (${CMAKE_CURRENT_BINARY_DIR}/install)" OFF )
set( INSTALL_PATH "${CMAKE_INSTALL_PREFIX}"  CACHE STRING "install path (only used when INSTALL_TO_PATH is set)" )
mark_as_advanced( CMAKE_INSTALL_PREFIX )
if( INSTALL_TO_PATH AND NOT ("${INSTALL_TO}" STREQUAL "path") )# changed to path
	set_property( CACHE INSTALL_TO_SOURCE INSTALL_TO_SUBDIR  PROPERTY VALUE OFF )
elseif( INSTALL_TO_SOURCE AND NOT ("${INSTALL_TO}" STREQUAL "source") )# changed to source
	set_property( CACHE INSTALL_TO_PATH INSTALL_TO_SUBDIR  PROPERTY VALUE OFF )
elseif( INSTALL_TO_SUBDIR AND NOT ("${INSTALL_TO}" STREQUAL "subdir") )# changed to subdir
	set_property( CACHE INSTALL_TO_PATH INSTALL_TO_SOURCE  PROPERTY VALUE OFF )
elseif( NOT INSTALL_TO_PATH AND NOT INSTALL_TO_SOURCE AND NOT INSTALL_TO_SUBDIR )# default
	set_property( CACHE INSTALL_TO_SUBDIR  PROPERTY VALUE ON )
endif()
if( INSTALL_TO_PATH )
	set( INSTALL_TO "path"  CACHE INTERNAL "" )
	set_property( CACHE CMAKE_INSTALL_PREFIX  PROPERTY VALUE "${INSTALL_PATH}" )
elseif( INSTALL_TO_SOURCE )
	set( INSTALL_TO "source"  CACHE INTERNAL "" )
	set_property( CACHE CMAKE_INSTALL_PREFIX  PROPERTY VALUE "${CMAKE_CURRENT_SOURCE_DIR}" )
elseif( INSTALL_TO_SUBDIR )
	set( INSTALL_TO "subdir"  CACHE INTERNAL "" )
	set_property( CACHE CMAKE_INSTALL_PREFIX  PROPERTY VALUE "${CMAKE_CURRENT_BINARY_DIR}/install" )
endif()
set( SVN_FOLDER_PATTERN "[\\.]svn"  CACHE STRING "pattern of svn folder that we exclude from instalations" )
mark_as_advanced( SVN_FOLDER_PATTERN )
set( DEVELOPMENT_FILES
	"${CMAKE_CURRENT_SOURCE_DIR}/CMakeLists.txt"
	"${CMAKE_CURRENT_SOURCE_DIR}/configure"
	"${CMAKE_CURRENT_SOURCE_DIR}/configure.in"
	"${CMAKE_CURRENT_SOURCE_DIR}/rAthena.sln"
	)
set( DEVELOPMENT_DIRECTORIES
	"3rdparty"
	"conf/import-tmpl"
	"conf/msg_conf/import-tmpl"
	"db/import-tmpl"
	"src"
	)
set( RUNTIME_FILES
	"${CMAKE_CURRENT_SOURCE_DIR}/athena-start"
	"${CMAKE_CURRENT_SOURCE_DIR}/LICENSE"
	"${CMAKE_CURRENT_SOURCE_DIR}/README.md"
	)
if (WIN32)
	set (RUNTIME_FILES 
		${RUNTIME_FILES}
		"${CMAKE_CURRENT_SOURCE_DIR}/dbghelp.dll"
		"${CMAKE_CURRENT_SOURCE_DIR}/libmysql.dll"
		"${CMAKE_CURRENT_SOURCE_DIR}/pcre3.dll"
		"${CMAKE_CURRENT_SOURCE_DIR}/zlib1.dll"
		"${CMAKE_CURRENT_SOURCE_DIR}/tools/charserv.bat"
		"${CMAKE_CURRENT_SOURCE_DIR}/tools/logserv.bat"
		"${CMAKE_CURRENT_SOURCE_DIR}/tools/mapserv.bat"
		"${CMAKE_CURRENT_SOURCE_DIR}/tools/runserver.bat"
		"${CMAKE_CURRENT_SOURCE_DIR}/tools/serv.bat"
	)
endif(WIN32)

set( RUNTIME_DIRECTORIES
	"conf"
	"db"
	"doc"
	"log"
	"npc"
	"sql-files"
	"tools"
	)
if( INSTALL_TO_SOURCE )# skip, already in the source dir
else()
	if( INSTALL_COMPONENT_RUNTIME )
		install( FILES ${RUNTIME_FILES}
			DESTINATION "."
			COMPONENT Runtime_base )
		foreach( DIR IN ITEMS ${RUNTIME_DIRECTORIES} )
			if( EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/${DIR}/" )
				install( DIRECTORY "${DIR}/"
					DESTINATION "${DIR}"
					COMPONENT Runtime_base
					PATTERN ${SVN_FOLDER_PATTERN} EXCLUDE
					PATTERN "conf/import-tmpl" EXCLUDE )
			else()
				# create empty directory
				install( CODE "file(MAKE_DIRECTORY \"\${ENV}\${CMAKE_INSTALL_PREFIX}/${DIR}\")"
					COMPONENT Runtime_base )
			endif()
		endforeach()
	endif( INSTALL_COMPONENT_RUNTIME )
	if( INSTALL_COMPONENT_DEVELOPMENT )
		install( FILES ${DEVELOPMENT_FILES}
			DESTINATION "."
			COMPONENT Development_base )
		foreach( DIR IN ITEMS ${DEVELOPMENT_DIRECTORIES} )
			install( DIRECTORY "${DIR}/"
				DESTINATION "${DIR}"
				COMPONENT Development_base
				PATTERN ${SVN_FOLDER_PATTERN} EXCLUDE )
		endforeach()
	endif( INSTALL_COMPONENT_DEVELOPMENT )
endif()
if( INSTALL_COMPONENT_RUNTIME )
	# templates
	set( _TEMPLATES
		"conf/import-tmpl" "conf/import"
		"conf/msg_conf/import-tmpl" "conf/msg_conf/import"
		"db/import-tmpl" "db/import"
		)
	set( INSTALL_TEMPLATES_FILE "${CMAKE_CURRENT_BINARY_DIR}/InstallTemplates.cmake" )
	file( WRITE "${INSTALL_TEMPLATES_FILE}"
		"macro( INSTALL_TEMPLATE _SRC _DST )\n"
		"  set( SRC \"${CMAKE_CURRENT_SOURCE_DIR}/\${_SRC}\" )\n"
		"  set( DST \"\${CMAKE_INSTALL_PREFIX}/\${_DST}\" )\n"
		"  if( EXISTS \"\${DST}\" )\n"
		"    message( \"-- Already exists: \${DST}\" )\n"
		"  else()\n"
		"    message( \"-- Installing template: \${DST}\" )\n"
		"    execute_process( COMMAND \"${CMAKE_COMMAND}\" -E copy \"\${SRC}\" \"\${DST}\" )\n"
		"  endif()\n"
		"endmacro()\n"
		)
	while( _TEMPLATES )
		list( GET _TEMPLATES 0 _SRC )
		list( GET _TEMPLATES 1 _DST )
		list( REMOVE_AT _TEMPLATES 0 1 )
		if( IS_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}/${_SRC}" )
			file( GLOB _PATHS "${CMAKE_CURRENT_SOURCE_DIR}/${_SRC}/*" )
			foreach( _PATH IN ITEMS ${_PATHS} )
				string( REPLACE "${CMAKE_CURRENT_SOURCE_DIR}/${_SRC}/" "" _PATH "${_PATH}" )
				if( NOT "${_PATH}" MATCHES "${SVN_FOLDER_PATTERN}" )
					list( APPEND _TEMPLATES "${_SRC}/${_PATH}" "${_DST}/${_PATH}" )
				endif()
			endforeach()
		else()
			file( APPEND "${INSTALL_TEMPLATES_FILE}" "INSTALL_TEMPLATE( \"${_SRC}\" \"${_DST}\" )\n" )
		endif()
	endwhile()
	install( SCRIPT "${INSTALL_TEMPLATES_FILE}"
		COMPONENT Runtime_templates )
endif( INSTALL_COMPONENT_RUNTIME )


#
# sources
#
set( TARGET_LIST  CACHE INTERNAL "" )
add_subdirectory( 3rdparty )
add_subdirectory( src )


#####################################################################
# final checks and warnings
#

list( LENGTH  TARGET_LIST  _LEN )
if( _LEN EQUAL 0 )
	message( FATAL_ERROR "no targets available" )
endif()
message( STATUS "Available targets:" )
foreach( _TARGET IN ITEMS ${TARGET_LIST} )
	message( STATUS "\t${_TARGET}" )
endforeach()
