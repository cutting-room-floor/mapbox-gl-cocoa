{
  'includes': [
    '../../gyp/common.gypi',
  ],
  'targets': [
    { 'target_name': 'mbgl-cocoa',
      'product_name': 'mbgl-cocoa',
      'type': 'static_library',
      'standalone_static_library': 1,
      'hard_dependency': 1,

      'sources': [
        'include/mbgl/platform/ios/MGLMapView.h',
        'src/MGLMapView.mm',
        'src/MGLStyleFunctionValue.h',
        'src/MGLStyleFunctionValue.m',
        'src/MGLTypes.h',
        'src/MGLTypes.m',
        'src/NSArray+MGLAdditions.h',
        'src/NSArray+MGLAdditions.m',
        'src/NSDictionary+MGLAdditions.h',
        'src/NSDictionary+MGLAdditions.m',
        'src/UIColor+MGLAdditions.h',
        'src/UIColor+MGLAdditions.m',
      ],

      'variables': {
        'ldflags': [
          '-framework ImageIO',
          '-framework MobileCoreServices',
          '-framework GLKit',
          '-framework OpenGLES',
          '-framework CoreGraphics',
          '-framework CoreLocation',
          '-framework UIKit',
        ],
      },

      'xcode_settings': {
        'SDKROOT': 'iphoneos',
        'SUPPORTED_PLATFORMS': 'iphonesimulator iphoneos',
        'CLANG_ENABLE_OBJC_ARC': 'YES',
      },

      'include_dirs': [
        'include',
        '../../include',
      ],

      'link_settings': {
        'xcode_settings': {
          'OTHER_LDFLAGS': [ '<@(ldflags)' ],
        },
      },

      'direct_dependent_settings': {
        'include_dirs': [
          'include',
        ],
        'mac_bundle_resources': [
          '<!@(find ./resources -type f)',
        ],
      },
    },
  ],
}
