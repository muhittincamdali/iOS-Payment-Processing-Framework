Pod::Spec.new do |s|
  s.name             = 'iOSPaymentProcessingFramework'
  s.version          = '1.0.0'
  s.summary          = 'Payment processing framework for iOS with Apple Pay and Stripe support.'
  s.description      = <<-DESC
    iOSPaymentProcessingFramework provides complete payment processing for iOS.
    Features include Apple Pay integration, Stripe support, secure tokenization,
    subscription management, and PCI-compliant payment handling.
  DESC

  s.homepage         = 'https://github.com/muhittincamdali/iOS-Payment-Processing-Framework'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Muhittin Camdali' => 'contact@muhittincamdali.com' }
  s.source           = { :git => 'https://github.com/muhittincamdali/iOS-Payment-Processing-Framework.git', :tag => s.version.to_s }

  s.ios.deployment_target = '15.0'

  s.swift_versions = ['5.9', '5.10', '6.0']
  s.source_files = 'Sources/**/*.swift'
  s.frameworks = 'Foundation', 'PassKit', 'StoreKit'
end
