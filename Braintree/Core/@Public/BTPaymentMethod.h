@import Foundation;

NS_ASSUME_NONNULL_BEGIN

/// Card type
typedef NS_ENUM(NSInteger, BTPaymentMethodType) {
    BTPaymentMethodTypeUnknown = 0,
    BTPaymentMethodTypeAMEX,
    BTPaymentMethodTypeDinersClub,
    BTPaymentMethodTypeDiscover,
    BTPaymentMethodTypeMasterCard,
    BTPaymentMethodTypeVisa,
    BTPaymentMethodTypeJCB,
    BTPaymentMethodTypeLaser,
    BTPaymentMethodTypeMaestro,
    BTPaymentMethodTypeUnionPay,
    BTPaymentMethodTypeSolo,
    BTPaymentMethodTypeSwitch,
    BTPaymentMethodTypeUKMaestro,
    BTPaymentMethodTypeCoinbase,
    BTPaymentMethodTypePayPalAccount,
    BTPaymentMethodTypePayPalCheckout,
    BTPaymentMethodTypeApplePayPayment,
};

/// A payment method returned by the Client API that represents a payment method associated with
/// a particular Braintree customer.
///
/// See also: BTCardPaymentMethod and BTPayPalPaymentMethod.
@interface BTPaymentMethod : NSObject <NSCopying, NSCoding>

/// Unique token that, if unlocked, may be used to create payments
///
/// Pass this value to the server for use as the `payment_method_nonce`
/// argument of Braintree server-side client library methods.
@property (nonatomic, readonly, copy) NSString *nonce;

/// A user-friendly description of the payment method suitable for display
///
/// For example:
///   * "Visa ending in 11" (for a credit card)
///   * "johnny@example.com" (for a PayPal account)
@property (nonatomic, readonly, copy) NSString *name;

/// The type of the payment method
///
/// See BTUIPaymentMethodUtils for a method to obtain a string
/// representation of this value for display.
@property (nonatomic, readonly, assign) BTPaymentMethodType type;

/// Whether or not this payment method is single use or may be saved in the vault
///
/// For example, Apple Pay is always single use, while credit cards may always be saved in the vault.
@property (nonatomic, readonly, assign) BOOL singleUse;

/// Information about the 3D Secure liability shift (present only if applicable)
@property (nonatomic, readonly, strong, nullable) NSDictionary *threeDSecureInfo;

@end

NS_ASSUME_NONNULL_END
