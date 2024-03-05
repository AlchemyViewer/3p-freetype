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

if [ "$OSTYPE" = "cygwin" ] ; then
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

[ -f "$stage"/packages/include/zlib/zlib.h ] || fail "You haven't installed packages yet."

# extract APR version into VERSION.txt
FREETYPE_INCLUDE_DIR="${FREETYPELIB_SOURCE_DIR}/include/freetype"
major_version="$(sed -n -E 's/#[[:space:]]*define[[:space:]]+FREETYPE_MAJOR[[:space:]]+([0-9]+)/\1/p' "${FREETYPE_INCLUDE_DIR}/freetype.h")"
minor_version="$(sed -n -E 's/#[[:space:]]*define[[:space:]]+FREETYPE_MINOR[[:space:]]+([0-9]+)/\1/p' "${FREETYPE_INCLUDE_DIR}/freetype.h")"
patch_version="$(sed -n -E 's/#[[:space:]]*define[[:space:]]+FREETYPE_PATCH[[:space:]]+([0-9]+)/\1/p' "${FREETYPE_INCLUDE_DIR}/freetype.h")"
version="${major_version}.${minor_version}.${patch_version}"
echo "${version}" > "${stage}/VERSION.txt"

# create staging dir structure
mkdir -p "$stage/include/freetype2"
mkdir -p "$stage/lib/debug"
mkdir -p "$stage/lib/release"

