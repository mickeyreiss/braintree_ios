@import Foundation;

#import "BTPayPalPaymentMethod.h"
#import "BTClient.h"

NS_ASSUME_NONNULL_BEGIN

@class BTPayPalCheckout;
@protocol BTPayPalDriverDelegate;

/// The BTPayPal enables you to obtain permission to charge your customers' PayPal accounts.
///
/// @note To make PayPal available, you must ensure that PayPal is enabled in your Braintree control panel. See our [online documentation](https://developers.braintreepayments.com/ios+ruby/guides/paypal) for details.
///
/// This class supports two basic use-cases: Vault and Checkout. Each of these involves variations on the user experience as well as variations on the capabilities granted to you by this authorization.
///
/// The *Vault* option uses PayPal's future payments authorization, which allows your merchant account to charge this customer arbitrary amounts for a long period of time into the future (unless the user manually revokes this permission in their PayPal control panel.) This authorization flow includes an screen with legal language that directs the user to agree to the terms of Future Payments. Unfortunately, it is not currently possible to collect shipping information in the Vault flow.
///
/// The *Checkout* option creates a one-time use PayPal payment on your behalf. As a result, you must specify the checkout details up-front, so that they can be shown to the user during the PayPal flow. With this flow, you must specify the estimated transaction amount, and you can collect shipping details. While this flow omits the Future Payments agreement, the resulting payment method cannot be stored in the vault. It is only possible to create one Braintree transaction with this form of user approval.
///
/// Both of these flows are available to all users on any iOS device. If the PayPal app is installed on the device, the PayPal login flow will take place there via an app switch. Otherwise, PayPal login takes place in the Safari browser.
///
/// Regardless of the type or target, all of these user experiences take full advantage of One Touch. This means that users may bypass the username/password entry screen when they are already logged in.
///
/// Upon successful completion, you will receive a BTPayPalPaymentMethod, which includes user-facing details and a payment method nonce, which you must pass to your server in order to create a transaction or save the authorization in the Braintree vault (not possible with Checkout).
///
/// ## User Experience Details
///
/// To keep your UI in sync during app switch authentication, you may set a delegate, which will receive notifications as the PayPal driver progresses through the various steps necessary for user authentication.
///
/// To help you decide how to present PayPal in your UI, helper methods are provided to indicate whether PayPal is available and whether the PayPal app is installed on this device.
@interface BTPayPalDriver : NSObject

/// Initializes a PayPal app switch
///
/// @param client An instance of BTClient for communicating with Braintree
///
/// @return A instance that is ready to perform authorization or checkout
- (nonnull instancetype)initWithClient:(nonnull BTClient *)client NS_DESIGNATED_INITIALIZER;


#pragma mark - PayPal Login

/// Authorize a PayPal user for saving their account in the Vault via app switch to the PayPal App or the browser.
///
/// On success, you will receive a paymentMethod, on failure, an error, on user cancelation, you will receive nil for both parameters.
///
/// Note that during the app switch authorization, the user may switch back to your app manually. In this case, the caller will not receive a cancelation via the completionBlock. Rather, it is the caller's responsibility to observe `UIApplicationDidBecomeActiveNotification` and `UIApplicationWillResignActiveNotification` using `NSNotificationCenter` if necessary.
///
/// @param completionBlock This completion will be invoked exactly once when authorization is complete or an error occurs.
- (void)startAuthorizationWithCompletion:(void (^)(BTPayPalPaymentMethod *__nullable paymentMethod, NSError *__nullable error))completionBlock;

/// Checkout with PayPal for creating a transaction with a PayPal single payment via app switch to the PayPal App or the browser.
///
/// @param completionBlock This completion will be invoked when authorization is complete.
- (void)startCheckout:(BTPayPalCheckout *)checkout completion:(void (^)(BTPayPalPaymentMethod *__nullable paymentMethod, NSError *__nullable error))completionBlock;


#pragma mark - App Switch

