{
  'targets': [
    {
        'target_name': 'Sample App',
        'product_name': 'MGL Sample',
        'sources': [
            './mapbox-gl-cocoa/main.m',
            './mapbox-gl-cocoa/MGLSAppDelegate.h',
            './mapbox-gl-cocoa/MGLSAppDelegate.m',
            './mapbox-gl-cocoa/MGLSViewController.h',
            './mapbox-gl-cocoa/MGLSViewController.m',
            '<!@(find mapbox-gl-cocoa -type f -name "MGLMapView.*")',
            '<!@(find mapbox-gl-cocoa -type f -name "MGLStyleFunctionValue.*")',
            '<!@(find mapbox-gl-cocoa -type f -name "MGLTypes.*")',
            '<!@(find mapbox-gl-cocoa -type f -name "*+MGLAdditions.*")',
            '../../common/foundation_request.h',
            '../../common/foundation_request.mm',
        ],
        'product_extension': 'app',
        'type': 'executable',
        'mac_bundle': 1,
        'mac_bundle_resources': [
          '<!@(find mapbox-gl-cocoa/Resources -type f)',
          '<(SHARED_INTERMEDIATE_DIR)/bin/style.min.js'
        ],
        'link_settings': {
          'libraries': [
            '$(SDKROOT)/System/Library/Frameworks/CoreGraphics.framework',
            '$(SDKROOT)/System/Library/Frameworks/CoreLocation.framework',
            '$(SDKROOT)/System/Library/Frameworks/GLKit.framework',
            '$(SDKROOT)/System/Library/Frameworks/OpenGLES.framework',
            '$(SDKROOT)/System/Library/Frameworks/UIKit.framework'
          ],
        },
        'xcode_settings': {
          'SDKROOT': 'iphoneos',
          'SUPPORTED_PLATFORMS':['iphonesimulator','iphoneos'],
          'ARCHS': [ 'armv7', 'armv7s', 'arm64', 'i386' ],
          'INFOPLIST_FILE': 'mapbox-gl-cocoa/mapbox-gl-cocoa-Info.plist',
          'CLANG_CXX_LIBRARY': 'libc++',
          'CLANG_CXX_LANGUAGE_STANDARD':'c++11',
          'IPHONEOS_DEPLOYMENT_TARGET':'7.0',
          'TARGETED_DEVICE_FAMILY': '1,2',
          'GCC_VERSION': 'com.apple.compilers.llvm.clang.1_0',
          'CLANG_ENABLE_OBJC_ARC': 'YES'
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
            }
          }
        },
        'default_configuration': 'Release',
        'dependencies': [
            '../../llmr.gyp:llmr-ios'
        ]
    }
  ]
}