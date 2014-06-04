# mapbox-gl-cocoa

This project is Cocoa API bindings for [`mapbox-gl-native`](https://github.com/mapbox/mapbox-gl-native). Use or edit this project to get access to Mapbox vector maps and dynamic OpenGL-based styling in your iOS apps by using `MGLMapView`. 

## Installation

To use this library in your app directly, follow these steps. Everything you need is in `./dist`. 

 * Copy the contents of `./dist` into your project. 
 * Add header file(s) in `Headers` to your project. 
 * Add `MapboxGL.bundle` to your app target's *Copy Bundle Resources* build phase. 
 * Add `libMapboxGL.a` to your project's linked libraries. 
 * Add `MapboxGL.mm` to your project's compiled sources (this is a stub file to trigger Objective-C++ compilation). 
 * Add the following dependent Cocoa frameworks to your project's linked libraries: 
   - `CoreLocation.framework`
   - `GLKit.framework`
   - `libz.dylib`
 * Import the necessary headers (like `MGLMapView.h`) into your project and use the APIs. 

## Development

If you'd like to contribute to this project, go instead to [Mapbox GL native](https://github.com/mapbox/mapbox-gl-native) and clone that project. This project is a submodule of that project and is pulled into the overarching build process there, which consists of a cross-platform C++ library and this Objective-C wrapper library, together with an iOS demo app. 

## Requirements

 * iOS 7+
 * a sense of adventure

## Concepts

## API Overview

## Related Projects

 * https://github.com/mapbox/mapbox-gl-native
 * https://github.com/mapbox/vector-tile-spec

## Other notes

Under early development, this project was called MVKMapKit (Mapbox... Vector Kit?), in case you see any lingering references to it. 
