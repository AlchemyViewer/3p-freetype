#!/usr/bin/env bash

export MSYS2_ARG_CONV_EXCL="*"

cd "$(dirname "$0")"

# turn on verbose debugging output for parabuild logs.
exec 4>&1; export BASH_XTRACEFD=4; set -x
# make errors fatal
set -e
# complain about unset env variables
set -u

if [ -z "$AUTOBUILD" ] ; then
    exit 1
fi

if [[ "$OSTYPE" == "cygwin" || "$OSTYPE" == "msys" ]] ; then
    autobuild="$(cygpath -u $AUTOBUILD)"
else
    autobuild="$AUTOBUILD"
fi

top="$(pwd)"
stage="$(pwd)/stage"

FREETYPELIB_SOURCE_DIR="$(pwd)/freetype"
HARFBUZZ_SOURCE_DIR="$(pwd)/harfbuzz"

# load autobuild provided shell functions and variables
source_environment_tempfile="$stage/source_environment.sh"
"$autobuild" source_environment > "$source_environment_tempfile"
. "$source_environment_tempfile"

# extract APR version into VERSION.txt
FREETYPE_INCLUDE_DIR="${FREETYPELIB_SOURCE_DIR}/include/freetype"
major_version="$(sed -n -E 's/#[[:space:]]*define[[:space:]]+FREETYPE_MAJOR[[:space:]]+([0-9]+)/\1/p' "${FREETYPE_INCLUDE_DIR}/freetype.h")"
minor_version="$(sed -n -E 's/#[[:space:]]*define[[:space:]]+FREETYPE_MINOR[[:space:]]+([0-9]+)/\1/p' "${FREETYPE_INCLUDE_DIR}/freetype.h")"
patch_version="$(sed -n -E 's/#[[:space:]]*define[[:space:]]+FREETYPE_PATCH[[:space:]]+([0-9]+)/\1/p' "${FREETYPE_INCLUDE_DIR}/freetype.h")"
version="${major_version}.${minor_version}.${patch_version}"
echo "${version}" > "${stage}/VERSION.txt"