/// Set the URL scheme that will be used to return to this app
///
/// This is needed for instructing the PayPal authentication on how to return to your app.
///
/// Your URL scheme must be registered in your info.plist, and it must start with your app's bundle identifier.
///
/// @param scheme a URL scheme
- (void)setReturnURLScheme:(NSString *)scheme;


/// Pass control back into BTPayPal after an app switch return. You must call this method in application:openURL:sourceApplication:annotation.
///
/// @param url the URL you receive in application:openURL:sourceApplication:annotation when PayPal returns back to your app
+ (void)handleAppSwitchReturnURL:(NSURL *)url;


#pragma mark - UX Helpers

/// An optional delegate for receiving notifications about the lifecycle of a PayPal app switch for updating your UI
@property (nonatomic, weak, nullable) id<BTPayPalDriverDelegate> delegate;

/// Check whether or not it is possible to pay with PayPal (e.g. is your merchant account enabled in the Braintree control panel).
///
/// You should always check whether PayPal is available before displaying any PayPal UI in your checkout form.
///
/// @return YES iff PayPal is available
- (BOOL)isAvailable;

/// Identify whether this user is a likely candidate for One Touch based on the presence of the PayPal app.
///
/// You may use this method to increase the prominence of your PayPal button for certain users.
///
/// @return YES iff the PayPal app is available on this device
+ (BOOL)isAppInstalled;


#pragma mark - Fraud Data

/// Collect data for PayPal fraud detection.
///
/// This occurs automatically when you use startAuthorizationWithCompletion: or startCheckout:completion:.
///
/// You should call this method immediatley before creating a transaction with a PayPal account
/// stored in the vault. This will provide PayPal with the most recent possible fraud data without any
/// impact on the user experience. By doing this, your vault transactions are less likely to be declined.
///
/// When you call this method, you must pass the returned data to your server, where it must be passed
/// into the transaction creation call.
///
/// @return A fresh application correlation ID
// TODO: What should this be called?
- (NSString *)applicationCorrelationId;

@end


/// Specifies the destination of the PayPal app switch
typedef NS_ENUM(NSInteger, BTPayPalDriverAppSwitchTarget){
    /// Login or One Touch will take place in the PayPal app
    BTPayPalDriverAppSwitchTargetPayPalApp,
    /// Login or One Touch will take place in the browser on PayPal's website
    BTPayPalDriverAppSwitchTargetBrowser,
};

/// A delegate protocol for sending lifecycle updates as PayPal login via app switch takes place
@protocol BTPayPalDriverDelegate <NSObject>

@optional

/// Delegates receive this message when the PayPal driver is preparing to perform an app switch.
///
/// This transition is usually instantaneous; however, you may use this hook to present a loading
/// indication to the user.
///
/// @param payPalDriver The BTPayPalDriver instance performing user authentication
- (void)payPalDriverWillPerformAppSwitch:(BTPayPalDriver *)payPalDriver;

/// Delegates receive this message when the PayPal driver has successfully performed an app switch.
///
/// You may use this hook to prepare your UI for app switch return. Keep in mind that
/// users may manually switch back to your app via the iOS task manager.
///
/// @note You may also hook into the app switch lifecycle via UIApplicationWillResignActiveNotification.
///
/// @param payPalDriver The BTPayPalDriver instance performing user authentication
/// @param target       The destination that was actually used for this app switch
- (void)payPalDriver:(BTPayPalDriver *)payPalDriver didPerformAppSwitchToTarget:(BTPayPalDriverAppSwitchTarget)target;

/// Delegates receive this message when control returns to BTPayPalDriver upon app switch return
///
/// This usually gets invoked after handleAppSwitchReturnURL: is called in your UIApplicationDelegate.
///
/// @note You may also hook into the app switch lifecycle via UIApplicationWillResignActiveNotification.
///
/// @param payPalDriver The instance of BTPayPalDriver handling the app switch return.
- (void)payPalDriverWillProcessAppSwitchResult:(BTPayPalDriver *)payPalDriver;

@end

NS_ASSUME_NONNULL_END