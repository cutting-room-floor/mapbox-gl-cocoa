{
  'includes': [
    '../../../gyp/common.gypi',
  ],
  'targets': [
    { 'target_name': 'iosapp',
      'product_name': 'Mapbox GL',
      'type': 'executable',
      'dependencies': [
        '../../../mbgl.gyp:bundle_styles',
        '../../../mbgl.gyp:core',
        '../../../mbgl.gyp:platform-<(platform_lib)',
        '../../../mbgl.gyp:http-<(http_lib)',
        '../../../mbgl.gyp:asset-<(asset_lib)',
        '../../../mbgl.gyp:cache-<(cache_lib)',
      ],
      'sources': [
        './main.m',
        './MBXAppDelegate.h',
        './MBXAppDelegate.m',
        './MBXViewController.h',
        './MBXViewController.mm',
        '<!@(find ../mapbox-gl-cocoa -type f -name "*.h")',
        '<!@(find ../mapbox-gl-cocoa -type f -name "*.m")',
        '<!@(find ../mapbox-gl-cocoa -type f -name "*.mm")',
        '../../../platform/darwin/settings_nsuserdefaults.mm',
        '../../../platform/darwin/Reachability.m',
      ],
      'product_extension': 'app',
      'mac_bundle': 1,
      'mac_bundle_resources': [
        '<!@(find ./img -type f)',
        '<!@(find ../mapbox-gl-cocoa/Resources -type f)',
      ],
      'variables' : {
        'ldflags': [
          '<@(sqlite3_ldflags)',
          '<@(uv_ldflags)',
          '<@(zlib_ldflags)',
          '-framework CoreGraphics',
          '-framework CoreLocation',
          '-framework GLKit',
          '-framework ImageIO',
          '-framework MobileCoreServices',
          '-framework OpenGLES',
          '-framework SystemConfiguration',
          '-framework UIKit',
        ]
      },
      'xcode_settings': {
        'SDKROOT': 'iphoneos',
        'SUPPORTED_PLATFORMS': 'iphonesimulator iphoneos',
        'INFOPLIST_FILE': 'app-info.plist',
        'CLANG_CXX_LIBRARY': 'libc++',
        'CLANG_CXX_LANGUAGE_STANDARD': 'c++11',
        'IPHONEOS_DEPLOYMENT_TARGET': '7.0',
        'TARGETED_DEVICE_FAMILY': '1,2',
        'GCC_VERSION': 'com.apple.compilers.llvm.clang.1_0',
        'COMBINE_HIDPI_IMAGES': 'NO', # don't merge @2x.png images into .tiff files
        'CLANG_ENABLE_OBJC_ARC': 'YES',
        'OTHER_LDFLAGS': [ '<@(ldflags)' ],
      },
      'configurations': {
        'Debug': {
          'xcode_settings': {
            'CODE_SIGN_IDENTITY': 'iPhone Developer',
          }
        },
        'Release': {
          'xcode_settings': {
            'CODE_SIGN_IDENTITY': 'iPhone Distribution',
            'ARCHS': [ "armv7", "armv7s", "arm64", "i386", "x86_64" ],
          }
        }
      },
    }
  ]
}
