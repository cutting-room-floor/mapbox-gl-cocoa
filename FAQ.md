# Mapbox GL Cocoa FAQ

Mapbox GL is a completely new renderer technology which will eventually replace and/or merge Mapbox's existing iOS toolsets, the [Mapbox iOS SDK](http://www.mapbox.com/mapbox-ios-sdk/) and [MBXMapKit](https://www.mapbox.com/mbxmapkit/). This FAQ shares our current plans for that migration. The plans are subject to change as Mapbox GL matures, but we wanted to both clarify our thinking as well as set expectations for where things are headed. 

### When will Mapbox GL be released? 

The library is open source right now, but an official, production-recommended release will come later in 2014. 

### Will the API be similar to the Mapbox iOS SDK/MBXMapKit/MapKit? 

Yes. We are shooting for bringing the Mapbox GL API in line with Apple's MapKit for the easiest transition ability. 

MBXMapKit is already an add-on to MapKit, so Apple's `MKMapView` API is used directly. 

The Mapbox iOS SDK is "workalike", since it descends from an [upstream open source project](https://github.com/Alpstein/route-me) that predates Apple's own MapKit. It uses similar concepts like annotations (with the difference that the map view delegate provides `CALayer` instances instead of `UIView`, the intention being that Mapbox GL will support `UIView`), similar API for managing the map view center, bounds, and zoom levels, and an `RMUserLocation` API that is very much like `MKUserLocation`. But the Mapbox iOS SDK also features unique APIs like extensible tile sources, offline caching, UTFGrid interactivity, and point annotation clustering. 

### Will the iOS SDK's extra APIs make it over to Mapbox GL? 

The intention is yes. This includes: 

#### Tile sources

#### Offline caching

#### UTFGrid interactivity

#### Annotation clustering
  
### What will the migration path look like? 

Ideally, the migration will be pretty lightweight because of the APIs supported above. There may be slight syntax changes, but they likely won't be more than would be expected from something like Mapbox iOS SDK version `1.x` to a hypothetical `2.x`. 
