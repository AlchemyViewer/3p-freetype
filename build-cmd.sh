#!/usr/bin/env bash

cd "$(dirname "$0")"

# turn on verbose debugging output for parabuild logs.
exec 4>&1; export BASH_XTRACEFD=4; set -x
# make errors fatal
set -e
# complain about unset env variables
set -u

FREETYPELIB_SOURCE_DIR="freetype"

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

# load autobuild provided shell functions and variables
source_environment_tempfile="$stage/source_environment.sh"
"$autobuild" source_environment > "$source_environment_tempfile"
. "$source_environment_tempfile"

# remove_cxxstd apply_patch
source "$(dirname "$AUTOBUILD_VARIABLES_FILE")/functions"

apply_patch "$top/patches/update-cmake-version-compat.patch" "$FREETYPELIB_SOURCE_DIR"

[ -f "$stage"/packages/include/zlib-ng/zlib.h ] || fail "You haven't installed packages yet."

pushd "$FREETYPELIB_SOURCE_DIR"
    case "$AUTOBUILD_PLATFORM" in

        windows*)
            load_vsvars

            for arch in sse avx2 arm64 ; do
                platform_target="x64"
                if [[ "$arch" == "arm64" ]]; then
                    platform_target="ARM64"
                fi

                mkdir -p "build_debug_$arch"
                pushd "build_debug_$arch"
                    opts="$(replace_switch /Zi /Z7 $LL_BUILD_DEBUG)"
                    if [[ "$arch" == "avx2" ]]; then
                        opts="$(replace_switch /arch:SSE4.2 /arch:AVX2 $opts)"
                    elif [[ "$arch" == "arm64" ]]; then
                        opts="$(remove_switch /arch:SSE4.2 $opts)"
                    fi
                    plainopts="$(remove_switch /GR $(remove_cxxstd $opts))"

                    cmake .. -G "$AUTOBUILD_WIN_CMAKE_GEN" -A "$platform_target" \
                        -DCMAKE_CONFIGURATION_TYPES=Debug -DBUILD_SHARED_LIBS:BOOL=OFF \
                        -DCMAKE_C_FLAGS:STRING="$plainopts" \
                        -DCMAKE_CXX_FLAGS:STRING="$opts" \
                        -DCMAKE_MSVC_DEBUG_INFORMATION_FORMAT="Embedded" \
                        -DCMAKE_INSTALL_PREFIX="$(cygpath -m $stage)" \
                        -DCMAKE_INSTALL_LIBDIR="$(cygpath -m "$stage/lib/$arch/debug")" \
                        -DFT_REQUIRE_ZLIB=ON \
                        -DFT_REQUIRE_PNG=ON \
                        -DFT_REQUIRE_BROTLI=ON \
                        -DFT_DISABLE_HARFBUZZ=ON \
                        -DFT_DISABLE_BZIP2=ON \
                        -DZLIB_INCLUDE_DIR="$(cygpath -m "$stage/packages/include/zlib-ng/")" \
                        -DZLIB_LIBRARY="$(cygpath -m "$stage/packages/lib/$arch/debug/zlibd.lib")" \
                        -DPNG_PNG_INCLUDE_DIR="$(cygpath -m "${stage}/packages/include/libpng16/")" \
                        -DPNG_LIBRARY="$(cygpath -m "${stage}/packages/lib/$arch/debug/libpng16.lib")" \
                        -DBROTLIDEC_INCLUDE_DIRS="$(cygpath -m "${stage}/packages/include/")" \
                        -DBROTLIDEC_LIBRARIES="$(cygpath -m "${stage}/packages/lib/$arch/debug/brotlidec.lib;${stage}/packages/lib/sse/debug/brotlicommon.lib")"

                    cmake --build . --config Debug
                    cmake --install . --config Debug
                popd

                mkdir -p "build_release_$arch"
                pushd "build_release_$arch"
                    opts="$(replace_switch /Zi /Z7 $LL_BUILD_RELEASE)"
                    if [[ "$arch" == "avx2" ]]; then
                        opts="$(replace_switch /arch:SSE4.2 /arch:AVX2 $opts)"
                    elif [[ "$arch" == "arm64" ]]; then
                        opts="$(remove_switch /arch:SSE4.2 $opts)"
                    fi
                    plainopts="$(remove_switch /GR $(remove_cxxstd $opts))"

                    cmake .. -G "$AUTOBUILD_WIN_CMAKE_GEN" -A "$platform_target" \
                        -DCMAKE_CONFIGURATION_TYPES=Release -DBUILD_SHARED_LIBS:BOOL=OFF \
                        -DCMAKE_C_FLAGS:STRING="$plainopts" \
                        -DCMAKE_CXX_FLAGS:STRING="$opts" \
                        -DCMAKE_MSVC_DEBUG_INFORMATION_FORMAT="Embedded" \
                        -DCMAKE_INSTALL_PREFIX="$(cygpath -m $stage)" \
                        -DCMAKE_INSTALL_LIBDIR="$(cygpath -m "$stage/lib/$arch/release")" \
                        -DFT_REQUIRE_ZLIB=ON \
                        -DFT_REQUIRE_PNG=ON \
                        -DFT_REQUIRE_BROTLI=ON \
                        -DFT_DISABLE_HARFBUZZ=ON \
                        -DFT_DISABLE_BZIP2=ON \
                        -DZLIB_INCLUDE_DIR="$(cygpath -m "$stage/packages/include/zlib-ng/")" \
                        -DZLIB_LIBRARY="$(cygpath -m "$stage/packages/lib/$arch/release/zlib.lib")" \
                        -DPNG_PNG_INCLUDE_DIR="$(cygpath -m "${stage}/packages/include/libpng16/")" \
                        -DPNG_LIBRARY="$(cygpath -m "${stage}/packages/lib/$arch/release/libpng16.lib")" \
                        -DBROTLIDEC_INCLUDE_DIRS="$(cygpath -m "${stage}/packages/include/")" \
                        -DBROTLIDEC_LIBRARIES="$(cygpath -m "${stage}/packages/lib/$arch/release/brotlidec.lib;${stage}/packages/lib/$arch/release/brotlicommon.lib")"


                    cmake --build . --config Release
                    cmake --install . --config Release
                popd
            done
        ;;

        darwin*)
            export MACOSX_DEPLOYMENT_TARGET="$LL_BUILD_DARWIN_DEPLOY_TARGET"

            for arch in x86_64 arm64 ; do
                ARCH_ARGS="-arch $arch"
                opts="${TARGET_OPTS:-$ARCH_ARGS $LL_BUILD_RELEASE}"
                cc_opts="$(remove_cxxstd $opts)"
                ld_opts="$ARCH_ARGS"

                mkdir -p "build_$arch"
                pushd "build_$arch"
                    CFLAGS="$cc_opts" \
                    CXXFLAGS="$opts" \
                    LDFLAGS="$ld_opts" \
                    cmake .. -G Ninja -DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED_LIBS:BOOL=OFF \
                        -DCMAKE_C_FLAGS="$cc_opts" \
                        -DCMAKE_CXX_FLAGS="$opts" \
                        -DCMAKE_OSX_ARCHITECTURES:STRING="$arch" \
                        -DCMAKE_OSX_DEPLOYMENT_TARGET=${MACOSX_DEPLOYMENT_TARGET} \
                        -DCMAKE_MACOSX_RPATH=YES \
                        -DCMAKE_INSTALL_PREFIX="$stage" \
                        -DCMAKE_INSTALL_LIBDIR="$stage/lib/release/$arch" \
                        -DFT_REQUIRE_ZLIB=ON \
                        -DFT_REQUIRE_PNG=ON \
                        -DFT_DISABLE_HARFBUZZ=ON \
                        -DFT_DISABLE_BZIP2=ON \
                        -DFT_DISABLE_BROTLI=ON \
                        -DPNG_PNG_INCLUDE_DIR="${stage}/packages/include/libpng16/" \
                        -DPNG_LIBRARY="${stage}/packages/lib/release/libpng16.a" \
                        -DZLIB_INCLUDE_DIR="${stage}/packages/include/zlib-ng/" \
                        -DZLIB_LIBRARY="${stage}/packages/lib/release/libz.a"

                    cmake --build . --config Release
                    cmake --install . --config Release

                    # conditionally run unit tests
                    if [ "${DISABLE_UNIT_TESTS:-0}" = "0" ]; then
                        ctest -C Release
                    fi
                popd
            done

            # Create universal library
            lipo -create -output "$stage/lib/release/libfreetype.a" "$stage/lib/release/x86_64/libfreetype.a" "$stage/lib/release/arm64/libfreetype.a"
        ;;

        linux*)
            # Default target per AUTOBUILD_ADDRSIZE
            opts="${TARGET_OPTS:--m$AUTOBUILD_ADDRSIZE $LL_BUILD_RELEASE}"
            plainopts="$(remove_cxxstd $opts)"

            mkdir -p "build"
            pushd "build"
                cmake .. -G Ninja -DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED_LIBS:BOOL=OFF \
                    -DCMAKE_C_FLAGS="$plainopts" \
                    -DCMAKE_CXX_FLAGS="$opts" \
                    -DCMAKE_INSTALL_PREFIX="$stage" \
                    -DCMAKE_INSTALL_LIBDIR="$stage/lib/release" \
                    -DFT_REQUIRE_ZLIB=ON \
                    -DFT_REQUIRE_PNG=ON \
                    -DFT_DISABLE_HARFBUZZ=ON \
                    -DFT_DISABLE_BZIP2=ON \
                    -DFT_DISABLE_BROTLI=ON \
                    -DPNG_PNG_INCLUDE_DIR="${stage}/packages/include/libpng16/" \
                    -DPNG_LIBRARY="${stage}/packages/lib/release/libpng16.a" \
                    -DZLIB_INCLUDE_DIR="${stage}/packages/include/zlib-ng/" \
                    -DZLIB_LIBRARY="${stage}/packages/lib/release/libz.a"

                cmake --build . --config Release
                cmake --install . --config Release

                # conditionally run unit tests
                if [ "${DISABLE_UNIT_TESTS:-0}" = "0" ]; then
                    ctest -C Release
                fi
            popd
        ;;
    esac
    mkdir -p "$stage/LICENSES"
    cp LICENSE.TXT "$stage/LICENSES/freetype.txt"
popd
