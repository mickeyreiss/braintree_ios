# Braintree Data - Advanced Fraud Protection

## Overview

`Braintree/Data` is our advanced fraud solution that is powered by `BTDataCollector`, PayPal and Kount. This system enables you to collect device data and correlate it with a session identifier on your server.

For credit cards, we have partnered with Kount. By default, we utilized an aggregated set of credentials and fraud rules.

It is also possible to use your own Fraud Merchant ID and collector url. For more information about theKount Direct fraud integration, please see [our documentation](https://developers.braintreepayments.com/ios/guides/fraud-tools#direct-fraud-tool-integration) or [contact our accounts team](accounts@braintreepayments.com).

For PayPal transactions, we automatically include the appropriate client metadata when tokenizing an account for saving it in the vault. For enhanced fraud protection, you should include device data in the background whenever you create transaction from a PayPal account that is saved in the vault.

### Usage

If you haven't already, integrate the Braintree SDK.
    * See [our documentation](https://developers.braintreepayments.com/ios/start/hello-client) for instructions on initializing BTClient

First, add the `Braintree/Data` dependencies to your `Podfile`.

```ruby
pod "Braintree/Data"
```

Note that you can also use `Braintree/Data/Kount` or `Braintree/Data/PayPal` if you would like to omit unneeded dependencies.

Next, follow these steps to collect device metadata:
    
1. Import `BTDataCollector` in your payment view controller:

```objectivec
- (void)viewDidLoad {
  [super viewDidLoad];
  self.data = [[BTDataCollector alloc] initWithClient:self.client];
  
  // Optionally, set a delegate to receive lifecycle notifications.
  self.data.delegate = self;
```

For best results, you should reuse your instance of `BTClient` and perform this initialization at a point when it would not cause a delay in your checkout UX. Please retain your `BTDataCollector` instance for your view controller's lifecycle.

3. Invoke `collect` (to generate a session id) as often as is needed. This will perform a device fingerprint and asynchronously send this data to Kount. This operation is relatively expensive. We recommend that you do this seldom and avoid interrupting your app startup with this call.

```objectivec
  NSString *deviceData = [self.data collectDeviceData];
  // Send deviceData to your server along with the payment method nonce.
}
```

#### Kount Direct

Kount Direct is for merchants with specific fraud prevention needs.

After initializing `BTDataCollector` following the instructions above, invoke `setCollectorUrl:` and/or `setKountMerchantId:` with the appropriate data.

Please contact our [accounts](accounts@getbraintree.com) team for more information.

### Server-Side Integration

When processing a user's purchase, pass the session id (returned by `collect` or passed into `collect:`) along with the other transaction details to your server. 

On your *server* include the session id in your request to Braintree.

For example in Ruby:

```ruby
result = Braintree::Transaction.sale(
  :amount => "100.00",
  :credit_card => {
    :number => params["credit_card_number"],
    :expiration_date => params["credit_card_expiration_date"],
    :cvv => params["credit_card_cvv"]
  },
  :device_data => params["BRAINTREE_DEVICE_DATA"]
)
```
