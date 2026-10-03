find_package(Qt6 REQUIRED COMPONENTS ShaderTools Core Qml Gui Quick QuickControls2 Concurrent Sql Network DBus)
find_package(PkgConfig REQUIRED)
enable_language(C)
pkg_check_modules(Qalculate IMPORTED_TARGET libqalculate REQUIRED)
pkg_check_modules(Pipewire IMPORTED_TARGET libpipewire-0.3 REQUIRED)
pkg_check_modules(Aubio IMPORTED_TARGET aubio REQUIRED)
pkg_check_modules(Cava IMPORTED_TARGET libcava QUIET)
if(NOT Cava_FOUND)
    # Fedora ships the cava executable but not its cavacore development files.
    # Build the small cavacore library from the pinned upstream source instead
    # of requiring a distro-specific -devel package.
    include(FetchContent)
    FetchContent_Declare(
        cava_source
        GIT_REPOSITORY https://github.com/karlstav/cava.git
        GIT_TAG        0.10.2
        SOURCE_DIR     "${CMAKE_BINARY_DIR}/_deps/cava-source"
    )
    FetchContent_GetProperties(cava_source)
    if(NOT cava_source_POPULATED)
        FetchContent_Populate(cava_source)
    endif()

    pkg_check_modules(FFTW3 IMPORTED_TARGET fftw3 REQUIRED)
    add_library(caelestia-cavacore STATIC "${cava_source_SOURCE_DIR}/cavacore.c")
    set_target_properties(caelestia-cavacore PROPERTIES POSITION_INDEPENDENT_CODE ON)
    target_include_directories(caelestia-cavacore PUBLIC "${cava_source_SOURCE_DIR}")
    target_link_libraries(caelestia-cavacore PRIVATE PkgConfig::FFTW3 m)
    set(CAELESTIA_CAVA_TARGET caelestia-cavacore)
    set(CAELESTIA_CAVA_BUNDLED ON)
else()
    set(CAELESTIA_CAVA_TARGET PkgConfig::Cava)
    set(CAELESTIA_CAVA_BUNDLED OFF)
endif()
include(cmake/sensorslib.cmake)

set(QT_QML_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/qml")
qt_standard_project_setup(REQUIRES 6.9)

include(cmake/pch.cmake)
include(cmake/qml-module.cmake)

add_subdirectory(src/Caelestia)
