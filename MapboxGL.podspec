Pod::Spec.new do |m|

  m.name    = 'MapboxGL'
  m.version = '0.1.0'

  m.summary          = 'Open source vector map solution for iOS with full styling capabilities.'
  m.description      = 'Open source OpenGL-based vector map solution for iOS with full styling capabilities and Cocoa bindings.'
  m.homepage         = 'https://www.mapbox.com/blog/mapbox-gl/'
  m.license          = 'BSD'
  m.author           = { 'Mapbox' => 'mobile@mapbox.com' }
  m.screenshot       = 'https://raw.githubusercontent.com/mapbox/mapbox-gl-cocoa/master/pkg/screenshot.png'
  m.social_media_url = 'https://twitter.com/Mapbox'

  m.source = { :git => 'https://github.com/mapbox/mapbox-gl-cocoa.git', :tag => m.version.to_s }

  m.platform              = :ios
  m.ios.deployment_target = '7.0'

  m.source_files = 'dist/Headers/*.h', 'dist/MapboxGL.mm'

  m.requires_arc = true

  m.resource_bundle = { 'MapboxGL' => 'dist/MapboxGL.bundle/*' }

  m.frameworks = 'CoreLocation', 'Foundation', 'GLKit', 'UIKit'

  m.libraries = 'z'

  m.vendored_libraries = 'dist/libMapboxGL.a'

end
