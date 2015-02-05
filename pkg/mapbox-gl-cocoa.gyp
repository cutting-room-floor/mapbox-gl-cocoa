{
  'target_defaults': {
    'product_name': 'MapboxGL',
    'variables' : {
      'ldflags': [
        '<@(sqlite3_ldflags)',
        '<@(uv_ldflags)',
        '<@(zlib_ldflags)',
      ]
    },
    'xcode_settings': {
      'SDKROOT': 'iphoneos',
      'SUPPORTED_PLATFORMS':['iphonesimulator','iphoneos'],
      'ARCHS': [ 'armv7', 'armv7s', 'arm64', 'i386', 'x86_64' ],
      'CLANG_CXX_LIBRARY': 'libc++',
      'CLANG_CXX_LANGUAGE_STANDARD':'c++11',
      'TARGETED_DEVICE_FAMILY': '1,2',
      'GCC_VERSION': 'com.apple.compilers.llvm.clang.1_0',
      'CLANG_ENABLE_OBJC_ARC': 'YES',
      'OTHER_CPLUSPLUSFLAGS': [ '<@(uv_cflags)' ],
      'OTHER_LDFLAGS!': [ '-lpthread', '-ldl', '-lz', '<@(ldflags)' ],
      'COMBINE_HIDPI_IMAGES': 'NO'
    },
    'link_settings': {
      'libraries': [
        '$(SDKROOT)/System/Library/Frameworks/CoreGraphics.framework',
        '$(SDKROOT)/System/Library/Frameworks/CoreLocation.framework',
        '$(SDKROOT)/System/Library/Frameworks/GLKit.framework',
        '$(SDKROOT)/System/Library/Frameworks/OpenGLES.framework',
        '$(SDKROOT)/System/Library/Frameworks/SystemConfiguration.framework',
        '$(SDKROOT)/System/Library/Frameworks/UIKit.framework'
      ],
    },
    'configurations': {
      'Debug': {
        'xcode_settings': {
          'CODE_SIGN_IDENTITY': 'iPhone Developer',
        }
      },
      'Release': {
        'xcode_settings': {
          'CODE_SIGN_IDENTITY': 'iPhone Developer',
        }
      }
    },
    'default_configuration': 'Release',
  },
  'targets': [
    {
      'target_name': 'mapbox-library',
      'type': 'static_library',
      'sources': [
        '<!@(find ../mapbox-gl-cocoa -type f -name "MGLMapView.*")',
        '<!@(find ../mapbox-gl-cocoa -type f -name "MGLStyleFunctionValue.*")',
        '<!@(find ../mapbox-gl-cocoa -type f -name "MGLTypes.*")',
        '<!@(find ../mapbox-gl-cocoa -type f -name "*+MGLAdditions.*")',
        '<!@(find ../../../include/mbgl/platform/darwin -type f)',
        '<!@(find ../../../platform/darwin -type f)',
        '<!@(find ../../../platform/ios -type f)'
      ],
      'copies': [
        {
          'files': [
            '<!@(find ../mapbox-gl-cocoa -type f -name "*.h")'
          ],
          'destination': '../dist/static/Headers'
        }
      ],
      'dependencies': [
          '../../../mapboxgl.gyp:mbgl-ios'
      ],
      'xcode_settings': {
        'IPHONEOS_DEPLOYMENT_TARGET':'7.0'
      }
    },
    {
      'target_name': 'mapbox-framework',
      'type': 'shared_library',
      'sources': [
        '<!@(find ../mapbox-gl-cocoa -type f -name "MGLMapView.*")',
        '<!@(find ../mapbox-gl-cocoa -type f -name "MGLStyleFunctionValue.*")',
        '<!@(find ../mapbox-gl-cocoa -type f -name "MGLTypes.*")',
        '<!@(find ../mapbox-gl-cocoa -type f -name "*+MGLAdditions.*")',
        '<!@(find ../../../include/mbgl/platform/darwin -type f)',
        '<!@(find ../../../platform/darwin -type f)',
        '<!@(find ../../../platform/ios -type f)'
      ],
      'mac_bundle': 1,
      'mac_bundle_resources': [
        '<(PRODUCT_DIR)/Headers',
        '<!@(find ../dist/static -type d -name MapboxGL.bundle)',
        '<!@(find ../dist -type f -name versions.txt)'
      ],
      'copies': [
        {
          'files': [
            '<!@(find ../mapbox-gl-cocoa -type f -name "*.h")',
            './MapboxGL.h'
          ],
          'destination': '<(PRODUCT_DIR)/Headers'
        }
      ],
      'link_settings': {
        'libraries': [
          'libz.dylib'
        ],
      },
      'dependencies': [
          '../../../mapboxgl.gyp:mbgl-ios'
      ],
      'xcode_settings': {
        'IPHONEOS_DEPLOYMENT_TARGET':'8.0',
        'INFOPLIST_FILE': 'framework-info.plist',
        'DEFINES_MODULE': 'YES',
        'CLANG_ENABLE_MODULES': 'YES',
        'DYLIB_COMPATIBILITY_VERSION': 1,
        'DYLIB_CURRENT_VERSION': 1,
        'CURRENT_PROJECT_VERSION': 1,
        'VERSIONING_SYSTEM': 'Apple Generic',
        'DYLIB_INSTALL_NAME_BASE': '@rpath',
        'LD_RUNPATH_SEARCH_PATHS': [
          '@executable_path/Frameworks',
          '@loader_path/Frameworks'
        ]
      },
    }
  ]
}