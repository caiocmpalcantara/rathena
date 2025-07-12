#
# setup
#
set( WEB_SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}  CACHE INTERNAL "" )


#
# web server
#
if ( NOT ENABLE_WEB_SERVER )
	return()
endif ( NOT ENABLE_WEB_SERVER )

if( BUILD_SERVERS AND ENABLE_WEB_SERVER )
message( STATUS "Creating target web-server" )
file(GLOB WEB_HEADERS ${WEB_SOURCE_DIR}/*.hpp)
file(GLOB WEB_SOURCES ${WEB_SOURCE_DIR}/*.cpp)
set( DEPENDENCIES common yaml-cpp httplib)
set( LIBRARIES ${GLOBAL_LIBRARIES} ${MYSQL_LIBRARIES} )
set( INCLUDE_DIRS ${GLOBAL_INCLUDE_DIRS} ${COMMON_BASE_INCLUDE_DIRS} ${HTTPLIB_INCLUDE_DIRS} ${JSON_INCLUDE_DIRS} ${RA_INCLUDE_DIRS} ${MYSQL_INCLUDE_DIRS} )
set( DEFINITIONS "${GLOBAL_DEFINITIONS} ${COMMON_BASE_DEFINITIONS}" )
set( SOURCE_FILES ${COMMON_BASE_HEADERS} ${COMMON_HEADERS} ${WEB_HEADERS} ${WEB_SOURCES} )
source_group( common FILES ${COMMON_BASE_HEADERS} ${COMMON_HEADERS} )
source_group( web FILES ${WEB_HEADERS} ${WEB_SOURCES} )
include_directories( ${INCLUDE_DIRS} )

#message( STATUS "web-server SOURCE_FILES=${SOURCE_FILES}")
add_executable( web-server ${SOURCE_FILES} )
#message( STATUS "web-server LIBRARIES=${LIBRARIES}, DEPENDENCIES=${DEPENDENCIES} DEFINITIONS=${DEFINITIONS}")
add_dependencies( web-server ${DEPENDENCIES} )
target_link_libraries( web-server ${LIBRARIES} ${DEPENDENCIES} )

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
					target_compile_definitions( web-server PRIVATE ${clean_def} )
				endif()
			endif()
		endif()
	endforeach()
endif()

# Apply COMMON_BASE_DEFINITIONS
if( COMMON_BASE_DEFINITIONS )
	target_compile_definitions( web-server PRIVATE ${COMMON_BASE_DEFINITIONS} )
endif()

target_include_directories( web-server PRIVATE ${INCLUDE_DIRS} )
if( INSTALL_COMPONENT_RUNTIME )
	cpack_add_component( Runtime_webserver DESCRIPTION "web-server" DISPLAY_NAME "web-server" GROUP Runtime )
	install( TARGETS web-server
		DESTINATION "."
		COMPONENT Runtime_webserver )
endif( INSTALL_COMPONENT_RUNTIME )
set( TARGET_LIST ${TARGET_LIST} web-server  CACHE INTERNAL "" )
message( STATUS "Creating target web-server - done" )
endif( BUILD_SERVERS AND ENABLE_WEB_SERVER)
