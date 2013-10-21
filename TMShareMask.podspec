Pod::Spec.new do |s|
  s.name         = "TMShareMask"
  s.version      = "0.2.2"
  s.summary      = "Thinker Mobile for Project,  share text on SMS, email, Facebook or Line ."
  s.homepage     = "https://github.com/willsbor/TMShareMask"
  s.license      = 'MIT'
  s.author       = { "KangKang" => "kang@thinkermobile.com" }
  s.source       = { :git => "https://github.com/willsbor/TMShareMask.git", :tag => "#{s.version}" }
  s.platform     = :ios, '5.0'
  s.ios.deployment_target = '5.0'
  s.source_files = 'TMShareMask/TMShareMask'
  s.framework  = 'CoreGraphics', 'MessageUI'
  s.requires_arc = true
  s.dependency 'Facebook-iOS-SDK',  '~> 3.8.0'
  s.dependency 'LineKit'
  s.dependency 'NSLogger',   '>=1.1'
end
