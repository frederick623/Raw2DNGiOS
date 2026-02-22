
CMAKE_MINIMUM_REQUIRED( VERSION 3.10.1 )
set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_BUILD_TYPE Release)
set(CMAKE_OSX_ARCHITECTURES "arm64")
set(BUILD_SHARED_LIBS FALSE)

ADD_SUBDIRECTORY(raw2dng)

add_library(raw2dng ${CMAKE_CURRENT_SOURCE_DIR}/raw2dng.cpp)

# Link against the library the child built
target_link_libraries(raw2dng PRIVATE rawConverter)
