#!/bin/sh

../../deps/run_gyp ./MVKMapKit.gyp --depth=. --generator-output=. -f xcode && open MVKMapKit.xcodeproj/
