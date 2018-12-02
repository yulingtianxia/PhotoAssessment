Pod::Spec.new do |s|
s.name = 'PhotoAssessment'
s.version = '1.0.0'
s.license = 'MIT'
s.summary = 'Swift framework for Photo Assessment using Core ML and Metal.'
s.homepage = 'https://github.com/yulingtianxia/PhotoAssessment'
s.social_media_url = 'http://twitter.com/yulingtianxia'
s.author = { "YangXiaoyu" => "yulingtianxia@gmail.com" }
s.source = { :git => 'https://github.com/yulingtianxia/PhotoAssessment.git', :tag => s.version }

s.module_name = 'PhotoAssessment'
s.ios.deployment_target = '11.0'
s.osx.deployment_target = '10.13'
s.tvos.deployment_target = '11.0'

s.source_files = 'Sources/*.{swift,mlmodel}'
end
