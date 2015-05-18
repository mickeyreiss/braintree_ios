Pod::Spec.new do |s|
  s.name             = "Braintree"
  s.version          = "4.0.0-pre1"
  s.summary          = "Braintree iOS: Accept payments in your app"
  s.description      = <<-DESC
                       Braintree is a full-stack payments platform for developers.

                       This CocoaPod will help you accept payments in your iOS app

                       We provide tokenization, alternative payment methods, One Touch, UI.

                       Choose the subpsecs you need for your app.

                       Check out our development portal at https://developers.braintreepayments.com.
  DESC
  s.homepage         = "https://www.braintreepayments.com/"
  s.documentation_url = "https://developers.braintreepayments.com/ios/"
  s.screenshots      = "https://raw.githubusercontent.com/braintree/braintree_ios/master/screenshot.png"
  s.license          = "MIT"
  s.author           = { "Braintree" => "code@getbraintree.com" }
  s.source           = { :git => "https://github.com/braintree/braintree_ios.git", :tag => s.version.to_s }
  s.social_media_url = "https://twitter.com/braintree"

  s.platform         = :ios, "7.0"
  s.requires_arc     = true

  s.compiler_flags = "-Wall -Werror -Wextra"

  s.frameworks = "Foundation"

  s.default_subspecs = %w[Drop-In Credit-Cards PayPal]

  # DROP IN

  s.subspec "Drop-In" do |s|
    s.source_files  = "Braintree/Drop-In/**/*.{h,m}"
    s.public_header_files  = "Braintree/Drop-In/@Public/*.h"
    s.frameworks = "UIKit"
    s.dependency "Braintree/Core"
    s.dependency "Braintree/PayPal"
    s.dependency "Braintree/UI"
    s.dependency "Braintree/Venmo"
    s.dependency "Braintree/Coinbase"
    s.resource_bundle = { "Braintree-Drop-In-Localization" => "Braintree/Drop-In/Localization/*.lproj" }
  end

  # PAYMENT METHODS AND INTEGRATIONS

  s.subspec "Credit-Cards" do |s|
    s.source_files = "Braintree/Credit-Cards/**/*.{h,m}"
    s.public_header_files = "Braintree/Credit-Cards/*.h"

    s.dependency "Braintree/Core"

    s.subspec "CSE" do |s|
      s.source_files = "Braintree/CSE/**/*.{h,m}"
      s.public_header_files = "Braintree/CSE/*.h"
    end

    s.subspec "3D-Secure" do |s|
      s.source_files = "Braintree/3D-Secure/**/*.{h,m}"
      s.public_header_files = "Braintree/3D-Secure/@Public/*.h"
      s.frameworks = "UIKit"
      s.dependency "Braintree/Core"
      s.dependency "Braintree/UI"
      s.resource_bundle = { "Braintree-3D-Secure-Localization" => "Braintree/3D-Secure/Localization/*.lproj" }
    end
  end

  s.subspec "Apple-Pay" do |s|
    s.dependency "Braintree/Core"
  end

  s.subspec "PayPal" do |s|
    s.source_files = "Braintree/PayPal/**/*.{h,m}"
    s.public_header_files = "Braintree/PayPal/@Public/*.h"
    s.frameworks = "CoreLocation", "MessageUI", "SystemConfiguration"
    s.vendored_library = "Braintree/PayPal/PayPalOneTouchCore/libPayPalOneTouchCore.a"
    s.xcconfig = { "OTHER_LDFLAGS" => "-ObjC -lc++" }
    s.dependency "Braintree/Core"
  end

  s.subspec "Venmo" do |s|
    s.source_files = "Braintree/Venmo/**/*.{h,m}"
    s.public_header_files = "Braintree/Venmo/@Public/*.h"
    s.dependency "Braintree/Core"
  end

  s.subspec "Coinbase" do |s|
    s.source_files = "Braintree/Coinbase/**/*.{h,m}"
    s.public_header_files = "Braintree/Coinbase/@Public/*.h"
    s.dependency "coinbase-official/OAuth", "~> 2.1.1"
    s.dependency "Braintree/Core"
  end

  s.subspec "Data" do |s|
    s.source_files = "Braintree/Data/Core/**/{.h,m}"
    s.public_header_files = "Braintree/Data/Core/*.h"

    s.subspec "Kount" do |s|
        s.source_files = "Braintree/Data/Kount/**/{.h,m}"
        s.public_header_files = "Braintree/Data/Kount/*.h"

        s.frameworks = "UIKit", "SystemConfiguration"

        s.vendored_library = "Braintree/Data/Kount/libDeviceCollectorLibrary.a"
    end

    s.subspec "PayPal" do |s|
        s.source_files = "Braintree/Data/PayPal/**/{.h,m}"
        s.public_header_files = "Braintree/Data/PayPal/*.h"

        s.dependency "Braintree/PayPal"
    end
  end

  # UI

  s.subspec "UI" do |s|
    s.source_files  = "Braintree/UI/**/*.{h,m}"
    s.public_header_files = "Braintree/UI/@Public/*.h"
    s.frameworks = "UIKit"
    s.resource_bundle = { "Braintree-UI-Localization" => "Braintree/UI/Localization/*.lproj" }
    s.dependency "Braintree/Core"
  end

  # CORE

  s.subspec "Core" do |s|
    s.source_files  = "Braintree/Core/**/*.{h,m}"
    s.public_header_files = "Braintree/API/@Public/*.h"
    s.frameworks = "AddressBook"
  end
end

