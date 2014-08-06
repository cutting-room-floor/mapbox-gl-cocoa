#!/bin/bash

# This script is meant to be run in place while
# mapbox-gl-cocoa is a submodule of the Mapbox GL native
# project. It packages a binary version of the C++
# library along with requisite Cocoa headers and
# resources.
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

# run GYP to generate mapbox-gl-cocoa Xcode project
# NOTE: the above command also creates $PARENT/mbgl.xcodeproj
../../../deps/run_gyp ./mapbox-gl-cocoa.gyp --depth=. --generator-output=. -f xcode

# build Release static lib of mapbox-gl-cocoa
xcodebuild -project ./mapbox-gl-cocoa.xcodeproj -target static-library -configuration Release -sdk iphonesimulator${SDK} ONLY_ACTIVE_ARCH=NO
xcodebuild -project ./mapbox-gl-cocoa.xcodeproj -target static-library -configuration Release -sdk iphoneos${SDK}

# build Release for device/sim
xcodebuild -project $PARENT/mbgl.xcodeproj -target mapboxgl-ios -configuration Release -sdk iphonesimulator${SDK} ONLY_ACTIVE_ARCH=NO
xcodebuild -project $PARENT/mbgl.xcodeproj -target mapboxgl-ios -configuration Release -sdk iphoneos${SDK}

# combine into one lib per arch
libtool -static -o ./build/libMapboxGL-device.a build/Release-iphoneos/libMapboxGL.a $PARENT/build/Release-iphoneos/lib*.a
libtool -static -o ./build/libMapboxGL-simulator.a build/Release-iphonesimulator/libMapboxGL.a $PARENT/build/Release-iphonesimulator/lib*.a

# TODO: we may also need to link these libs in the above libtool command
#$PARENT/mapnik-packaging/osx/out/build-cpp11-libcpp-universal/lib/libuv.a \
#$PARENT/mapnik-packaging/osx/out/build-cpp11-libcpp-universal/lib/libpng.a \

lipo -create ./build/libMapboxGL-device.a \
             ./build/libMapboxGL-simulator.a \
             -o $OUTPUT/lib$NAME.a

# copy headers & stub
mkdir -p $OUTPUT/Headers
for header in `ls $SOURCES/*.h`; do
   cp -v $header $OUTPUT/Headers
done
cp -v MapboxGL.mm $OUTPUT

# create resource bundle
mkdir $OUTPUT/$NAME.bundle
cp -v $SOURCES/Resources/* $OUTPUT/$NAME.bundle
cp -v $PARENT/bin/style.js $OUTPUT/$NAME.bundle
cp -v $PARENT/build/DerivedSources/Release/bin/style.min.js $OUTPUT/$NAME.bundle
cp -v '../spec/reference/v4.json' $OUTPUT/$NAME.bundle

# record versions info
VERSIONS="`pwd`/$OUTPUT/versions.txt"
echo -n "mapbox-gl-cocoa  " > $VERSIONS
git log | head -1 | awk '{ print $2 }' >> $VERSIONS
echo -n "mapbox-gl-native " >> $VERSIONS
cd ../.. && git log | head -1 | awk '{ print $2 }' >> $VERSIONS && cd $OLDPWD
