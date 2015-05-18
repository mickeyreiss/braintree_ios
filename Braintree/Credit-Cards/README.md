# Braintree Credit Cards

This subspec enables you to collect credit card data in your app in a PCI Compliant manner.

Most Braintree integrations will use this code to tokenize credit card details, in order to avoid uploading credit card details to your server.

Instead, you send them directly to Braintree and receive a temporary token, called a `payment_method_nonce`. We call this strategy tokenization.

To charge the card, pass this nonce to your server and use the server-side SDKs to create a `Transaction`.

## Integration

Like all Braintree integrations, you will begin by creating a `BTClient` in order to communicate with Braintree's severs. Then, you can tokenize the card details in exchange for a nonce:

```objectivec
- (IBAction)userEnteredCreditCardDetails {
  BTClient *client = [[BTClient alloc] initWithClientToken:CLIENT_TOKEN_FROM_SERVER];
  BTCard *card = [BTCard cardWithNumber:@"4111111111111111" expirationDate:@"12/2038"];
  [client tokenizePaymentMethod:card completion:^(BTPaymentMethod *paymentMethod, NSError *error) {
    if (error) {
      NSLog(@"Failed: %@", error");
    } else {
      NSLog(@"Got a payment method nonce: %@", paymentMethod");
    }
  }];
}
```

Or similarly in Swift:

```swift
@IBAction func userEnteredCreditCardDetails() {
  let client : BTClient = BTClient(clientToken:CLIENT_TOKEN_FROM_SERVER)
  let card : BTCard = BTCard(number:"4111111111111111", expirationDate:"12/2038")
  client.tokenizePaymentMethod(card) { (paymentMethod : BTPaymentMethod?, error : NSError?) in
    if let error = error {
      println(@"Failed: %@", error");
    } 
    if let paymentMethod in paymentMethod {
      println(@"Got a payment method nonce: %@", paymentMethod");
    }
  }
}
```

### Creating a `BTCard`

In a real integration, you probably don't want to hard-code the card details. Instead, you'll probably read them from the UI:

Since each app's card form is slightly different, we provide a number of flexible options for setting up the card details:

```objectivec
- (IBAction)userEnteredCreditCardDetails:(YOURCardForm *)cardForm {
  BTCard *card;
     
  // Initialize a card with MM/YY or MM/YYYY expiration format
  card = [BTCard cardWithNumber:cardForm.numberField.text
                expirationDate:cardForm.expirationDateField.text];
                 
  // Initialize a card with MM/YY or MM/YYYY expiration format
  card = [BTCard cardWithNumber:cardForm.numberField.text
                expirationMonth:cardForm.monthField.text
                 expirationYear:cardForm.yearField.text];
                 
  // Set some additional fields
  card.cvv = cardForm.cvv.text;
  card.postalCode = cardForm.cvv.text;
}
```

You can even provide custom fields:

```objectivec
- (IBAction)userEnteredCreditCardDetails:(YOURCardForm *)cardForm {
  BTCard *card = [[BTCard alloc] init];
     
  card.number = @"411111111111111";
  
  // You can set individual fields with subscript notation
  card[BTCardParameterExpirationMonthKey]= @"12";
  card["advanced_field"]= @"special_value";
}
```

Or initialize the model from an `NSDictionary`:

```objectivec
- (IBAction)userEnteredCreditCardDetails:(YOURCardForm *)cardForm {
  BTCard *card = [BTCard cardWithParameters:@{
    BTCardParameterNumberKey: @"41111111111111111",
    BTCardParameterExpirationDateKey: @"12/38",
    @"billing_address": @{ @"postal_code": @"12345" },
    @"advanced_field": @"special_value",
  }];
}
```

You can mix and match each of these approaches. In any case, you can always use `tokenizePaymentMethod:` to create a 
payment method nonce for the data.

## UI Helpers

Please take a look at our [`Braintree/UI` subspec](../UI/README.md) for more information about our UI helpers, including
card forms, logos and validation utilities.

## Alternatives

We also support an alternative strategy, called [client side encryption](../CSE/README.md), which we consider 
deprecated. In this scheme, data is encrypted on the client-side rather than sent to Braintree for tokenization.

## See Also

This subspec is a part of the [Braintree SDK](../README.md), which includes unified support for many payment options.
