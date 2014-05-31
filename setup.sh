#!/bin/sh

../../deps/run_gyp ./mapbox-gl-cocoa.gyp --depth=. --generator-output=. -f xcode && open mapbox-gl-cocoa.xcodeproj/
