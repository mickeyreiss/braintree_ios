# Braintree v.zero SDK for iOS

Welcome to Braintree's v.zero SDK for iOS. This CocoaPod will help you accept card, PayPal, and Venmo payments in your iOS app.

![Screenshot of v.zero](screenshot.png)

## Documentation

Start with [**'Hello, Client!'**](https://developers.braintreepayments.com/ios/start/hello-client) for instructions on basic setup and usage.

Next, read the [**full documentation**](https://developers.braintreepayments.com/ios/sdk/client) for information about integration options, such as Drop-In UI, custom payment button, and credit card tokenization.

Finally, [**cocoadocs.org/docsets/Braintree**](http://cocoadocs.org/docsets/Braintree) hosts the complete, up-to-date API documentation generated straight from the header files.

### Quick Start

Add Braintree via CocoaPods:

```ruby
# Integrates the most common Braintree integration:
pod 'Braintree'
```

Then run `pod install`.

If you are not already using CocoaPods, please follow [the official setup guide](https://guides.cocoapods.org/using/getting-started.html).

It is also possible to [integrate the library without CocoaPods](Docs/Manual Integration.md).

It is also possible to [integrate the library with Carthage](Docs/Carthage Integration.md).

## Demo

A demo app is included in project. To run it, run `pod install` and then open `Braintree.xcworkspace` in Xcode. See the [README](Demos/Braintree-Demo/README.md) for more details.

## Features

This SDK enables you to collect payment details securely in your iOS app.

We support the following payment options:

* Credit Card Tokenization - The preferred mechanism for transmitting PCI-scope data directly to Braintree's servers in exchange for a payment method nonce.
* PayPal (Vault) - Obtain One Touch consent for future payments against a consumer's PayPal account
* PayPal (Checkout) - Perform a single PayPal payment with One Touch, including a contextual checkout flow and shipping address collection
* Coinbase - Accept bitcoin by obtaining consent to charge a consumer's Coinbase account 
* Venmo - Add credit cards from the user's Venmo account to your vault with One Touch
* Apple Pay - Enable users to checkout with Touch ID
* Credit Card Encryption - A deprecated alternative to tokenization, in which the data is encrypted client-side and transmitted to Braintree via your server

We also provide tools to help reduce fraud:

* 3D Secure - An additional layer of verification for enrolled credit cards, whereby issuers can authenticate cardholders directly
* Braintree Data - Tools for collecting device metadata in order to prevent and detect fraud

Finally, we provide code to make it fast and simple to build your mobile payment experience:

* Drop in - A complete checkout view controller or payment button in just a few lines of code
* UI - A suite of views, assets and utilities that solve common UI problems for apps that accept payments

Each of these is provided by a CocoaPods subspec, which keeps the integration lean and focused on the code you need.

Please see the individual READMEs for more information about each of these integrations.

## Subspecs

If you'd like to integrate only certain features, we provide a number of subspecs. Add any or all of these lines to your `Podfile` to integrate only the pieces you need:

```ruby
# Pick and choose the pieces that matter to you:
# pod 'Braintree/3D-Secure'
# pod 'Braintree/Apple-Pay'
# pod 'Braintree/CSE'
# pod 'Braintree/Coinbase'
# pod 'Braintree/Credit-Cards'
# pod 'Braintree/Data' # Advanced fraud protection
# pod 'Braintree/Drop-in'
# pod 'Braintree/PayPal'
# pod 'Braintree/UI'
# pod 'Braintree/Venmo'
```

## Help

* [Read the headers](Braintree/Braintree.h)
* [Read the docs](https://developers.braintreepayments.com/ios/sdk/client)
* Find a bug? [Open an issue](https://github.com/braintree/braintree_ios/issues)
* Want to contribute? [Check out contributing guidelines](CONTRIBUTING.md) and [submit a pull request](https://help.github.com/articles/creating-a-pull-request).

## Contributing

This SDK is built by collaboration between the Braintree team and the open source community.

We welcome pull requests on Github and have published our [contributing standards](CONTRIBUTING.md) in this repository.

## Feedback

Braintree iOS is in active development. We appreciate the time you take to try it out and welcome your feedback!

Here are a few ways to get in touch:

* [GitHub Issues](https://github.com/braintree/braintree_ios/issues) - For reporting bugs and feature requests
* support@braintreepayments.com - For individual support at any phase of integration
* https://support.braintreepayments.com - For more information about our wonderful support team 

### License

The Braintree iOS SDK is open source and available under the MIT license. See the [LICENSE](LICENSE) file for more info.
