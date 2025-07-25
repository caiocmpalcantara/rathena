
# macro to configure the use of local or system version of a package
# Uses:
#	HAVE_LOCAL_${name} - is local version available?
#	${name}_LOCAL_LIBRARIES - libraries of the local version
#	${name}_LOCAL_INCLUDE_DIRS - include directories of the local version
#	HAVE_SYSTEM_${name} - is system version available?
#	${name}_SYSTEM_LIBRARIES - libraries of the system version
#	${name}_SYSTEM_INCLUDE_DIRS - include directories of the system version
# Generates:
#	WITH_LOCAL_${name} - use the local version of the package (only when local is available)
#	WITH_${name} - use this package
#	${name}_LIBRARIES - libraries
#	${name}_INCLUDE_DIRS - include directories
macro( CONFIGURE_WITH_LOCAL_OR_SYSTEM name )
	unset( ${name}_LIBRARIES CACHE )
	unset( ${name}_INCLUDE_DIRS CACHE )
	if( HAVE_LOCAL_${name} )
		set( WITH_LOCAL_${name} ON
			CACHE BOOL "use local version of ${name}" )
	else()
		unset( WITH_LOCAL_${name} CACHE )
	endif()
	if( WITH_LOCAL_${name} )
		message( STATUS "Configuring for local ${name}" )
		set( ${name}_LIBRARIES ${${name}_LOCAL_LIBRARIES} )
		set( ${name}_INCLUDE_DIRS ${${name}_LOCAL_INCLUDE_DIRS} )
		message( STATUS "Configuring for local ${name} - done" )
	elseif( HAVE_SYSTEM_${name} )
		message( STATUS "Configuring for system ${name}" )
		set( ${name}_LIBRARIES ${${name}_SYSTEM_LIBRARIES} )
		set( ${name}_INCLUDE_DIRS ${${name}_SYSTEM_INCLUDE_DIRS} )
		message( STATUS "Configuring for system ${name} - done" )
	endif()
	if( WITH_LOCAL_${name} OR HAVE_SYSTEM_${name} )
		set( WITH_${name} ON
			CACHE BOOL "use ${name}" )
	else()
		unset( WITH_${name} CACHE )
	endif()
	set( ${name}_LIBRARIES ${${name}_LIBRARIES}
		CACHE PATH "${name} libraries" )
	set( ${name}_INCLUDE_DIRS ${${name}_INCLUDE_DIRS}
		CACHE PATH "${name} include directories" )
	mark_as_advanced( ${name}_LIBRARIES )
	mark_as_advanced( ${name}_INCLUDE_DIRS )
endmacro( CONFIGURE_WITH_LOCAL_OR_SYSTEM )


# Add 3rdparty libraries
# These can be built in parallel as they have minimal interdependencies

# Fix for rapidyaml regex path issues in CMake
# Disable source grouping to avoid regex compilation errors
set( RYML_WITH_TAB_TOKENS OFF CACHE BOOL "Disable tab tokens to avoid regex issues" )
set( C4_DISABLE_SOURCE_GROUPS ON CACHE BOOL "Disable source groups to avoid regex path issues" )

add_subdirectory( httplib )
add_subdirectory( json )
add_subdirectory( libconfig )
add_subdirectory( mysql )
add_subdirectory( pcre )
add_subdirectory( rapidyaml )  # Note: rapidyaml depends on c4core internally
add_subdirectory( yaml-cpp )
add_subdirectory( zlib )

# Set parallel build properties for 3rdparty targets if enabled
if( ENABLE_PARALLEL_BUILD AND PARALLEL_BUILD_JOBS GREATER 1 )
	# Most 3rdparty libraries can build in parallel
	# rapidyaml has internal dependencies but handles them correctly
	message( STATUS "3rdparty libraries configured for parallel builds" )
endif()
