#!/bin/bash

JPEG_TAG=master
OPENH264_TAG=master
OPENSSL_TAG=master
FFMPEG_TAG=n4.4.1

WITH_JPEG=0
WITH_OPENH264=0
WITH_OPENSSL=0
WITH_FFMPEG=0

SRC_DIR=$(dirname "${BASH_SOURCE[0]}")
SRC_DIR=$(realpath "$SRC_DIR")
BUILD_SRC=$(pwd)
BUILD_DST=$(pwd)

CMAKE_BUILD_TYPE=Debug
BUILD_DEPS=0

SCRIPT_PATH=$(dirname "${BASH_SOURCE[0]}")
source $SCRIPT_PATH/android-build-common.sh
source $SCRIPT_PATH/android-build.conf

# Parse arguments.
REMAINING=""
while [[ $# > 0 ]]
do
	key="$1"
	case $key in
		--freerdp-src)
			SRC_DIR="$2"
			shift
			;;
		--jpeg)
			WITH_JPEG=1
			shift
			;;
		--openh264)
			WITH_OPENH264=1
			shift
			;;
		--openh264-ndk)
			shift
			ANDROID_NDK_OPENH264=$1
			shift
			;;
		--ffmpeg)
			WITH_FFMPEG=1
			shift
			;;
		--openssl)
			WITH_OPENSSL=1
			shift
			;;
		--debug)
			CMAKE_BUILD_TYPE=Debug
			shift
			;;
		--release)
			CMAKE_BUILD_TYPE=Release
			shift
			;;
		--relWithDebug)
			CMAKE_BUILD_TYPE=RelWithDebug
			shift
			;;
		--build-deps)
			BUILD_DEPS=1
			shift
			;;
		*)
			REMAINING="$REMAINING $key"
			shift
			;;
	esac
done
common_parse_arguments $REMAINING

# clean up top
if [ -d $BUILD_SRC ];
then
	common_clean $BUILD_SRC
fi

if [ -d $BUILD_DST ];
then
	common_run mkdir -p $BUILD_DST
fi

# Prepare the environment
common_run mkdir -p $BUILD_SRC

CMAKE_CMD_ARGS="-DANDROID_NDK=$ANDROID_NDK \
	-DANDROID_NATIVE_API_LEVEL=android-${NDK_TARGET} \
	-DCMAKE_TOOLCHAIN_FILE=$ANDROID_NDK/build/cmake/android.toolchain.cmake \
	-DCMAKE_BUILD_TYPE=$CMAKE_BUILD_TYPE \
	-DFREERDP_EXTERNAL_PATH=$BUILD_DST \
	-DCMAKE_MAKE_PROGRAM=make"

BASE=$(pwd)
for ARCH in $BUILD_ARCH
do
    # build dependencies.
    if [ $WITH_JPEG -ne 0 ];
    then
        if [ $BUILD_DEPS -ne 0 ];
        then
            common_run bash $SCRIPT_PATH/android-build-jpeg.sh \
                --src $BUILD_SRC/jpeg --dst $BUILD_DST \
                --ndk $ANDROID_NDK \
                --arch $ARCH \
                --target $NDK_TARGET \
                --tag $JPEG_TAG
        fi
        CMAKE_CMD_ARGS="$CMAKE_CMD_ARGS -DWITH_JPEG=ON"
    else
        CMAKE_CMD_ARGS="$CMAKE_CMD_ARGS -DWITH_JPEG=OFF"
    fi
    if [ $WITH_OPENH264 -ne 0 ];
    then
        if [ -z "$ANDROID_NDK_OPENH264" ]
        then
            echo
            echo "Warning: Missing openh264-ndk, using $ANDROID_NDK" >&2
            echo
            ANDROID_NDK_OPENH264=$ANDROID_NDK
        fi
        if [ $BUILD_DEPS -ne 0 ];
        then
            common_run bash $SCRIPT_PATH/android-build-openh264.sh \
                --src $BUILD_SRC/openh264 --dst $BUILD_DST \
                --sdk "$ANDROID_SDK" \
                --ndk "$ANDROID_NDK_OPENH264" \
                --arch $ARCH \
                --target $NDK_TARGET \
                --tag $OPENH264_TAG
        fi
        CMAKE_CMD_ARGS="$CMAKE_CMD_ARGS -DWITH_OPENH264=ON"
    else
        CMAKE_CMD_ARGS="$CMAKE_CMD_ARGS -DWITH_OPENH264=OFF"
    fi
	if [ $WITH_FFMPEG -ne 0 ];
    then
		if [ $BUILD_DEPS -ne 0 ];
        then
            common_run bash $SCRIPT_PATH/android-build-ffmpeg.sh \
                --src $BUILD_SRC/ffmpeg --dst $BUILD_DST \
                --sdk "$ANDROID_SDK" \
                --ndk "$ANDROID_NDK" \
                --arch $ARCH \
                --target $NDK_TARGET \
                --tag $FFMPEG_TAG
        fi
		CMAKE_CMD_ARGS="$CMAKE_CMD_ARGS -DWITH_FFMPEG=ON -DWITH_SWSCALE=ON -DWITH_DSP_FFMPEG=ON"
	else
        CMAKE_CMD_ARGS="$CMAKE_CMD_ARGS -DWITH_FFMPEG=OFF -DWITH_SWSCALE=OFF -DWITH_DSP_FFMPEG=OFF"
    fi
    if [ $WITH_OPENSSL -ne 0 ];
    then
        if [ $BUILD_DEPS -ne 0 ];
        then
            common_run bash $SCRIPT_PATH/android-build-openssl.sh \
                --src $BUILD_SRC/openssl --dst $BUILD_DST \
                --sdk "$ANDROID_SDK" \
                --ndk $ANDROID_NDK \
                --arch $ARCH \
		--target $NDK_TARGET \
                --tag $OPENSSL_TAG
        fi
    fi

    # Build and install the library.
    if [ $DEPS_ONLY -eq 0 ];
    then
	common_run cd $BASE
	common_run mkdir -p $BUILD_SRC/freerdp-build/$ARCH
	common_run cd $BUILD_SRC/freerdp-build/$ARCH
	common_run export ANDROID_NDK=$ANDROID_NDK
	common_run $CMAKE_PROGRAM $CMAKE_CMD_ARGS \
		-DANDROID_ABI=$ARCH \
		-DCMAKE_INSTALL_PREFIX=$BUILD_DST/$ARCH \
		-DCMAKE_INSTALL_LIBDIR=. \
		$SRC_DIR
	echo $(pwd)
	common_run cmake --build . --target install
    fi
done

echo "Successfully build library for architectures $BUILD_ARCH"
