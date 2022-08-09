
Pod::Spec.new do |s|
  s.name          = 'react-native-aes-forked'
  s.version       = '2.1.0-forked'
  s.summary       = 'Native module for AES encryption Forked'
  s.author        = "artzlabs"
  s.license       = 'MIT'
  s.requires_arc  = true
  s.homepage      = "https://github.com/artzlabs/react-native-aes-crypto-forked"
  s.source        = { :git => 'https://github.com/artzlabs/react-native-aes-crypto-forked', :tag => "v#{s.version}" }
  s.platform      = :ios, '9.0'
  s.source_files  = "ios/**/*.{h,m}"

  s.dependency "React-Core"
end
