# mapbox-gl-cocoa

This project is Cocoa API bindings for [`mapbox-gl-native`](https://github.com/mapbox/mapbox-gl-native). Use or edit this project to get access to Mapbox vector maps and dynamic OpenGL-based styling in your iOS apps by using `MGLMapView`. 

## Installation

This project should be cloned as a submodule of `mapbox-gl-native` so that it is contained within that project. Then, run `./setup.sh` to use [GYP](https://code.google.com/p/gyp/) to create the Xcode project for the sample app. This script will open the project, then you should select the *Sample App* target and an iOS platform of choice to build & run the sample app. 

GYP is currently used because the `mapbox-gl-native` iOS test app itself requires the resources bundle created by this GYP project. In future, mapbox-gl-cocoa will be installable as a statically-linked library, header files, and a pre-built resource bundle for persons not wishing to develop on `mapbox-gl-native` itself. 

## Requirements

 * iOS 7+
 * a sense of adventure

## Concepts

## API Overview

## Related Projects

 * https://github.com/mapbox/vector-tile-spec
 * https://github.com/mapbox/mapbox-gl-native
 * https://github.com/mapbox/llmr (soon)

## Other notes

Under early development, this project was called MVKMapKit (Mapbox... Vector Kit?), in case you see any lingering references to it. 
