platform :ios, '9.0'
pod 'Google-Mobile-Ads-SDK', '~> 7.0'
pod 'Fabric'
pod 'Crashlytics'

# https://tech.zalando.com/blog/speeding-up-xcode-builds/
post_install do |installer|
    puts("Update debug pod settings to speed up build time")
    Dir.glob(File.join("Pods", "**", "Pods*{debug,Private}.xcconfig")).each do |file|
        File.open(file, 'a') { |f| f.puts "\nDEBUG_INFORMATION_FORMAT = dwarf" }
    end
end