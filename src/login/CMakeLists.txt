#
# setup
#
set( LOGIN_SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}  CACHE INTERNAL "" )

# login server
#
if( BUILD_SERVERS )
message( STATUS "Creating target login-server" )
file(GLOB LOGIN_HEADERS ${LOGIN_SOURCE_DIR}/*.hpp)
file(GLOB LOGIN_SOURCES_CXX ${LOGIN_SOURCE_DIR}/*.cpp)
set(LOGIN_SOURCES ${LOGIN_SOURCES_C} ${LOGIN_SOURCES_CXX})
#message( STATUS "LOGIN_SOURCES="${LOGIN_SOURCES})
set( DEPENDENCIES common )
set( LIBRARIES ${GLOBAL_LIBRARIES} ${MYSQL_LIBRARIES} )
set( INCLUDE_DIRS ${GLOBAL_INCLUDE_DIRS} ${COMMON_BASE_INCLUDE_DIRS} ${RA_INCLUDE_DIRS} ${MYSQL_INCLUDE_DIRS} )
set( DEFINITIONS "${GLOBAL_DEFINITIONS} ${COMMON_BASE_DEFINITIONS} -DWITH_SQL" )
set( SOURCE_FILES ${COMMON_BASE_HEADERS} ${COMMON_HEADERS} ${LOGIN_HEADERS} ${LOGIN_SOURCES} )
source_group( common FILES ${COMMON_BASE_HEADERS} ${COMMON_HEADERS} )
source_group( login FILES ${LOGIN_HEADERS} ${LOGIN_SOURCES} )
include_directories( ${INCLUDE_DIRS} )

add_executable( login-server ${SOURCE_FILES} )
add_dependencies( login-server ${DEPENDENCIES} )
target_link_libraries( login-server ${LIBRARIES} ${DEPENDENCIES} )

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
					target_compile_definitions( login-server PRIVATE ${clean_def} )
				endif()
			endif()
		endif()
	endforeach()
endif()

# Apply COMMON_BASE_DEFINITIONS
if( COMMON_BASE_DEFINITIONS )
	target_compile_definitions( login-server PRIVATE ${COMMON_BASE_DEFINITIONS} )
endif()

target_include_directories( login-server PRIVATE ${INCLUDE_DIRS} )
if( INSTALL_COMPONENT_RUNTIME )
	cpack_add_component( Runtime_loginserver DESCRIPTION "login-server" DISPLAY_NAME "login-server" GROUP Runtime )
	install( TARGETS login-server
		DESTINATION "."
		COMPONENT Runtime_loginserver )
endif( INSTALL_COMPONENT_RUNTIME )
set( TARGET_LIST ${TARGET_LIST} login-server  CACHE INTERNAL "" )
message( STATUS "Creating target login-server - done" )
endif( BUILD_SERVERS )
