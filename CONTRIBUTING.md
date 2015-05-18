# Contribute

Thanks for considering contributing to this project. Ways you can
help:

* [Create a pull request](https://help.github.com/articles/creating-a-pull-request) 
* [Add an issue](https://github.com/braintree/braintree_ios/issues)
* [Contact us](README.md#feedback) with feedback

## Development

Clone this repo, then install the project's development dependencies:

``` 
gem install bundler bundle install 
```

This installs [CocoaPods](http://cocoapods.org/), which you can
then use to obtain all the iOS dependencies:

``` 
pod install 
```

## Style and Technical Requirements

Please try to maintain a clean consistent code style.

Please provide test coverage around code changes as much as possible.

As an SDK, we strive to be as low-risk and isolated as possible.
Therefore, we avoid dependencies and global state as much as possible.

We officially support only the most recent version of Xcode and the
iOS Base SDK. At runtime, we support the current and previous major
version of iOS on all compatible devices.

This SDK is generally developed in a manner consistent with typical
open source development on Github. Certain features are developed
privately within Braintree and then released publicly upon completion.

While we consider the `master` branch to be stable, our officially
supported builds are tagged with [semver](https://semver.org)-compliant
version numbers and published on [CocoaPods
trunk](https://cocoapods.org/?q=braintree).

For purposes of backwards compatibility, our public API is defined
by our CocoaPods podspec. Public header files are documented for
publication on [cocoadocs](http://cocoadocs.org/docsets/Braintree).

## SDK Architecture

This SDK is a part of Braintree v.zero. The main responsibility of
this SDK is payment method tokenization. It is initialized with a
client token for configuration and Braintree Client API authorization.
The reference to tokenized payment details is called a `payment
method nonce`.

The SDK is divided into a number of loosely coupled subspecs, which
are effectively modules that provide the client-side component of
a single Braintree product. Each subspec consists of a public API,
as well as a number of internal collaborator classes and/or
dependencies.

The `Braintree/Core` subspec provides shared functionality and is
primarily focused on secure communication with the Braintree Client
API.

## Environments

The architecture of the Braintree client API means that it is not
possible to run all types of integration tests without a Braintree
development environment (which, unfortunately, is not accessible
to the public).

Our demo app has two sample merchant servers, for sandbox and
production respectively, that are available on the internet. It is
also possible to use your own merchant server. This will require
you to integrate a  server-side client library, such as
 [`braintree_ruby`](https://github.com/braintree/braintree_ruby).

The various Braintree Gateway environments, such as `development`,
`sandbox` and `production`, are determined by the client token,
with which the Braintree client is initialized. This client token
is generated on the server-side and drives the client-side behavior
around environments, processing rules, merchant accounts, credit
cards, PayPal, etc.

## Tests

Use [Rake](http://rake.rubyforge.org/) to run tests or create
releases. To view available rake tasks:

``` rake -T ```

It is not possible to run all integration tests externally to
Braintree.

