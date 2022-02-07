# Uncomment the next line to define a global platform for your project
platform :ios, '9.0'

target 'Switch Shoutout' do
  # Comment the next line if you're not using Swift and don't want to use dynamic frameworks
  use_frameworks!

  # Pods for Switch Shoutout

  pod 'Firebase'
  pod 'Firebase/Auth'
  pod 'Firebase/Database'
  pod 'FirebaseStorage'
  pod 'FirebaseUI/Storage'
  pod 'UIWindowTransitions'
  pod 'InputMask'
  pod 'SVProgressHUD'
  pod 'ReachabilitySwift'
  pod 'DZNEmptyDataSet'
  pod 'Alamofire'
  pod 'AlamofireImage'
  pod 'OneSignal', '>= 2.5.2', '< 3.0'
  #pod 'Chatto'
  #pod 'ChattoAdditions'

end

target 'OneSignalNotificationServiceExtension' do
    use_frameworks!
    
    pod 'OneSignal', '>= 2.6.2', '< 3.0'
end

post_install do |installer|
    installer.pods_project.targets.each do |target|
        target.build_configurations.each do |config|
            config.build_settings['CLANG_WARN_DOCUMENTATION_COMMENTS'] = 'NO'
        end
    end
end
