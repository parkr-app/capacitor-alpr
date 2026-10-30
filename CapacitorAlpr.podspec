require 'json'

package = JSON.parse(File.read(File.join(__dir__, 'package.json')))

Pod::Spec.new do |s|
  s.name = 'CapacitorAlpr'
  s.version = package['version']
  s.summary = package['description']
  s.license = package['license']
  s.homepage = 'https://alpr.parkr.app'
  s.author = package['author']
  s.source = { :git => package['repository']['url'], :tag => "v#{s.version}" }
  s.source_files = 'ios/Sources/**/*.swift'
  s.vendored_frameworks = 'ios/Frameworks/AlprKit.xcframework'
  s.frameworks = 'AVFoundation', 'UIKit'
  s.ios.deployment_target = '15.1'
  s.dependency 'Capacitor'
  s.swift_version = '5.9'
end
