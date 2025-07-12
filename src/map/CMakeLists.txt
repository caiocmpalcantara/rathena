#
# setup
#
set( MAP_SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}  CACHE INTERNAL "" )


#
# map server
#
if( BUILD_SERVERS )
message( STATUS "Creating target map-server" )
file(GLOB MAP_HEADERS ${MAP_SOURCE_DIR}/*.hpp)
file(GLOB MAP_SOURCES ${MAP_SOURCE_DIR}/*.cpp)
set( DEPENDENCIES common ryml)
set( LIBRARIES ${GLOBAL_LIBRARIES} ${MYSQL_LIBRARIES} )
set( INCLUDE_DIRS ${GLOBAL_INCLUDE_DIRS} ${COMMON_BASE_INCLUDE_DIRS} ${RA_INCLUDE_DIRS} ${MYSQL_INCLUDE_DIRS} )
set( DEFINITIONS "${GLOBAL_DEFINITIONS} ${COMMON_BASE_DEFINITIONS}" )
if( WITH_PCRE )
	message( STATUS "Enabled PCRE code" )
	set( LIBRARIES ${LIBRARIES} ${PCRE_LIBRARIES} )
	set( INCLUDE_DIRS ${INCLUDE_DIRS} ${PCRE_INCLUDE_DIRS} )
	set( DEFINITIONS "${DEFINITIONS} -DPCRE_SUPPORT" )
else()
	message( STATUS "Disabled PCRE code" )
endif()
set( SOURCE_FILES ${COMMON_BASE_HEADERS} ${COMMON_HEADERS} ${MAP_HEADERS} ${MAP_SOURCES} )
source_group( common FILES ${COMMON_BASE_HEADERS} ${COMMON_HEADERS} )
source_group( map FILES ${MAP_HEADERS} ${MAP_SOURCES} )
include_directories( ${INCLUDE_DIRS} )

#message( STATUS "map-server SOURCE_FILES=${SOURCE_FILES}")
add_executable( map-server ${SOURCE_FILES} )
#message( STATUS "map-server LIBRARIES=${LIBRARIES}, DEPENDENCIES=${DEPENDENCIES} DEFINITIONS=${DEFINITIONS}")
add_dependencies( map-server ${DEPENDENCIES} )
target_link_libraries( map-server ${LIBRARIES} ${DEPENDENCIES} )

# Modern CMake: Use target_compile_definitions instead of COMPILE_FLAGS
# Apply GLOBAL_DEFINITIONS properly - only preprocessor definitions, not compiler flags
if( GLOBAL_DEFINITIONS )
	# Parse GLOBAL_DEFINITIONS string and apply each definition
	string( REPLACE " " ";" GLOBAL_DEFS_LIST "${GLOBAL_DEFINITIONS}" )
	foreach( def IN LISTS GLOBAL_DEFS_LIST )
		if( def AND NOT def STREQUAL "" )
			# Only process items that start with -D (preprocessor definitions)
			if( def MATCHES "^-D" )
				# Remove leading -D
				string( REGEX REPLACE "^-D" "" clean_def "${def}" )
				if( clean_def AND NOT clean_def STREQUAL "" )
					target_compile_definitions( map-server PRIVATE ${clean_def} )
				endif()
			endif()
		endif()
	endforeach()
endif()

# Apply COMMON_BASE_DEFINITIONS
if( COMMON_BASE_DEFINITIONS )
	target_compile_definitions( map-server PRIVATE ${COMMON_BASE_DEFINITIONS} )
endif()

# Apply PCRE support definition if enabled
if( WITH_PCRE )
	target_compile_definitions( map-server PRIVATE PCRE_SUPPORT )
endif()

target_include_directories( map-server PRIVATE ${INCLUDE_DIRS} )
if( INSTALL_COMPONENT_RUNTIME )
	cpack_add_component( Runtime_mapserver DESCRIPTION "map-server" DISPLAY_NAME "map-server" GROUP Runtime )
	install( TARGETS map-server
		DESTINATION "."
		COMPONENT Runtime_mapserver )
endif( INSTALL_COMPONENT_RUNTIME )
set( TARGET_LIST ${TARGET_LIST} map-server  CACHE INTERNAL "" )
message( STATUS "Creating target map-server - done" )
endif( BUILD_SERVERS )
