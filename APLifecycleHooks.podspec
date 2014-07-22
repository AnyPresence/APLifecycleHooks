Pod::Spec.new do |s|
  s.name             = "APLifecycleHooks"
  s.version          = "0.0.1"
  s.summary          = "Add events to private methods of AnyPresence iOS SDK"
  s.description      = <<-DESC
Allows you to write custom code for events in the iOS SDK. For example, you can now write a logout function that fires whenever you recieve a 401.
                       DESC
  s.homepage         = "https://github.com/AnyPresence/APLifecycleHooks"
  s.license          = 'MIT'
  s.author           = { "David Benko" => "dbenko@anypresence.com" }
  s.source           = { :git => "https://github.com/AnyPresence/APLifecycleHooks.git", :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/davidwbenko'

  s.platform     = :ios
  s.requires_arc = true

  s.source_files = 'APLifecycleHooks/**/*.{h,m}'
end
