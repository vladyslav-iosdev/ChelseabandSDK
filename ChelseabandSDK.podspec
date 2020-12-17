#
# Be sure to run `pod lib lint ChelseabandSDK.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'ChelseabandSDK'
  s.version          = '1.0.3'
  s.summary          = 'Chelsea band library'
  s.description      = <<-DESC
ChelseabandSDK is a Bluetooth library that makes interaction with Chealsea band BLE devices much more pleasant. It's backed by RxSwift and CoreBluetooth and it provides nice API, for both Central and Peripheral modes. All to work with and make your code more readable, reliable and easier to maintain.
                       DESC
  s.homepage         = 'https://github.com/vladyslav-iosdev/ChelseabandSDK'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'vladyslav-iosdev' => 'vladyslav.shepitko@gmail.com' }
  s.source           = { :git => 'https://github.com/vladyslav-iosdev/ChelseabandSDK.git', :tag => s.version.to_s }
  s.ios.deployment_target = '11.0'
  s.swift_version = '5.0'
  s.source_files = 'ChelseabandSDK/Sources/**/*'
  s.dependency 'RxBluetoothKit', '~> 6.0.0'
  s.dependency 'RxCocoa', '~> 5.1.1' 

end
