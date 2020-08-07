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

if [ "$OSTYPE" = "cygwin" ] ; then
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

[ -f "$stage"/packages/include/zlib/zlib.h ] || fail "You haven't installed packages yet."

# extract APR version into VERSION.txt
FREETYPE_INCLUDE_DIR="${top}/${FREETYPELIB_SOURCE_DIR}/include/freetype"
major_version="$(sed -n -E 's/#[[:space:]]*define[[:space:]]+FREETYPE_MAJOR[[:space:]]+([0-9]+)/\1/p' "${FREETYPE_INCLUDE_DIR}/freetype.h")"
minor_version="$(sed -n -E 's/#[[:space:]]*define[[:space:]]+FREETYPE_MINOR[[:space:]]+([0-9]+)/\1/p' "${FREETYPE_INCLUDE_DIR}/freetype.h")"
patch_version="$(sed -n -E 's/#[[:space:]]*define[[:space:]]+FREETYPE_PATCH[[:space:]]+([0-9]+)/\1/p' "${FREETYPE_INCLUDE_DIR}/freetype.h")"
version="${major_version}.${minor_version}.${patch_version}"
build=${AUTOBUILD_BUILD_ID:=0}
echo "${version}.${build}" > "${stage}/VERSION.txt"

pushd "$FREETYPELIB_SOURCE_DIR"
    case "$AUTOBUILD_PLATFORM" in

        windows*)
            load_vsvars

            case "$AUTOBUILD_VSVER" in
                "120")
                    verdir="vc2013"
                    ;;
                "150")
                    # We have not yet updated the .sln and .vcxproj files for
                    # VS 2017. Until we do, those projects and their build
                    # outputs will be found in the same places as before.
                    verdir="vc2013"
                    ;;
                *)
                    echo "Unknown AUTOBUILD_VSVER = '$AUTOBUILD_VSVER'" 1>&2 ; exit 1
                    ;;
            esac

            build_sln "builds/win32/$verdir/freetype.sln" "LIB Release|$AUTOBUILD_WIN_VSPLATFORM"

            mkdir -p "$stage/lib/release"
            cp -a "objs/win32/$verdir"/freetype*.lib "$stage/lib/release/freetype.lib"

            mkdir -p "$stage/include/freetype2/"
            cp -a include/ft2build.h "$stage/include/"
            cp -a include/freetype "$stage/include/freetype2/"
        ;;

        darwin*)
            # Darwin build environment at Linden is also pre-polluted like Linux
            # and that affects colladadom builds.  Here are some of the env vars
            # to look out for:
            #
            # AUTOBUILD             GROUPS              LD_LIBRARY_PATH         SIGN
            # arch                  branch              build_*                 changeset
            # helper                here                prefix                  release
            # repo                  root                run_tests               suffix

            opts="${TARGET_OPTS:--arch $AUTOBUILD_CONFIGURE_ARCH $LL_BUILD_RELEASE}"

            # Release
            CFLAGS="$opts" \
                CXXFLAGS="$opts" \
                CPPFLAGS="-I$stage/packages/include/zlib" \
                LDFLAGS="$opts -Wl,-headerpad_max_install_names -L$stage/packages/lib/release -Wl,-unexported_symbols_list,$stage/packages/lib/release/libz_darwin.exp" \
                ./configure --with-pic \
                --prefix="$stage" --libdir="$stage"/lib/release/
            make
            make install

            # conditionally run unit tests
            if [ "${DISABLE_UNIT_TESTS:-0}" = "0" ]; then
                # make test
                echo "No tests"
            fi

            install_name_tool -id "@executable_path/../Resources/libfreetype.6.dylib" "$stage"/lib/release/libfreetype.6.dylib

            make distclean
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
            unset DISTCC_HOSTS CC CXX CFLAGS CPPFLAGS CXXFLAGS

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

            # Handle any deliberate platform targeting
            if [ -z "${TARGET_CPPFLAGS:-}" ]; then
                # Remove sysroot contamination from build environment
                unset CPPFLAGS
            else
                # Incorporate special pre-processing flags
                export CPPFLAGS="$TARGET_CPPFLAGS"
            fi

            # Fix up path for pkgconfig
            if [ -d "$stage/packages/lib/release/pkgconfig" ]; then
                fix_pkgconfig_prefix "$stage/packages"
            fi

            OLD_PKG_CONFIG_PATH="${PKG_CONFIG_PATH:-}"

            # debug configure and build
            export PKG_CONFIG_PATH="$stage/packages/lib/debug/pkgconfig:${OLD_PKG_CONFIG_PATH}"

            # build the debug version and link against the debug zlib
            CFLAGS="$DEBUG_CFLAGS" \
                CXXFLAGS="$DEBUG_CXXFLAGS" \
                CPPFLAGS="${CPPFLAGS:-} ${DEBUG_CPPFLAGS} -I$stage/packages/include/zlib" \
                LDFLAGS="-L$stage/packages/lib/debug" \
                ./configure --enable-shared=no --with-pic --with-zlib=yes \
                    --prefix="\${AUTOBUILD_PACKAGES_DIR}" --libdir="\${prefix}/lib/debug"
            make
            make install DESTDIR="$stage"

            # conditionally run unit tests
            if [ "${DISABLE_UNIT_TESTS:-0}" = "0" ]; then
                # make test
                echo "No tests"
            fi

            make distclean

            # release configure and build
            export PKG_CONFIG_PATH="$stage/packages/lib/release/pkgconfig:${OLD_PKG_CONFIG_PATH}"

            # build the release version and link against the release zlib
            CFLAGS="$RELEASE_CFLAGS" \
                CXXFLAGS="$RELEASE_CXXFLAGS" \
                CPPFLAGS="${CPPFLAGS:-} ${RELEASE_CPPFLAGS} -I$stage/packages/include/zlib" \
                LDFLAGS="-L$stage/packages/lib/release" \
                ./configure --enable-shared=no --with-pic --with-zlib=yes \
                    --prefix="\${AUTOBUILD_PACKAGES_DIR}" --libdir="\${prefix}/lib/release"
            make
            make install DESTDIR="$stage"

            # conditionally run unit tests
            if [ "${DISABLE_UNIT_TESTS:-0}" = "0" ]; then
                # make test
                echo "No tests"
            fi

            make distclean
        ;;
    esac
    mkdir -p "$stage/LICENSES"
    cp docs/LICENSE.TXT "$stage/LICENSES/freetype.txt"
popd

mkdir -p "$stage"/docs/freetype/
cp -a README.Linden "$stage"/docs/freetype/
