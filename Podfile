# Uncomment the next line to define a global platform for your project
platform :ios, '12.0'

target 'XLSV' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!
  pod 'SSZipArchive'
  pod 'CoreXLSX', '~> 0.14.1'
  pod 'Google-Mobile-Ads-SDK'
  pod 'Zip', '~> 2.1'
#  Maybe set on this next version
#  pod 'GoogleAPIClientForREST', '~> 3.5'
#  pod 'GoogleAPIClientForREST/Drive'
#  pod 'GoogleSignIn', '7.1.0-fac-eap-1.0.0'
  pod 'SwiftyXMLParser'
  pod 'SWXMLHash'


  # Pods for MultiDirectionCollectionView

end

post_install do |installer|
  # Some pods (e.g. CoreXLSX) declare a deployment target below the app's (iOS 12.0) while
  # depending on pods that require 12.0 (ZIPFoundation) -- Xcode's strict module system
  # refuses to link a 9.0-targeted module against a 12.0-only dependency. Align every pod's
  # deployment target up to the app's minimum so they stay linkable.
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      deployment_target = config.build_settings['IPHONEOS_DEPLOYMENT_TARGET']
      if deployment_target && deployment_target.to_f < 12.0
        config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '12.0'
      end
    end
  end
end