case "$AUTOBUILD_PLATFORM" in
    windows*)
        load_vsvars

        pushd "$FREETYPELIB_SOURCE_DIR"
            mkdir -p "build_debug_temp"
            pushd "build_debug_temp"
                cmake -G "$AUTOBUILD_WIN_CMAKE_GEN" -A "$AUTOBUILD_WIN_VSPLATFORM" .. -DBUILD_SHARED_LIBS:BOOL=OFF \
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
                cmake -G "$AUTOBUILD_WIN_CMAKE_GEN" -A "$AUTOBUILD_WIN_VSPLATFORM" .. -DBUILD_SHARED_LIBS:BOOL=OFF \
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
                cmake -G "$AUTOBUILD_WIN_CMAKE_GEN" -A "$AUTOBUILD_WIN_VSPLATFORM" .. -DBUILD_SHARED_LIBS:BOOL=OFF \
                    -DCMAKE_INSTALL_PREFIX="$(cygpath -m $stage)/debug_temp" \
                    -DHB_HAVE_FREETYPE=ON \
                    -DFREETYPE_INCLUDE_DIRS="$(cygpath -m $stage)/debug_temp/include/freetype2/" \
                    -DFREETYPE_LIBRARIES="$(cygpath -m $stage)/debug_temp/lib/freetyped.lib"

                cmake --build . --config Debug
                cmake --install . --config Debug
            popd

            mkdir -p "build_release_temp"
            pushd "build_release_temp"
                cmake -G "$AUTOBUILD_WIN_CMAKE_GEN" -A "$AUTOBUILD_WIN_VSPLATFORM" .. -DBUILD_SHARED_LIBS:BOOL=OFF \
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
                cmake -G "$AUTOBUILD_WIN_CMAKE_GEN" -A "$AUTOBUILD_WIN_VSPLATFORM" .. -DBUILD_SHARED_LIBS:BOOL=OFF \
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
                cmake -G "$AUTOBUILD_WIN_CMAKE_GEN" -A "$AUTOBUILD_WIN_VSPLATFORM" .. -DBUILD_SHARED_LIBS:BOOL=OFF \
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
                cmake -G "$AUTOBUILD_WIN_CMAKE_GEN" -A "$AUTOBUILD_WIN_VSPLATFORM" .. -DBUILD_SHARED_LIBS:BOOL=OFF \
                    -DCMAKE_INSTALL_PREFIX="$(cygpath -m $stage)/debug" \
                    -DHB_HAVE_FREETYPE=ON \
                    -DFREETYPE_INCLUDE_DIRS="$(cygpath -m $stage)/debug/include/freetype2/" \
                    -DFREETYPE_LIBRARIES="$(cygpath -m $stage)/debug/lib/freetyped.lib"

                cmake --build . --config Debug
                cmake --install . --config Debug
            popd

            mkdir -p "build_release"
            pushd "build_release"
                cmake -G "$AUTOBUILD_WIN_CMAKE_GEN" -A "$AUTOBUILD_WIN_VSPLATFORM" .. -DBUILD_SHARED_LIBS:BOOL=OFF \
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
        pushd "$FREETYPELIB_SOURCE_DIR"
        # Setup osx sdk platform
        SDKNAME="macosx"
        export SDKROOT=$(xcodebuild -version -sdk ${SDKNAME} Path)

        # Deploy Targets
        X86_DEPLOY=10.15
        ARM64_DEPLOY=11.0

        # Setup build flags
        ARCH_FLAGS_X86="-arch x86_64 -mmacosx-version-min=${X86_DEPLOY} -isysroot ${SDKROOT} -msse4.2"
        ARCH_FLAGS_ARM64="-arch arm64 -mmacosx-version-min=${ARM64_DEPLOY} -isysroot ${SDKROOT}"
        DEBUG_COMMON_FLAGS="-O0 -g -fPIC -DPIC"
        RELEASE_COMMON_FLAGS="-O3 -g -fPIC -DPIC -fstack-protector-strong"
        DEBUG_CFLAGS="$DEBUG_COMMON_FLAGS"
        RELEASE_CFLAGS="$RELEASE_COMMON_FLAGS"
        DEBUG_CXXFLAGS="$DEBUG_COMMON_FLAGS -std=c++17"
        RELEASE_CXXFLAGS="$RELEASE_COMMON_FLAGS -std=c++17"
        DEBUG_CPPFLAGS="-DPIC"
        RELEASE_CPPFLAGS="-DPIC"
        DEBUG_LDFLAGS="-Wl,-headerpad_max_install_names"
        RELEASE_LDFLAGS="-Wl,-headerpad_max_install_names"

        # x86 Deploy Target
        export MACOSX_DEPLOYMENT_TARGET=${X86_DEPLOY}

        mkdir -p "build_debug_x86"
        pushd "build_debug_x86"
            CFLAGS="$ARCH_FLAGS_X86 $DEBUG_CFLAGS" \
            CXXFLAGS="$ARCH_FLAGS_X86 $DEBUG_CXXFLAGS" \
            CPPFLAGS="$DEBUG_CPPFLAGS" \
            LDFLAGS="$ARCH_FLAGS_X86 $DEBUG_LDFLAGS" \
            cmake .. -GXcode -DBUILD_SHARED_LIBS:BOOL=OFF \
                -DCMAKE_C_FLAGS="$ARCH_FLAGS_X86 $DEBUG_CFLAGS" \
                -DCMAKE_CXX_FLAGS="$ARCH_FLAGS_X86 $DEBUG_CXXFLAGS" \
                -DCMAKE_XCODE_ATTRIBUTE_GCC_OPTIMIZATION_LEVEL="0" \
                -DCMAKE_XCODE_ATTRIBUTE_GCC_FAST_MATH=NO \
                -DCMAKE_XCODE_ATTRIBUTE_GCC_GENERATE_DEBUGGING_SYMBOLS=YES \
                -DCMAKE_XCODE_ATTRIBUTE_DEBUG_INFORMATION_FORMAT=dwarf \
                -DCMAKE_XCODE_ATTRIBUTE_LLVM_LTO=NO \
                -DCMAKE_XCODE_ATTRIBUTE_CLANG_X86_VECTOR_INSTRUCTIONS=sse4.2 \
                -DCMAKE_XCODE_ATTRIBUTE_CLANG_CXX_LANGUAGE_STANDARD="c++17" \
                -DCMAKE_XCODE_ATTRIBUTE_CLANG_CXX_LIBRARY="libc++" \
                -DCMAKE_XCODE_ATTRIBUTE_CODE_SIGN_IDENTITY="" \
                -DCMAKE_OSX_ARCHITECTURES:STRING=x86_64 \
                -DCMAKE_OSX_DEPLOYMENT_TARGET=${MACOSX_DEPLOYMENT_TARGET} \
                -DCMAKE_OSX_SYSROOT=${SDKROOT} \
                -DCMAKE_MACOSX_RPATH=YES \
                -DCMAKE_INSTALL_PREFIX="$stage/debug_x86" \
                -DFT_REQUIRE_ZLIB=ON \
                -DFT_REQUIRE_PNG=ON \
                -DFT_DISABLE_HARFBUZZ=ON \
                -DFT_DISABLE_BZIP2=ON \
                -DFT_DISABLE_BROTLI=ON \
                -DPNG_INCLUDE_DIRS="${stage}/packages/include/libpng16/" \
                -DPNG_LIBRARIES="${stage}/packages/lib/debug/libpng16d.a" \
                -DZLIB_INCLUDE_DIRS="${stage}/packages/include/zlib/" \
                -DZLIB_LIBRARIES="${stage}/packages/lib/debug/libz.a" \
                -DZLIB_LIBRARY_DIRS="${stage}/packages/lib"

            cmake --build . --config Debug
            cmake --install . --config Debug

            # conditionally run unit tests
            if [ "${DISABLE_UNIT_TESTS:-0}" = "0" ]; then
                ctest -C Debug
            fi
        popd

        mkdir -p "build_release_x86"
        pushd "build_release_x86"
            CFLAGS="$ARCH_FLAGS_X86 $RELEASE_CFLAGS" \
            CXXFLAGS="$ARCH_FLAGS_X86 $RELEASE_CXXFLAGS" \
            CPPFLAGS="$RELEASE_CPPFLAGS" \
            LDFLAGS="$ARCH_FLAGS_X86 $RELEASE_LDFLAGS" \
            cmake .. -GXcode -DBUILD_SHARED_LIBS:BOOL=OFF \
                -DCMAKE_C_FLAGS="$ARCH_FLAGS_X86 $RELEASE_CFLAGS" \
                -DCMAKE_CXX_FLAGS="$ARCH_FLAGS_X86 $RELEASE_CXXFLAGS" \
                -DCMAKE_XCODE_ATTRIBUTE_GCC_OPTIMIZATION_LEVEL="3" \
                -DCMAKE_XCODE_ATTRIBUTE_GCC_FAST_MATH=NO \
                -DCMAKE_XCODE_ATTRIBUTE_GCC_GENERATE_DEBUGGING_SYMBOLS=YES \
                -DCMAKE_XCODE_ATTRIBUTE_DEBUG_INFORMATION_FORMAT=dwarf \
                -DCMAKE_XCODE_ATTRIBUTE_LLVM_LTO=NO \
                -DCMAKE_XCODE_ATTRIBUTE_CLANG_X86_VECTOR_INSTRUCTIONS=sse4.2 \
                -DCMAKE_XCODE_ATTRIBUTE_CLANG_CXX_LANGUAGE_STANDARD="c++17" \
                -DCMAKE_XCODE_ATTRIBUTE_CLANG_CXX_LIBRARY="libc++" \
                -DCMAKE_XCODE_ATTRIBUTE_CODE_SIGN_IDENTITY="" \
                -DCMAKE_OSX_ARCHITECTURES:STRING=x86_64 \
                -DCMAKE_OSX_DEPLOYMENT_TARGET=${MACOSX_DEPLOYMENT_TARGET} \
                -DCMAKE_OSX_SYSROOT=${SDKROOT} \
                -DCMAKE_MACOSX_RPATH=YES \
                -DCMAKE_INSTALL_PREFIX="$stage/release_x86" \
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

        # arm64 Deploy Target
        export MACOSX_DEPLOYMENT_TARGET=${ARM64_DEPLOY}

        mkdir -p "build_debug_arm64"
        pushd "build_debug_arm64"
            CFLAGS="$ARCH_FLAGS_ARM64 $DEBUG_CFLAGS" \
            CXXFLAGS="$ARCH_FLAGS_ARM64 $DEBUG_CXXFLAGS" \
            CPPFLAGS="$DEBUG_CPPFLAGS" \
            LDFLAGS="$ARCH_FLAGS_ARM64 $DEBUG_LDFLAGS" \
            cmake .. -GXcode -DBUILD_SHARED_LIBS:BOOL=OFF \
                -DCMAKE_C_FLAGS="$ARCH_FLAGS_ARM64 $DEBUG_CFLAGS" \
                -DCMAKE_CXX_FLAGS="$ARCH_FLAGS_ARM64 $DEBUG_CXXFLAGS" \
                -DCMAKE_XCODE_ATTRIBUTE_GCC_OPTIMIZATION_LEVEL="0" \
                -DCMAKE_XCODE_ATTRIBUTE_GCC_FAST_MATH=NO \
                -DCMAKE_XCODE_ATTRIBUTE_GCC_GENERATE_DEBUGGING_SYMBOLS=YES \
                -DCMAKE_XCODE_ATTRIBUTE_DEBUG_INFORMATION_FORMAT=dwarf \
                -DCMAKE_XCODE_ATTRIBUTE_LLVM_LTO=NO \
                -DCMAKE_XCODE_ATTRIBUTE_CLANG_CXX_LANGUAGE_STANDARD="c++17" \
                -DCMAKE_XCODE_ATTRIBUTE_CLANG_CXX_LIBRARY="libc++" \
                -DCMAKE_XCODE_ATTRIBUTE_CODE_SIGN_IDENTITY="" \
                -DCMAKE_OSX_ARCHITECTURES:STRING=arm64 \
                -DCMAKE_OSX_DEPLOYMENT_TARGET=${MACOSX_DEPLOYMENT_TARGET} \
                -DCMAKE_OSX_SYSROOT=${SDKROOT} \
                -DCMAKE_MACOSX_RPATH=YES \
                -DCMAKE_INSTALL_PREFIX="$stage/debug_arm64" \
                -DFT_REQUIRE_ZLIB=ON \
                -DFT_REQUIRE_PNG=ON \
                -DFT_DISABLE_HARFBUZZ=ON \
                -DFT_DISABLE_BZIP2=ON \
                -DFT_DISABLE_BROTLI=ON \
                -DPNG_INCLUDE_DIRS="${stage}/packages/include/libpng16/" \
                -DPNG_LIBRARIES="${stage}/packages/lib/debug/libpng16d.a" \
                -DZLIB_INCLUDE_DIRS="${stage}/packages/include/zlib/" \
                -DZLIB_LIBRARIES="${stage}/packages/lib/debug/libz.a" \
                -DZLIB_LIBRARY_DIRS="${stage}/packages/lib"

            cmake --build . --config Debug
            cmake --install . --config Debug

            # conditionally run unit tests
            if [ "${DISABLE_UNIT_TESTS:-0}" = "0" ]; then
                ctest -C Debug
            fi
        popd

        mkdir -p "build_release_arm64"
        pushd "build_release_arm64"
            CFLAGS="$ARCH_FLAGS_ARM64 $RELEASE_CFLAGS" \
            CXXFLAGS="$ARCH_FLAGS_ARM64 $RELEASE_CXXFLAGS" \
            CPPFLAGS="$RELEASE_CPPFLAGS" \
            LDFLAGS="$ARCH_FLAGS_ARM64 $RELEASE_LDFLAGS" \
            cmake .. -GXcode -DBUILD_SHARED_LIBS:BOOL=OFF \
                -DCMAKE_C_FLAGS="$ARCH_FLAGS_ARM64 $RELEASE_CFLAGS" \
                -DCMAKE_CXX_FLAGS="$ARCH_FLAGS_ARM64 $RELEASE_CXXFLAGS" \
                -DCMAKE_XCODE_ATTRIBUTE_GCC_OPTIMIZATION_LEVEL="3" \
                -DCMAKE_XCODE_ATTRIBUTE_GCC_FAST_MATH=NO \
                -DCMAKE_XCODE_ATTRIBUTE_GCC_GENERATE_DEBUGGING_SYMBOLS=YES \
                -DCMAKE_XCODE_ATTRIBUTE_DEBUG_INFORMATION_FORMAT=dwarf \
                -DCMAKE_XCODE_ATTRIBUTE_LLVM_LTO=NO \
                -DCMAKE_XCODE_ATTRIBUTE_CLANG_CXX_LANGUAGE_STANDARD="c++17" \
                -DCMAKE_XCODE_ATTRIBUTE_CLANG_CXX_LIBRARY="libc++" \
                -DCMAKE_XCODE_ATTRIBUTE_CODE_SIGN_IDENTITY="" \
                -DCMAKE_OSX_ARCHITECTURES:STRING=arm64 \
                -DCMAKE_OSX_DEPLOYMENT_TARGET=${MACOSX_DEPLOYMENT_TARGET} \
                -DCMAKE_OSX_SYSROOT=${SDKROOT} \
                -DCMAKE_MACOSX_RPATH=YES \
                -DCMAKE_INSTALL_PREFIX="$stage/release_arm64" \
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

        # create fat libraries
        lipo -create ${stage}/debug_x86/lib/libfreetyped.a ${stage}/debug_arm64/lib/libfreetyped.a -output ${stage}/lib/debug/libfreetyped.a
        lipo -create ${stage}/release_x86/lib/libfreetype.a ${stage}/release_arm64/lib/libfreetype.a -output ${stage}/lib/release/libfreetype.a

        # copy headers
        mv $stage/release_x86/include/freetype2/* $stage/include/freetype2

        popd
    ;;

    linux*)
        # Default target per autobuild build --address-size
        opts="${TARGET_OPTS:--m$AUTOBUILD_ADDRSIZE}"
        DEBUG_COMMON_FLAGS="$opts -Og -g -fPIC -DPIC"
        RELEASE_COMMON_FLAGS="$opts -O3 -g -fPIC -DPIC -fstack-protector-strong -D_FORTIFY_SOURCE=2"
        DEBUG_CFLAGS="$DEBUG_COMMON_FLAGS"
        RELEASE_CFLAGS="$RELEASE_COMMON_FLAGS"
        DEBUG_CXXFLAGS="$DEBUG_COMMON_FLAGS -std=c++17"
        RELEASE_CXXFLAGS="$RELEASE_COMMON_FLAGS -std=c++17"
        DEBUG_CPPFLAGS="-DPIC"
        RELEASE_CPPFLAGS="-DPIC -D_FORTIFY_SOURCE=2"

        pushd "$FREETYPELIB_SOURCE_DIR"
            mkdir -p "build_debug_temp"
            pushd "build_debug_temp"
                CFLAGS="$DEBUG_CFLAGS" \
                CPPFLAGS="$DEBUG_CPPFLAGS" \
                cmake .. -GNinja -DBUILD_SHARED_LIBS:BOOL=OFF \
                    -DCMAKE_BUILD_TYPE="Debug" \
                    -DCMAKE_C_FLAGS="$DEBUG_CFLAGS" \
                    -DCMAKE_INSTALL_PREFIX="$stage/debug_temp" \
                    -DFT_REQUIRE_ZLIB=ON \
                    -DFT_REQUIRE_PNG=ON \
                    -DFT_DISABLE_HARFBUZZ=ON \
                    -DFT_DISABLE_BZIP2=ON \
                    -DFT_DISABLE_BROTLI=ON \
                    -DPNG_INCLUDE_DIRS="${stage}/packages/include/libpng16/" \
                    -DPNG_LIBRARIES="${stage}/packages/lib/debug/libpng16d.a" \
                    -DZLIB_INCLUDE_DIRS="${stage}/packages/include/zlib/" \
                    -DZLIB_LIBRARIES="${stage}/packages/lib/debug/libz.a"

                cmake --build . --config Debug
                cmake --install . --config Debug

                # conditionally run unit tests
                if [ "${DISABLE_UNIT_TESTS:-0}" = "0" ]; then
                    ctest -C Debug
                fi
            popd

            mkdir -p "build_release_temp"
            pushd "build_release_temp"
                CFLAGS="$RELEASE_CFLAGS" \
                CPPFLAGS="$RELEASE_CPPFLAGS" \
                cmake .. -GNinja -DBUILD_SHARED_LIBS:BOOL=OFF \
                    -DCMAKE_BUILD_TYPE="Release" \
                    -DCMAKE_C_FLAGS="$RELEASE_CFLAGS" \
                    -DCMAKE_INSTALL_PREFIX="$stage/release_temp" \
                    -DFT_REQUIRE_ZLIB=ON \
                    -DFT_REQUIRE_PNG=ON \
                    -DFT_DISABLE_HARFBUZZ=ON \
                    -DFT_DISABLE_BZIP2=ON \
                    -DFT_DISABLE_BROTLI=ON \
                    -DPNG_INCLUDE_DIRS="${stage}/packages/include/libpng16/" \
                    -DPNG_LIBRARIES="${stage}/packages/lib/release/libpng16.a" \
                    -DZLIB_INCLUDE_DIRS="${stage}/packages/include/zlib/" \
                    -DZLIB_LIBRARIES="${stage}/packages/lib/release/libz.a"

                cmake --build . --config Release
                cmake --install . --config Release

                # conditionally run unit tests
                if [ "${DISABLE_UNIT_TESTS:-0}" = "0" ]; then
                    ctest -C Release
                fi
            popd
        popd

        pushd "$HARFBUZZ_SOURCE_DIR"
            mkdir -p "build_debug_temp"
            pushd "build_debug_temp"
                CFLAGS="$DEBUG_CFLAGS" \
                CPPFLAGS="$DEBUG_CPPFLAGS" \
                cmake -G "$AUTOBUILD_WIN_CMAKE_GEN" -A "$AUTOBUILD_WIN_VSPLATFORM" .. -DBUILD_SHARED_LIBS:BOOL=OFF \
                    -DCMAKE_INSTALL_PREFIX="$stage/debug_temp" \
                    -DHB_HAVE_FREETYPE=ON \
                    -DFREETYPE_INCLUDE_DIRS="$stage/debug_temp/include/freetype2/" \
                    -DFREETYPE_LIBRARIES="$stage/debug_temp/lib/libfreetyped.a"

                cmake --build . --config Debug
                cmake --install . --config Debug
            popd

            mkdir -p "build_release_temp"
            pushd "build_release_temp"
                CFLAGS="$RELEASE_CFLAGS" \
                CPPFLAGS="$RELEASE_CPPFLAGS" \
                cmake -G "$AUTOBUILD_WIN_CMAKE_GEN" -A "$AUTOBUILD_WIN_VSPLATFORM" .. -DBUILD_SHARED_LIBS:BOOL=OFF \
                    -DCMAKE_INSTALL_PREFIX="$stage/release_temp" \
                    -DHB_HAVE_FREETYPE=ON \
                    -DFREETYPE_INCLUDE_DIRS="$stage/release_temp/include/freetype2/" \
                    -DFREETYPE_LIBRARIES="$stage/release_temp/lib/libfreetype.a"

                cmake --build . --config Release
                cmake --install . --config Release
            popd
        popd

        pushd "$FREETYPELIB_SOURCE_DIR"
            mkdir -p "build_debug"
            pushd "build_debug"
                CFLAGS="$DEBUG_CFLAGS" \
                CPPFLAGS="$DEBUG_CPPFLAGS" \
                cmake .. -GNinja -DBUILD_SHARED_LIBS:BOOL=OFF \
                    -DCMAKE_BUILD_TYPE="Debug" \
                    -DCMAKE_C_FLAGS="$DEBUG_CFLAGS" \
                    -DCMAKE_INSTALL_PREFIX="$stage/debug" \
                    -DFT_REQUIRE_ZLIB=ON \
                    -DFT_REQUIRE_PNG=ON \
                    -DFT_REQUIRE_HARFBUZZ=ON \
                    -DFT_DISABLE_BZIP2=ON \
                    -DFT_DISABLE_BROTLI=ON \
                    -DPNG_INCLUDE_DIRS="${stage}/packages/include/libpng16/" \
                    -DPNG_LIBRARIES="${stage}/packages/lib/debug/libpng16d.a" \
                    -DZLIB_INCLUDE_DIRS="${stage}/packages/include/zlib/" \
                    -DZLIB_LIBRARIES="${stage}/packages/lib/debug/libz.a" \
                    -DHarfBuzz_INCLUDE_DIRS="${stage}/debug_temp/include/harfbuzz/" \
                    -DHarfBuzz_LIBRARY="${stage}/debug_temp/lib/libharfbuzz.a"

                cmake --build . --config Debug
                cmake --install . --config Debug

                # conditionally run unit tests
                if [ "${DISABLE_UNIT_TESTS:-0}" = "0" ]; then
                    ctest -C Debug
                fi
            popd

            mkdir -p "build_release"
            pushd "build_release"
                CFLAGS="$RELEASE_CFLAGS" \
                CPPFLAGS="$RELEASE_CPPFLAGS" \
                cmake .. -GNinja -DBUILD_SHARED_LIBS:BOOL=OFF \
                    -DCMAKE_BUILD_TYPE="Release" \
                    -DCMAKE_C_FLAGS="$RELEASE_CFLAGS" \
                    -DCMAKE_INSTALL_PREFIX="$stage/release" \
                    -DFT_REQUIRE_ZLIB=ON \
                    -DFT_REQUIRE_PNG=ON \
                    -DFT_REQUIRE_HARFBUZZ=ON \
                    -DFT_DISABLE_BZIP2=ON \
                    -DFT_DISABLE_BROTLI=ON \
                    -DPNG_INCLUDE_DIRS="${stage}/packages/include/libpng16/" \
                    -DPNG_LIBRARIES="${stage}/packages/lib/release/libpng16.a" \
                    -DZLIB_INCLUDE_DIRS="${stage}/packages/include/zlib/" \
                    -DZLIB_LIBRARIES="${stage}/packages/lib/release/libz.a" \
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
            mkdir -p "build_debug"
            pushd "build_debug"
                CFLAGS="$DEBUG_CFLAGS" \
                CPPFLAGS="$DEBUG_CPPFLAGS" \
                cmake -G "$AUTOBUILD_WIN_CMAKE_GEN" -A "$AUTOBUILD_WIN_VSPLATFORM" .. -DBUILD_SHARED_LIBS:BOOL=OFF \
                    -DCMAKE_INSTALL_PREFIX="$stage/debug" \
                    -DHB_HAVE_FREETYPE=ON \
                    -DFREETYPE_INCLUDE_DIRS="$stage/debug/include/freetype2/" \
                    -DFREETYPE_LIBRARIES="$stage/debug/lib/libfreetyped.a"

                cmake --build . --config Debug
                cmake --install . --config Debug
            popd

            mkdir -p "build_release"
            pushd "build_release"
                CFLAGS="$RELEASE_CFLAGS" \
                CPPFLAGS="$RELEASE_CPPFLAGS" \
                cmake -G "$AUTOBUILD_WIN_CMAKE_GEN" -A "$AUTOBUILD_WIN_VSPLATFORM" .. -DBUILD_SHARED_LIBS:BOOL=OFF \
                    -DCMAKE_INSTALL_PREFIX="$stage/release" \
                    -DHB_HAVE_FREETYPE=ON \
                    -DFREETYPE_INCLUDE_DIRS="$stage/release/include/freetype2/" \
                    -DFREETYPE_LIBRARIES="$stage/release/lib/libfreetype.a"

                cmake --build . --config Release
                cmake --install . --config Release
            popd
        popd

        # Copy libraries
        cp -a ${stage}/debug/lib/*.a ${stage}/lib/debug/
        cp -a ${stage}/release/lib/*.a ${stage}/lib/release/

        # copy headers
        cp -a $stage/release/include/freetype2/* $stage/include/freetype2/
    ;;
esac

mkdir -p "$stage/LICENSES"
cp $FREETYPELIB_SOURCE_DIR/LICENSE.TXT "$stage/LICENSES/freetype.txt"
cp $HARFBUZZ_SOURCE_DIR/COPYING "$stage/LICENSES/harfbuzz.txt"
