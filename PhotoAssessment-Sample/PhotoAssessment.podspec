Pod::Spec.new do |s|
s.name = 'PhotoAssessment'
s.version = '1.1.1'
s.license = { :type => 'MIT', :file => 'LICENSE' }
s.summary = 'Swift framework for Photo Assessment using Core ML and Metal.'
s.homepage = 'https://github.com/yulingtianxia/PhotoAssessment'
s.social_media_url = 'http://twitter.com/yulingtianxia'
s.author = { "YangXiaoyu" => "yulingtianxia@gmail.com" }
s.source = { :git => 'https://github.com/yulingtianxia/PhotoAssessment.git', :tag => s.version.to_s }

s.swift_version = '5.0'
s.module_name = 'PhotoAssessment'
s.ios.deployment_target = '11.0'
s.osx.deployment_target = '10.13'

s.source_files = 'PhotoAssessment-Sample/Sources/*.{swift,mlmodel}'
end