case "$AUTOBUILD_PLATFORM" in
    windows*)
        load_vsvars

        # create staging dir structure
        mkdir -p "$stage/include/freetype2"
        mkdir -p "$stage/lib/debug"
        mkdir -p "$stage/lib/release"

        pushd "$FREETYPELIB_SOURCE_DIR"
            mkdir -p "build_debug_temp"
            pushd "build_debug_temp"
                cmake -G Ninja .. -DCMAKE_BUILD_TYPE=Debug -DBUILD_SHARED_LIBS:BOOL=OFF \
                    -DCMAKE_INSTALL_PREFIX="$(cygpath -m $stage)/debug_temp" \
                    -DFT_REQUIRE_ZLIB=ON \
                    -DFT_REQUIRE_PNG=ON \
                    -DFT_DISABLE_HARFBUZZ=ON \
                    -DFT_DISABLE_BZIP2=ON \
                    -DFT_DISABLE_BROTLI=ON \
                    -DZLIB_INCLUDE_DIRS="$(cygpath -m $stage)/packages/include/zlib/" \
                    -DZLIB_LIBRARIES="$(cygpath -m $stage)/packages/lib/debug/zlibd.lib" \
                    -DPNG_INCLUDE_DIRS="$(cygpath -m ${stage})/packages/include/libpng16/" \
                    -DPNG_LIBRARIES="$(cygpath -m ${stage})/packages/lib/debug/libpng16d.lib"

                cmake --build . --config Debug
                cmake --install . --config Debug
            popd

            mkdir -p "build_release_temp"
            pushd "build_release_temp"
                cmake -G Ninja .. -DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED_LIBS:BOOL=OFF \
                    -DCMAKE_INSTALL_PREFIX="$(cygpath -m $stage)/release_temp" \
                    -DFT_REQUIRE_ZLIB=ON \
                    -DFT_REQUIRE_PNG=ON \
                    -DFT_DISABLE_HARFBUZZ=ON \
                    -DFT_DISABLE_BZIP2=ON \
                    -DFT_DISABLE_BROTLI=ON \
                    -DZLIB_INCLUDE_DIRS="$(cygpath -m $stage)/packages/include/zlib/" \
                    -DZLIB_LIBRARIES="$(cygpath -m $stage)/packages/lib/release/zlib.lib" \
                    -DPNG_INCLUDE_DIRS="$(cygpath -m ${stage})/packages/include/libpng16/" \
                    -DPNG_LIBRARIES="$(cygpath -m ${stage})/packages/lib/release/libpng16.lib"

                cmake --build . --config Release
                cmake --install . --config Release
            popd
        popd

        pushd "$HARFBUZZ_SOURCE_DIR"
            mkdir -p "build_debug_temp"
            pushd "build_debug_temp"
                cmake -G Ninja .. -DCMAKE_BUILD_TYPE=Debug -DBUILD_SHARED_LIBS:BOOL=OFF \
                    -DCMAKE_INSTALL_PREFIX="$(cygpath -m $stage)/debug_temp" \
                    -DHB_HAVE_FREETYPE=ON \
                    -DFREETYPE_INCLUDE_DIRS="$(cygpath -m $stage)/debug_temp/include/freetype2/" \
                    -DFREETYPE_LIBRARIES="$(cygpath -m $stage)/debug_temp/lib/freetyped.lib"

                cmake --build . --config Debug
                cmake --install . --config Debug
            popd

            mkdir -p "build_release_temp"
            pushd "build_release_temp"
                cmake -G Ninja .. -DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED_LIBS:BOOL=OFF \
                    -DCMAKE_INSTALL_PREFIX="$(cygpath -m $stage)/release_temp" \
                    -DHB_HAVE_FREETYPE=ON \
                    -DFREETYPE_INCLUDE_DIRS="$(cygpath -m $stage)/release_temp/include/freetype2/" \
                    -DFREETYPE_LIBRARIES="$(cygpath -m $stage)/release_temp/lib/freetype.lib"

                cmake --build . --config Release
                cmake --install . --config Release
            popd
        popd

        pushd "$FREETYPELIB_SOURCE_DIR"
            mkdir -p "build_debug"
            pushd "build_debug"
                cmake -G Ninja .. -DCMAKE_BUILD_TYPE=Debug -DBUILD_SHARED_LIBS:BOOL=OFF \
                    -DCMAKE_INSTALL_PREFIX="$(cygpath -m $stage)/debug" \
                    -DFT_REQUIRE_ZLIB=ON \
                    -DFT_REQUIRE_PNG=ON \
                    -DFT_REQUIRE_HARFBUZZ=ON \
                    -DFT_DISABLE_BZIP2=ON \
                    -DFT_DISABLE_BROTLI=ON \
                    -DZLIB_INCLUDE_DIRS="$(cygpath -m $stage)/packages/include/zlib/" \
                    -DZLIB_LIBRARIES="$(cygpath -m $stage)/packages/lib/debug/zlibd.lib" \
                    -DPNG_INCLUDE_DIRS="$(cygpath -m ${stage})/packages/include/libpng16/" \
                    -DPNG_LIBRARIES="$(cygpath -m ${stage})/packages/lib/debug/libpng16d.lib" \
                    -DHarfBuzz_INCLUDE_DIRS="$(cygpath -m ${stage})/debug_temp/include/harfbuzz/" \
                    -DHarfBuzz_LIBRARY="$(cygpath -m ${stage})/debug_temp/lib/harfbuzz.lib"

                cmake --build . --config Debug
                cmake --install . --config Debug
            popd

            mkdir -p "build_release"
            pushd "build_release"
                cmake -G Ninja .. -DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED_LIBS:BOOL=OFF \
                    -DCMAKE_INSTALL_PREFIX="$(cygpath -m $stage)/release" \
                    -DFT_REQUIRE_ZLIB=ON \
                    -DFT_REQUIRE_PNG=ON \
                    -DFT_REQUIRE_HARFBUZZ=ON \
                    -DFT_DISABLE_BZIP2=ON \
                    -DFT_DISABLE_BROTLI=ON \
                    -DZLIB_INCLUDE_DIRS="$(cygpath -m $stage)/packages/include/zlib/" \
                    -DZLIB_LIBRARIES="$(cygpath -m $stage)/packages/lib/release/zlib.lib" \
                    -DPNG_INCLUDE_DIRS="$(cygpath -m ${stage})/packages/include/libpng16/" \
                    -DPNG_LIBRARIES="$(cygpath -m ${stage})/packages/lib/release/libpng16.lib" \
                    -DHarfBuzz_INCLUDE_DIRS="$(cygpath -m ${stage})/release_temp/include/harfbuzz/" \
                    -DHarfBuzz_LIBRARY="$(cygpath -m ${stage})/release_temp/lib/harfbuzz.lib"

                cmake --build . --config Release
                cmake --install . --config Release
            popd
        popd

        pushd "$HARFBUZZ_SOURCE_DIR"
            mkdir -p "build_debug"
            pushd "build_debug"
                cmake -G Ninja .. -DCMAKE_BUILD_TYPE=Debug -DBUILD_SHARED_LIBS:BOOL=OFF \
                    -DCMAKE_INSTALL_PREFIX="$(cygpath -m $stage)/debug" \
                    -DHB_HAVE_FREETYPE=ON \
                    -DFREETYPE_INCLUDE_DIRS="$(cygpath -m $stage)/debug/include/freetype2/" \
                    -DFREETYPE_LIBRARIES="$(cygpath -m $stage)/debug/lib/freetyped.lib"

                cmake --build . --config Debug
                cmake --install . --config Debug
            popd

            mkdir -p "build_release"
            pushd "build_release"
                cmake -G Ninja .. -DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED_LIBS:BOOL=OFF \
                    -DCMAKE_INSTALL_PREFIX="$(cygpath -m $stage)/release" \
                    -DHB_HAVE_FREETYPE=ON \
                    -DFREETYPE_INCLUDE_DIRS="$(cygpath -m $stage)/release/include/freetype2/" \
                    -DFREETYPE_LIBRARIES="$(cygpath -m $stage)/release/lib/freetype.lib"

                cmake --build . --config Release
                cmake --install . --config Release
            popd
        popd

        # Copy libraries
        cp -a ${stage}/debug/lib/*.lib ${stage}/lib/debug/
        cp -a ${stage}/release/lib/*.lib ${stage}/lib/release/

        # copy headers
        cp -a $stage/release/include/* $stage/include/
    ;;

    darwin*)
        # Setup build flags
        C_OPTS_X86="-arch x86_64 $LL_BUILD_RELEASE_CFLAGS"
        C_OPTS_ARM64="-arch arm64 $LL_BUILD_RELEASE_CFLAGS"
        CXX_OPTS_X86="-arch x86_64 $LL_BUILD_RELEASE_CXXFLAGS"
        CXX_OPTS_ARM64="-arch arm64 $LL_BUILD_RELEASE_CXXFLAGS"
        LINK_OPTS_X86="-arch x86_64 $LL_BUILD_RELEASE_LINKER"
        LINK_OPTS_ARM64="-arch arm64 $LL_BUILD_RELEASE_LINKER"

        # deploy target
        export MACOSX_DEPLOYMENT_TARGET=${LL_BUILD_DARWIN_BASE_DEPLOY_TARGET}

        # create staging dir structure
        mkdir -p "$stage/include/freetype2"
        mkdir -p "$stage/lib/release"

        pushd "$FREETYPELIB_SOURCE_DIR"
            mkdir -p "build_release_x86_temp"
            pushd "build_release_x86_temp"
                CFLAGS="$C_OPTS_X86" \
                CXXFLAGS="$CXX_OPTS_X86" \
                LDFLAGS="$LINK_OPTS_X86" \
                cmake .. -G Ninja -DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED_LIBS:BOOL=OFF \
                    -DCMAKE_C_FLAGS="$C_OPTS_X86" \
                    -DCMAKE_CXX_FLAGS="$CXX_OPTS_X86" \
                    -DCMAKE_OSX_ARCHITECTURES:STRING=x86_64 \
                    -DCMAKE_OSX_DEPLOYMENT_TARGET=${MACOSX_DEPLOYMENT_TARGET} \
                    -DCMAKE_MACOSX_RPATH=YES \
                    -DCMAKE_INSTALL_PREFIX="$stage/release_x86_temp" \
                    -DFT_REQUIRE_ZLIB=ON \
                    -DFT_REQUIRE_PNG=ON \
                    -DFT_DISABLE_HARFBUZZ=ON \
                    -DFT_DISABLE_BZIP2=ON \
                    -DFT_DISABLE_BROTLI=ON \
                    -DPNG_INCLUDE_DIRS="${stage}/packages/include/libpng16/" \
                    -DPNG_LIBRARIES="${stage}/packages/lib/release/libpng16.a" \
                    -DZLIB_INCLUDE_DIRS="${stage}/packages/include/zlib/" \
                    -DZLIB_LIBRARIES="${stage}/packages/lib/release/libz.a" \
                    -DZLIB_LIBRARY_DIRS="${stage}/packages/lib"

                cmake --build . --config Release
                cmake --install . --config Release

                # conditionally run unit tests
                if [ "${DISABLE_UNIT_TESTS:-0}" = "0" ]; then
                    ctest -C Release
                fi
            popd
        popd

        pushd "$HARFBUZZ_SOURCE_DIR"
            mkdir -p "build_release_x86_temp"
            pushd "build_release_x86_temp"
                CFLAGS="$C_OPTS_X86" \
                CXXFLAGS="$CXX_OPTS_X86" \
                LDFLAGS="$LINK_OPTS_X86" \
                cmake .. -G Ninja -DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED_LIBS:BOOL=OFF \
                    -DCMAKE_C_FLAGS="$C_OPTS_X86" \
                    -DCMAKE_CXX_FLAGS="$CXX_OPTS_X86" \
                    -DCMAKE_OSX_ARCHITECTURES:STRING=x86_64 \
                    -DCMAKE_OSX_DEPLOYMENT_TARGET=${MACOSX_DEPLOYMENT_TARGET} \
                    -DCMAKE_MACOSX_RPATH=YES \
                    -DCMAKE_INSTALL_PREFIX="$stage/release_x86_temp" \
                    -DHB_HAVE_FREETYPE=ON \
                    -DFREETYPE_INCLUDE_DIRS="$stage/release_x86_temp/include/freetype2/" \
                    -DFREETYPE_LIBRARIES="$stage/release_x86_temp/lib/libfreetype.a"

                cmake --build . --config Release
                cmake --install . --config Release
            popd
        popd

        pushd "$FREETYPELIB_SOURCE_DIR"
            mkdir -p "build_release_x86"
            pushd "build_release_x86"
                CFLAGS="$C_OPTS_X86" \
                CXXFLAGS="$CXX_OPTS_X86" \
                LDFLAGS="$LINK_OPTS_X86" \
                cmake .. -G Ninja -DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED_LIBS:BOOL=OFF \
                    -DCMAKE_C_FLAGS="$C_OPTS_X86" \
                    -DCMAKE_CXX_FLAGS="$CXX_OPTS_X86" \
                    -DCMAKE_OSX_ARCHITECTURES:STRING=x86_64 \
                    -DCMAKE_OSX_DEPLOYMENT_TARGET=${MACOSX_DEPLOYMENT_TARGET} \
                    -DCMAKE_MACOSX_RPATH=YES \
                    -DCMAKE_INSTALL_PREFIX="$stage/release_x86" \
                    -DFT_REQUIRE_ZLIB=ON \
                    -DFT_REQUIRE_PNG=ON \
                    -DFT_REQUIRE_HARFBUZZ=ON \
                    -DFT_DISABLE_BZIP2=ON \
                    -DFT_DISABLE_BROTLI=ON \
                    -DPNG_INCLUDE_DIRS="${stage}/packages/include/libpng16/" \
                    -DPNG_LIBRARIES="${stage}/packages/lib/release/libpng16.a" \
                    -DZLIB_INCLUDE_DIRS="${stage}/packages/include/zlib/" \
                    -DZLIB_LIBRARIES="${stage}/packages/lib/release/libz.a" \
                    -DZLIB_LIBRARY_DIRS="${stage}/packages/lib" \
                    -DHarfBuzz_INCLUDE_DIRS="${stage}/release_x86_temp/include/harfbuzz/" \
                    -DHarfBuzz_LIBRARY="${stage}/release_x86_temp/lib/libharfbuzz.a"

                cmake --build . --config Release
                cmake --install . --config Release

                # conditionally run unit tests
                if [ "${DISABLE_UNIT_TESTS:-0}" = "0" ]; then
                    ctest -C Release
                fi
            popd
        popd

        pushd "$HARFBUZZ_SOURCE_DIR"
            mkdir -p "build_release_x86"
            pushd "build_release_x86"
                CFLAGS="$C_OPTS_X86" \
                CXXFLAGS="$CXX_OPTS_X86" \
                LDFLAGS="$LINK_OPTS_X86" \
                cmake .. -G Ninja -DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED_LIBS:BOOL=OFF \
                    -DCMAKE_C_FLAGS="$C_OPTS_X86" \
                    -DCMAKE_CXX_FLAGS="$CXX_OPTS_X86" \
                    -DCMAKE_OSX_ARCHITECTURES:STRING=x86_64 \
                    -DCMAKE_OSX_DEPLOYMENT_TARGET=${MACOSX_DEPLOYMENT_TARGET} \
                    -DCMAKE_MACOSX_RPATH=YES \
                    -DCMAKE_INSTALL_PREFIX="$stage/release_x86" \
                    -DHB_HAVE_FREETYPE=ON \
                    -DFREETYPE_INCLUDE_DIRS="$stage/release_x86/include/freetype2/" \
                    -DFREETYPE_LIBRARIES="$stage/release_x86/lib/libfreetype.a"

                cmake --build . --config Release
                cmake --install . --config Release
            popd
        popd

        pushd "$FREETYPELIB_SOURCE_DIR"
            mkdir -p "build_release_arm64_temp"
            pushd "build_release_arm64_temp"
                CFLAGS="$C_OPTS_ARM64" \
                CXXFLAGS="$CXX_OPTS_ARM64" \
                LDFLAGS="$LINK_OPTS_ARM64" \
                cmake .. -G Ninja -DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED_LIBS:BOOL=OFF \
                    -DCMAKE_C_FLAGS="$C_OPTS_ARM64" \
                    -DCMAKE_CXX_FLAGS="$CXX_OPTS_ARM64" \
                    -DCMAKE_OSX_ARCHITECTURES:STRING=arm64 \
                    -DCMAKE_OSX_DEPLOYMENT_TARGET=${MACOSX_DEPLOYMENT_TARGET} \
                    -DCMAKE_MACOSX_RPATH=YES \
                    -DCMAKE_INSTALL_PREFIX="$stage/release_arm64_temp" \
                    -DFT_REQUIRE_ZLIB=ON \
                    -DFT_REQUIRE_PNG=ON \
                    -DFT_DISABLE_HARFBUZZ=ON \
                    -DFT_DISABLE_BZIP2=ON \
                    -DFT_DISABLE_BROTLI=ON \
                    -DPNG_INCLUDE_DIRS="${stage}/packages/include/libpng16/" \
                    -DPNG_LIBRARIES="${stage}/packages/lib/release/libpng16.a" \
                    -DZLIB_INCLUDE_DIRS="${stage}/packages/include/zlib/" \
                    -DZLIB_LIBRARIES="${stage}/packages/lib/release/libz.a" \
                    -DZLIB_LIBRARY_DIRS="${stage}/packages/lib"

                cmake --build . --config Release
                cmake --install . --config Release

                # conditionally run unit tests
                if [ "${DISABLE_UNIT_TESTS:-0}" = "0" ]; then
                    ctest -C Release
                fi
            popd
        popd

        pushd "$HARFBUZZ_SOURCE_DIR"
            mkdir -p "build_release_arm64_temp"
            pushd "build_release_arm64_temp"
                CFLAGS="$C_OPTS_ARM64" \
                CXXFLAGS="$CXX_OPTS_ARM64" \
                LDFLAGS="$LINK_OPTS_ARM64" \
                cmake .. -G Ninja -DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED_LIBS:BOOL=OFF \
                    -DCMAKE_C_FLAGS="$C_OPTS_ARM64" \
                    -DCMAKE_CXX_FLAGS="$CXX_OPTS_ARM64" \
                    -DCMAKE_OSX_ARCHITECTURES:STRING=arm64 \
                    -DCMAKE_OSX_DEPLOYMENT_TARGET=${MACOSX_DEPLOYMENT_TARGET} \
                    -DCMAKE_MACOSX_RPATH=YES \
                    -DCMAKE_INSTALL_PREFIX="$stage/release_arm64_temp" \
                    -DHB_HAVE_FREETYPE=ON \
                    -DFREETYPE_INCLUDE_DIRS="$stage/release_arm64_temp/include/freetype2/" \
                    -DFREETYPE_LIBRARIES="$stage/release_arm64_temp/lib/libfreetype.a"

                cmake --build . --config Release
                cmake --install . --config Release
            popd
        popd

        pushd "$FREETYPELIB_SOURCE_DIR"
            mkdir -p "build_release_arm64"
            pushd "build_release_arm64"
                CFLAGS="$C_OPTS_ARM64" \
                CXXFLAGS="$CXX_OPTS_ARM64" \
                LDFLAGS="$LINK_OPTS_ARM64" \
                cmake .. -G Ninja -DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED_LIBS:BOOL=OFF \
                    -DCMAKE_C_FLAGS="$C_OPTS_ARM64" \
                    -DCMAKE_CXX_FLAGS="$CXX_OPTS_ARM64" \
                    -DCMAKE_OSX_ARCHITECTURES:STRING=arm64 \
                    -DCMAKE_OSX_DEPLOYMENT_TARGET=${MACOSX_DEPLOYMENT_TARGET} \
                    -DCMAKE_MACOSX_RPATH=YES \
                    -DCMAKE_INSTALL_PREFIX="$stage/release_arm64" \
                    -DFT_REQUIRE_ZLIB=ON \
                    -DFT_REQUIRE_PNG=ON \
                    -DFT_REQUIRE_HARFBUZZ=ON \
                    -DFT_DISABLE_BZIP2=ON \
                    -DFT_DISABLE_BROTLI=ON \
                    -DPNG_INCLUDE_DIRS="${stage}/packages/include/libpng16/" \
                    -DPNG_LIBRARIES="${stage}/packages/lib/release/libpng16.a" \
                    -DZLIB_INCLUDE_DIRS="${stage}/packages/include/zlib/" \
                    -DZLIB_LIBRARIES="${stage}/packages/lib/release/libz.a" \
                    -DZLIB_LIBRARY_DIRS="${stage}/packages/lib" \
                    -DHarfBuzz_INCLUDE_DIRS="${stage}/release_arm64_temp/include/harfbuzz/" \
                    -DHarfBuzz_LIBRARY="${stage}/release_arm64_temp/lib/libharfbuzz.a"

                cmake --build . --config Release
                cmake --install . --config Release

                # conditionally run unit tests
                if [ "${DISABLE_UNIT_TESTS:-0}" = "0" ]; then
                    ctest -C Release
                fi
            popd
        popd

        pushd "$HARFBUZZ_SOURCE_DIR"
            mkdir -p "build_release_arm64"
            pushd "build_release_arm64"
                CFLAGS="$C_OPTS_ARM64" \
                CXXFLAGS="$CXX_OPTS_ARM64" \
                LDFLAGS="$LINK_OPTS_ARM64" \
                cmake .. -G Ninja -DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED_LIBS:BOOL=OFF \
                    -DCMAKE_C_FLAGS="$C_OPTS_ARM64" \
                    -DCMAKE_CXX_FLAGS="$CXX_OPTS_ARM64" \
                    -DCMAKE_OSX_ARCHITECTURES:STRING=arm64 \
                    -DCMAKE_OSX_DEPLOYMENT_TARGET=${MACOSX_DEPLOYMENT_TARGET} \
                    -DCMAKE_MACOSX_RPATH=YES \
                    -DCMAKE_INSTALL_PREFIX="$stage/release_arm64" \
                    -DHB_HAVE_FREETYPE=ON \
                    -DFREETYPE_INCLUDE_DIRS="$stage/release_arm64/include/freetype2/" \
                    -DFREETYPE_LIBRARIES="$stage/release_arm64/lib/libfreetype.a"

                cmake --build . --config Release
                cmake --install . --config Release
            popd
        popd

        # create fat libraries
        lipo -create ${stage}/release_x86/lib/libfreetype.a ${stage}/release_arm64/lib/libfreetype.a -output ${stage}/lib/release/libfreetype.a
        lipo -create ${stage}/release_x86/lib/libharfbuzz.a ${stage}/release_arm64/lib/libharfbuzz.a -output ${stage}/lib/release/libharfbuzz.a
        lipo -create ${stage}/release_x86/lib/libharfbuzz-subset.a ${stage}/release_arm64/lib/libharfbuzz-subset.a -output ${stage}/lib/release/libharfbuzz-subset.a

        # copy headers
        mv $stage/release_x86/include/* $stage/include/
    ;;

    linux*)
        # Linux build environment at Linden comes pre-polluted with stuff that can
        # seriously damage 3rd-party builds.  Environmental garbage you can expect
        # includes:
        #
        #    DISTCC_POTENTIAL_HOSTS     arch           root        CXXFLAGS
        #    DISTCC_LOCATION            top            branch      CC
        #    DISTCC_HOSTS               build_name     suffix      CXX
        #    LSDISTCC_ARGS              repo           prefix      CFLAGS
        #    cxx_version                AUTOBUILD      SIGN        CPPFLAGS
        #
        # So, clear out bits that shouldn't affect our configure-directed build
        # but which do nonetheless.
        #
        unset DISTCC_HOSTS CFLAGS CPPFLAGS CXXFLAGS

        # Default target per --address-size
        opts_c="${TARGET_OPTS:--m$AUTOBUILD_ADDRSIZE $LL_BUILD_RELEASE_CFLAGS}"
        opts_cxx="${TARGET_OPTS:--m$AUTOBUILD_ADDRSIZE $LL_BUILD_RELEASE_CXXFLAGS}"

        # Handle any deliberate platform targeting
        if [ -z "${TARGET_CPPFLAGS:-}" ]; then
            # Remove sysroot contamination from build environment
            unset CPPFLAGS
        else
            # Incorporate special pre-processing flags
            export CPPFLAGS="$TARGET_CPPFLAGS"
        fi

        # create staging dir structure
        mkdir -p "$stage/include"
        mkdir -p "$stage/lib"

        pushd "$FREETYPELIB_SOURCE_DIR"
            mkdir -p "build_release_temp"
            pushd "build_release_temp"
                CFLAGS="$opts_c" \
                cmake .. -GNinja -DBUILD_SHARED_LIBS:BOOL=OFF \
                    -DCMAKE_BUILD_TYPE="Release" \
                    -DCMAKE_C_FLAGS="$opts_c" \
                    -DCMAKE_INSTALL_PREFIX="$stage/release_temp" \
                    -DFT_REQUIRE_ZLIB=ON \
                    -DFT_REQUIRE_PNG=ON \
                    -DFT_DISABLE_HARFBUZZ=ON \
                    -DFT_DISABLE_BZIP2=ON \
                    -DFT_DISABLE_BROTLI=ON \
                    -DPNG_INCLUDE_DIRS="${stage}/packages/include/libpng16/" \
                    -DPNG_LIBRARIES="${stage}/packages/lib/libpng16.a" \
                    -DZLIB_INCLUDE_DIRS="${stage}/packages/include/zlib/" \
                    -DZLIB_LIBRARIES="${stage}/packages/lib/libz.a"

                cmake --build . --config Release
                cmake --install . --config Release

                # conditionally run unit tests
                if [ "${DISABLE_UNIT_TESTS:-0}" = "0" ]; then
                    ctest -C Release
                fi
            popd
        popd

        pushd "$HARFBUZZ_SOURCE_DIR"
            mkdir -p "build_release_temp"
            pushd "build_release_temp"
                CFLAGS="$opts_c" \
                cmake -GNinja .. -DBUILD_SHARED_LIBS:BOOL=OFF \
                    -DCMAKE_BUILD_TYPE=Release \
                    -DCMAKE_C_FLAGS="$opts_c" \
                    -DCMAKE_INSTALL_PREFIX="$stage/release_temp" \
                    -DHB_HAVE_FREETYPE=ON \
                    -DFREETYPE_INCLUDE_DIRS="$stage/release_temp/include/freetype2/" \
                    -DFREETYPE_LIBRARIES="$stage/release_temp/lib/libfreetype.a"

                cmake --build . --config Release
                cmake --install . --config Release
            popd
        popd

        pushd "$FREETYPELIB_SOURCE_DIR"
            mkdir -p "build_release"
            pushd "build_release"
                CFLAGS="$opts_c" \
                cmake .. -GNinja -DBUILD_SHARED_LIBS:BOOL=OFF \
                    -DCMAKE_BUILD_TYPE="Release" \
                    -DCMAKE_C_FLAGS="$opts_c" \
                    -DCMAKE_INSTALL_PREFIX="$stage" \
                    -DFT_REQUIRE_ZLIB=ON \
                    -DFT_REQUIRE_PNG=ON \
                    -DFT_REQUIRE_HARFBUZZ=ON \
                    -DFT_DISABLE_BZIP2=ON \
                    -DFT_DISABLE_BROTLI=ON \
                    -DPNG_INCLUDE_DIRS="${stage}/packages/include/libpng16/" \
                    -DPNG_LIBRARIES="${stage}/packages/lib/libpng16.a" \
                    -DZLIB_INCLUDE_DIRS="${stage}/packages/include/zlib/" \
                    -DZLIB_LIBRARIES="${stage}/packages/lib/libz.a" \
                    -DHarfBuzz_INCLUDE_DIRS="${stage}/release_temp/include/harfbuzz/" \
                    -DHarfBuzz_LIBRARY="${stage}/release_temp/lib/libharfbuzz.a"

                cmake --build . --config Release
                cmake --install . --config Release

                # conditionally run unit tests
                if [ "${DISABLE_UNIT_TESTS:-0}" = "0" ]; then
                    ctest -C Release
                fi
            popd
        popd

        pushd "$HARFBUZZ_SOURCE_DIR"
            mkdir -p "build_release"
            pushd "build_release"
                CFLAGS="$opts_c" \
                cmake -GNinja .. -DBUILD_SHARED_LIBS:BOOL=OFF \
                    -DCMAKE_BUILD_TYPE=Release \
                    -DCMAKE_C_FLAGS="$opts_c" \
                    -DCMAKE_INSTALL_PREFIX="$stage" \
                    -DHB_HAVE_FREETYPE=ON \
                    -DFREETYPE_INCLUDE_DIRS="$stage/include/freetype2/" \
                    -DFREETYPE_LIBRARIES="$stage/lib/libfreetype.a"

                cmake --build . --config Release
                cmake --install . --config Release
            popd
        popd
    ;;
esac

mkdir -p "$stage/LICENSES"
cp $FREETYPELIB_SOURCE_DIR/LICENSE.TXT "$stage/LICENSES/freetype.txt"
cp $HARFBUZZ_SOURCE_DIR/COPYING "$stage/LICENSES/harfbuzz.txt"
