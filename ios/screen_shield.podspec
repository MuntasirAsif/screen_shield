#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint screen_shield.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'screen_shield'
  s.version          = '0.1.3'
  s.summary          = 'Block screenshots/recording and detect screen capture on iOS and Android.'
  s.description      = <<-DESC
Block screenshots and screen recording, and detect screen capture/mirroring, on Android and iOS.
                       DESC
  s.homepage         = 'https://github.com/MuntasirAsif/screen_shield'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Muhammad Muntasir Mahamud Ashif' => 'muntasirashifee@gmail.com' }
  s.source           = { :path => '.' }
  s.source_files = 'screen_shield/Sources/screen_shield/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '15.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'

  # If your plugin requires a privacy manifest, for example if it uses any
  # required reason APIs, update the PrivacyInfo.xcprivacy file to describe your
  # plugin's privacy impact, and then uncomment this line. For more information,
  # see https://developer.apple.com/documentation/bundleresources/privacy_manifest_files
  # s.resource_bundles = {'screen_shield_privacy' => ['screen_shield/Sources/screen_shield/PrivacyInfo.xcprivacy']}
end
