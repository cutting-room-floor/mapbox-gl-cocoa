#!/bin/bash

# This script is meant to be run in place while
# mapbox-gl-cocoa is a submodule of the Mapbox GL native
# project. It packages binary versions of the C++
# library along with requisite Cocoa headers and
# resources as both static library and iOS 8+ framework.
#
# If you want to hack on the Mapbox GL native project itself,
# follow the instructions in that repository to get setup:
#
# https://github.com/mapbox/mapbox-gl-native
#

NAME="MapboxGL"
PARENT="../../.."
OUTPUT="../dist"
SOURCES="../mapbox-gl-cocoa"

echo "Cleaning..."
rm -rfv $OUTPUT
mkdir -pv $OUTPUT

#
# include README
#
cp -v README.md $OUTPUT

#
# Record versions info from git hashes for packaging reference.
#
VERSIONS="`pwd`/$OUTPUT/versions.txt"
echo -n "mapbox-gl-cocoa  " > $VERSIONS
git log | head -1 | awk '{ print $2 }' >> $VERSIONS
echo -n "mapbox-gl-native " >> $VERSIONS
cd ../.. && git log | head -1 | awk '{ print $2 }' >> $VERSIONS && cd $OLDPWD

#
# Manually create resource bundle. We don't use a GYP target here because of 
# complications between faked GYP bundles-as-executables, device build 
# dependencies, and code signing. 
#
mkdir -pv $OUTPUT/static/$NAME.bundle
cp -v $SOURCES/Resources/* $OUTPUT/static/${NAME}.bundle
cp -rv $PARENT/styles $OUTPUT/static/${NAME}.bundle/styles

#
# Run GYP to generate mapbox-gl-cocoa Xcode project.
# NOTE: the above command also creates the dependent $PARENT/mapboxgl.xcodeproj.
#
../../../deps/run_gyp ./mapbox-gl-cocoa.gyp --depth=. --generator-output=. -f xcode

#
# Build Cocoa lib for sim & device.
#
xcodebuild -project ./mapbox-gl-cocoa.xcodeproj -target mapbox-library -configuration Release -sdk iphonesimulator${SDK} ONLY_ACTIVE_ARCH=NO
xcodebuild -project ./mapbox-gl-cocoa.xcodeproj -target mapbox-library -configuration Release -sdk iphoneos${SDK}

#
# Build C++ lib for sim & device.
#
xcodebuild -project $PARENT/mapboxgl.xcodeproj -target mapboxgl-ios -configuration Release -sdk iphonesimulator${SDK} ONLY_ACTIVE_ARCH=NO
xcodebuild -project $PARENT/mapboxgl.xcodeproj -target mapboxgl-ios -configuration Release -sdk iphoneos${SDK}

#
# Combine into one lib each for sim & device.
#
libtool -static -o ./build/lib${NAME}-simulator.a \
                   build/Release-iphonesimulator/lib${NAME}.a \
                   $PARENT/build/Release-iphonesimulator/lib*.a \
                   $PARENT/mapnik-packaging/osx/out/build-cpp11-libcpp-i386-iphonesimulator/lib/libpng.a \
                   $PARENT/mapnik-packaging/osx/out/build-cpp11-libcpp-x86_64-iphonesimulator64/lib/libpng.a \
                   $PARENT/mapnik-packaging/osx/out/build-cpp11-libcpp-i386-iphonesimulator/lib/libuv.a \
                   $PARENT/mapnik-packaging/osx/out/build-cpp11-libcpp-x86_64-iphonesimulator64/lib/libuv.a
libtool -static -o ./build/lib${NAME}-device.a \
                   build/Release-iphoneos/lib${NAME}.a \
                   $PARENT/build/Release-iphoneos/lib*.a \
                   $PARENT/mapnik-packaging/osx/out/build-cpp11-libcpp-armv7-iphoneos/lib/libpng.a \
                   $PARENT/mapnik-packaging/osx/out/build-cpp11-libcpp-armv7s-iphoneoss/lib/libpng.a \
                   $PARENT/mapnik-packaging/osx/out/build-cpp11-libcpp-arm64-iphoneos64/lib/libpng.a \
                   $PARENT/mapnik-packaging/osx/out/build-cpp11-libcpp-armv7-iphoneos/lib/libuv.a \
                   $PARENT/mapnik-packaging/osx/out/build-cpp11-libcpp-armv7s-iphoneoss/lib/libuv.a \
                   $PARENT/mapnik-packaging/osx/out/build-cpp11-libcpp-arm64-iphoneos64/lib/libuv.a

#
# Combine into one final lib for all platforms.
#
lipo -create ./build/lib${NAME}-device.a \
             ./build/lib${NAME}-simulator.a \
             -o $OUTPUT/static/lib${NAME}.a

if [[ `xcodebuild -showsdks | grep -c iphoneos8` == 0 ]]; then
    echo "Skipping framework build since no iOS 8 SDK present."
    exit
fi

#
# Build framework for sim & device.
#
xcodebuild -project ./mapbox-gl-cocoa.xcodeproj -target mapbox-framework -configuration Release -sdk iphonesimulator${SDK} ONLY_ACTIVE_ARCH=NO
xcodebuild -project ./mapbox-gl-cocoa.xcodeproj -target mapbox-framework -configuration Release -sdk iphoneos${SDK}

#
# Combine into one framework for all platforms.
#
mkdir -pv $OUTPUT/dynamic
cp -rv ./build/Release-iphoneos/${NAME}.framework $OUTPUT/dynamic
lipo -create ./build/Release-iphoneos/${NAME}.framework/${NAME} \
             ./build/Release-iphonesimulator/${NAME}.framework/${NAME} \
             -o $OUTPUT/dynamic/${NAME}.framework/${NAME}
