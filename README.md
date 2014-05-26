# MVKMapKit

This is a Cocoa API wrapper for [`llmr-native`](https://github.com/mapbox/llmr-native). Use or edit this project to get access to Mapbox vector maps in your iOS apps by using `MVKMapView`. 

## Installation

This project should be cloned as a submodule of `llmr-native` so that it is contained within that project. Then, run `./setup.sh` to use GYP to create the Xcode project for the sample app. This script will open the project, then you should select the *Sample App* target and an iOS platform of choice to build & run the sample app. 

GYP is currently used because the `llmr-native` iOS test app itself requires the resources bundle created by this GYP project. In future, MVKMapKit will be installable as a statically-linked library, header files, and a pre-built resource bundle for persons not wishing to develop on `llmr-native` itself. 

## Requirements

 * iOS 7+
 * a sense of adventure

## Concepts

## API Overview

## Related Projects

 * https://github.com/mapbox/vector-tile-spec
 * https://github.com/mapbox/llmr-native
 * https://github.com/mapbox/llmr (if public)

##

*Project name subject to change.*
