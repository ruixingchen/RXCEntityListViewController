Pod::Spec.new do |spec|

  spec.name         = "RXCEntityListViewController"
  spec.version      = "1.0"

  spec.author       = { "ruixingchen" => "rxc@ruixingchen.com" }

  spec.summary      = "1"
  spec.description  = "1"
  spec.homepage     = "https://github.com/ruixingchen/RXCEntityListViewController"
  spec.license      = "MIT"

  spec.source       = { :git => "https://github.com/ruixingchen/RXCEntityListViewController.git", :tag => spec.version.to_s }
  #spec.source_files  = "Source/*.swift"

  spec.requires_arc = true
  spec.swift_versions = "5.0"
  spec.ios.deployment_target = '9.0'

  spec.default_subspecs = 'Core'
  
  spec.subspec 'Core' do |subspec|
    subspec.dependency 'RXCDiffArray', '~> 1.1'
    subspec.dependency 'RXCDiffArray/DifferenceKit'

    subspec.ios.source_files = 'Source/**/*.swift'
    subspec.ios.frameworks = 'Foundation', 'UIKit'
  end

  spec.subspec 'Texture' do |subspec|
    subspec.dependency 'Texture', '~> 2.8'
    subspec.dependency 'RXCDiffArray/ASDKExtension', '~> 1.1'
    subspec.dependency 'RXCEntityListViewController/Core'

    #subspec.ios.frameworks = 'UIKit'
  end

end
