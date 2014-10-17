## Installation

To use this library in your app directly, follow these steps. You can also make use of [CocoaPods](http://cocoapods.org) by pointing at the `MapboxGL.podspec` file in the root of the repository (the library has not yet been added to the CocoaPods specs repository). 

### Static library (iOS 7+)

 * Copy the contents of [`./static`](./static) into your project. It should happen automatically, but ensure that: 
   - `Headers` is in your *Header Search Paths* build setting. 
   - `MapboxGL.bundle` is in your target's *Copy Bundle Resources* build phase. 
   - `libMapboxGL.a` is in your target's *Link Binary With Libraries* build phase. 
 * Add the following dependent Cocoa frameworks to your project's linked libraries: 
   - `CoreGraphics.framework`
   - `CoreLocation.framework`
   - `GLKit.framework`
   - `OpenGLES.framework`
   - `SystemConfiguration.framework`
   - `UIKit.framework`
   - `libc++.dylib`
   - `libsqlite3.dylib`
   - `libz.dylib`
 * Get a Mapbox API access token on [your account page](https://mapbox.com/account/apps). 
 * Import the necessary headers (`#import "MGLMapView.h"`) into your project and use the APIs per the [example usage](../README.md#example-usage). 

### Dynamic framework (iOS 8+)

 * Copy `MapboxGL.framework` from [`./dynamic`](./dynamic) into your project. It should happen automatically, but ensure that: 
   - The containing folder is in your *Framework Search Paths* build setting. 
   - `MapboxGL.framework` is in your target's *Link Binary With Libraries* build phase. 
   - `MapboxGL.framework` is in your target's *Embed Frameworks* build phase. 
 * Get a Mapbox API access token on [your account page](https://mapbox.com/account/apps). 
 * Import the necessary headers (`#import <MapboxGL/MapboxGL.h>`) into your project and use the APIs per the [example usage](../README.md#example-usage). 
