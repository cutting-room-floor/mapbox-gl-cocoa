# mapbox-gl-cocoa

This project is Cocoa API bindings for [`mapbox-gl-native`](https://github.com/mapbox/mapbox-gl-native). Use or edit this project to get access to Mapbox vector maps and dynamic OpenGL-based styling in your iOS apps by using `MGLMapView`. 

![](https://raw.githubusercontent.com/mapbox/mapbox-gl-cocoa/master/pkg/screenshot.png)

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

```objective-c
MGLMapView *mapView = [[MGLMapView alloc] initWithFrame:CGRectMake(0, 0, 400, 400)]];
mapView.centerCoordinate = CLLocationCoordinate2DMake(28.369334, -80.743779);
mapView.zoomLevel = 13;
[self.view addSubview:mapView];
```

## Development

If you'd like to contribute to this project, go instead to [Mapbox GL native](https://github.com/mapbox/mapbox-gl-native) and clone that project. This project is a submodule of that project and is pulled into the overarching build process there, which consists of a cross-platform C++ library and this Objective-C wrapper library, together with an iOS demo app. 

## Requirements

 * iOS 7+
 * a sense of adventure

## Styling

See `STYLING.md` for more information on the styling language. *This language is in rapid development and is subject to change.* Contained within the `MapboxGL.bundle` assets is a `style.js`, which describes the entire default style bundled with the framework (class: `default`), as well as the `night` class variant. 

The styling language is a cascading language similar to CSS. It can be described in native code with Mapbox GL Cocoa such that the following style layer adjustments are possible: 

```objective-c
NSDictionary *buildingStyle = @{ @"color" : @{ @"type"  : MVKStyleValueTypeColor,
                                               @"value" : [UIColor purpleColor] } };

[self setStyleDescription:buildingStyle forLayer:@"buildings" inClass:@"default"];
```

By default, layer properties changes are updated instantly on the map. However, a transition animation duration can optionally be specified to animate the change between number, number pair, and even color property types. 

## Related Projects

 * https://github.com/mapbox/mapbox-gl-native
 * https://github.com/mapbox/vector-tile-spec

## Other notes

Under early development, this project was called MVKMapKit (Mapbox... Vector Kit?), in case you see any lingering references to it. 
