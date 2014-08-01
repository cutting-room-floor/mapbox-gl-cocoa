# mapbox-gl-cocoa

[![Build Status](https://travis-ci.org/mapbox/mapbox-gl-cocoa.svg)](https://travis-ci.org/mapbox/mapbox-gl-cocoa)

This project is Cocoa API bindings for [`mapbox-gl-native`](https://github.com/mapbox/mapbox-gl-native). Use or edit this project to get access to Mapbox vector maps and dynamic OpenGL-based styling in your iOS apps by using `MGLMapView`. 

![](https://raw.githubusercontent.com/mapbox/mapbox-gl-cocoa/master/pkg/screenshot.png)

## Installation

To use this library in your app directly, follow these steps. Everything you need is in `./dist`. You can also make use of [CocoaPods](http://cocoapods.org) by pointing at the `MapboxGL.podspec` file in the root of the repository (the library has not yet been added to the CocaoPods specs repository). 

 * Copy the contents of `./dist` into your project. 
 * Add header files in `Headers` to your project. 
 * Add `MapboxGL.bundle` to your app target's *Copy Bundle Resources* build phase. 
 * Add `libMapboxGL.a` to your project's linked libraries. 
 * Add `MapboxGL.mm` to your project's compiled sources (this is a stub file to trigger Objective-C++ compilation). 
 * Add the following dependent Cocoa frameworks to your project's linked libraries: 
   - `CoreLocation.framework`
   - `GLKit.framework`
   - `libz.dylib`
 * Get a Mapbox API access token on [your account page](https://mapbox.com/account/apps). 
 * Import the necessary headers (like `MGLMapView.h`) into your project and use the APIs. 

```objective-c
MGLMapView *mapView = [[MGLMapView alloc] initWithFrame:CGRectMake(0, 0, 400, 400)
                                            accessToken:@"<token>"];
[mapView setCenterCoordinate:CLLocationCoordinate2DMake(28.369334, -80.743779) 
                   zoomLevel:13 
                    animated:NO];
[self.view addSubview:mapView];
```

## Development

If you'd like to contribute to this project, go instead to [Mapbox GL native](https://github.com/mapbox/mapbox-gl-native) and clone that project. This project is a submodule of that project and is pulled into the overarching build process there, which consists of a cross-platform C++ library and this Objective-C wrapper library, together with an iOS demo app. 

## Packaging

This library, when standalone, makes use of static inclusion of [Mapbox GL](https://github.com/mapbox/mapbox-gl-native), the underlying C++ library. To package a version for release, run `./pkg/package.sh` while this project is checked out inside of Mapbox GL. This will update the contents of `./dist`. 

## Testing

Tests are in `./test` and make use of the [KIF](https://github.com/kif-framework/KIF) framework. Since this project relies on the underlying C++ library, in order to be independently testable, the tests run an Xcode project which uses the static build of this library. Thus, to fully test the framework, you should first package a build per the above instructions so that the test app can link against `./dist/libMapboxGL.a`. See the [`.travis.yml`](https://github.com/mapbox/mapbox-gl-cocoa/blob/master/.travis.yml) for more info on the steps required. 

## Requirements

 * iOS 7+
 * a sense of adventure

## Styling

See `STYLING.md` for more information on the styling language. *This language is in rapid development and is subject to change.* Contained within the `MapboxGL.bundle` assets is a `style.js`, which describes the entire default style bundled with the framework (class: `default`), as well as the `night` class variant. 

The styling language is a cascading language similar to CSS. It can be described in native code with Mapbox GL Cocoa such that the following style layer adjustments are possible: 

```objective-c
NSDictionary *buildingStyle = @{ @"stroke" : @{ @"type"  : MGLStyleValueTypeColor,
                                                @"value" : [UIColor purpleColor] } };

[self setStyleDescription:buildingStyle forLayer:@"buildings" inClass:@"default"];
```

By default, layer properties changes are updated instantly on the map. However, a transition animation duration can optionally be specified to animate the change between number, number pair, and even color property types. 

## Related Projects

 * https://github.com/mapbox/mapbox-gl-native
 * https://github.com/mapbox/mapbox-gl-style-spec
 * https://github.com/mapbox/vector-tile-spec

## Other notes

Under early development, this project was called MVKMapKit (Mapbox... Vector Kit?), in case you see any lingering references to it. 
