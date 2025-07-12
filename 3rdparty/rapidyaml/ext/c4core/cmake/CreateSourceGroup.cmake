# create hierarchical source groups based on a dir tree
#
# EXAMPLE USAGE:
#
#    create_source_group("src" "${SRC_ROOT}" "${SRC_LIST}")
#
# Visual Studio usually has the equivalent to this:
#
#    create_source_group("Header Files" ${PROJ_SRC_DIR} "${PROJ_HEADERS}")
#    create_source_group("Source Files" ${PROJ_SRC_DIR} "${PROJ_SOURCES}")
#
# TODO: <jpmag> this was taken from a stack overflow answer. Need to find it
# and add a link here.

macro(create_source_group GroupPrefix RootDir ProjectSources)
  # Disable source grouping to avoid regex path issues with special characters
  # This is a workaround for CMake regex compilation errors when paths contain
  # special characters like ++ which are interpreted as regex metacharacters

  # Simply group all sources under the main prefix to avoid path processing
  set(DirSources ${ProjectSources})
  foreach(Source ${DirSources})
    source_group("${GroupPrefix}" FILES ${Source})
  endforeach(Source)
endmacro(create_source_group)
