{
  'targets': [
    {
        'target_name': 'static-library',
        'product_name': 'MapboxGL',
        'sources': [
            '<!@(find ../mapbox-gl-cocoa -type f -name "MGLMapView.*")',
            '<!@(find ../mapbox-gl-cocoa -type f -name "MGLStyleFunctionValue.*")',
            '<!@(find ../mapbox-gl-cocoa -type f -name "MGLTypes.*")',
            '<!@(find ../mapbox-gl-cocoa -type f -name "*+MGLAdditions.*")',
            '../../../common/foundation_request.h',
            '../../../common/foundation_request.mm',
            '../../../common/nslog_log.hpp',
            '../../../common/nslog_log.mm'
        ],
        'type': 'static_library',
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
          'ARCHS': [ 'armv7', 'armv7s', 'arm64', 'i386', 'x86_64' ],
          'CLANG_CXX_LIBRARY': 'libc++',
          'CLANG_CXX_LANGUAGE_STANDARD':'c++11',
          'IPHONEOS_DEPLOYMENT_TARGET':'7.0',
          'TARGETED_DEVICE_FAMILY': '1,2',
          'GCC_VERSION': 'com.apple.compilers.llvm.clang.1_0',
          'CLANG_ENABLE_OBJC_ARC': 'YES',
          'OTHER_LDFLAGS!': [ '-lpthread', '-ldl', '-lz' ]
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
        "dependencies": [
            "../../../mapboxgl.gyp:mapboxgl-ios"
        ]
    }
  ]
}