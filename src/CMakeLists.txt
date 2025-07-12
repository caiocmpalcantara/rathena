
#
# setup and static libraries
#

set(RA_INCLUDE_DIRS ${CMAKE_CURRENT_SOURCE_DIR} CACHE PATH
	"rathena include directory"
)
mark_as_advanced( RA_INCLUDE_DIRS )



# Build common library first (required by all servers)
add_subdirectory( common )
if( HAVE_common )
	option( BUILD_SERVERS "build server executables" ON )
else()
	message( STATUS "Disabled server targets (requires common)" )
endif()

# Build tools early (only depends on minicore, can build in parallel with servers)
add_subdirectory( tool )

#
# Server targets - these can build in parallel once common is ready
# Each server has the same dependency on common, so they can build concurrently
#
if( BUILD_SERVERS )
	add_subdirectory( login )
	add_subdirectory( char )
	add_subdirectory( map )
	add_subdirectory( web )

	if( ENABLE_PARALLEL_BUILD )
		message( STATUS "Server targets configured for parallel builds (depends on common)" )
	endif()
endif()

