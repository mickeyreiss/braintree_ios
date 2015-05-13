//
//  PayPalOneTouchRequest.h
//
//  Version 1.0.3
//
//  Copyright (c) 2015 PayPal Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PayPalOneTouchCoreResult.h"

/// Completion block for receiving the result of performing a request
typedef void (^PayPalOneTouchRequestCompletionBlock) (BOOL success, PayPalOneTouchRequestTarget target, NSError *error);

/// This environment MUST be used for App Store submissions.
extern NSString *const PayPalEnvironmentProduction;
/// Sandbox: Uses the PayPal sandbox for transactions. Useful for development.
extern NSString *const PayPalEnvironmentSandbox;
/// Mock: Mock mode. Does not submit transactions to PayPal. Fakes successful responses. Useful for unit tests.
extern NSString *const PayPalEnvironmentMock;

/// Base class for all OneTouch requests
@interface PayPalOneTouchRequest : NSObject

/// Ask the OneTouch library to carry out a request.
/// Will app-switch to the PayPal mobile Wallet app if present, or to web browser otherwise.
///
/// @param request The PayPalOneTouchAuthorizationRequest, PayPalOneTouchCheckoutRequest, or other subclass object
/// @param completionBlock Block that is called when the request has finished initiating
///        (i.e., app-switch has occurred or an error was encountered).
///
/// @note As currently implemented, the appropriate app-switch (to Wallet, browser, or neither) will
///       happen immediately, followed in turn by an immediate call of the completionBlock.
///       We use a completion block here to allow for future changes in implementation that might cause
///       delays (such as time-consuming cryptographic operations, or server interactions).
- (void)performWithCompletionBlock:(PayPalOneTouchRequestCompletionBlock)completionBlock;

/// All requests MUST include the app's Client ID, as obtained from developer.paypal.com
@property (nonatomic, readonly) NSString *clientID;

/// All requests MUST indicate the environment - `live`, `mock`, or `sandbox`; or else a stage indicated as `base-url:port`
@property (nonatomic, readonly) NSString *environment;

/// All requests MUST indicate the URL scheme to be used for returning to this app, following an app-switch
@property (nonatomic, readonly) NSString *callbackURLScheme;

/// Requests MAY include additional key/value pairs that OTC will add to the payload
/// (For example, the Braintree client_token, which is required by the
///  temporary Braintree Future Payments consent webpage.)
@property (nonatomic, strong) NSDictionary *additionalPayloadAttributes;

@end


/// Request consent for Profile Sharing (e.g., for Future Payments)
@interface PayPalOneTouchAuthorizationRequest : PayPalOneTouchRequest

/// Factory method. Non-empty values for all parameters MUST be provided.
///
/// @param scopeValues Set of requested scope-values.
///        Available scope-values are listed at https://developer.paypal.com/webapps/developer/docs/integration/direct/identity/attributes/
/// @param privacyURL The URL of the merchant's privacy policy
/// @param agreementURL The URL of the merchant's user agreement
/// @param clientID The app's Client ID, as obtained from developer.paypal.com
/// @param environment `live`, `mock`, or `sandbox`; or else a stage indicated as `base-url:port`
/// @param callbackURLScheme The URL scheme to be used for returning to this app, following an app-switch
+ (instancetype)requestWithScopeValues:(NSSet *)scopeValues
                            privacyURL:(NSURL *)privacyURL
                          agreementURL:(NSURL *)agreementURL
                              clientID:(NSString *)clientID
                           environment:(NSString *)environment
                     callbackURLScheme:(NSString *)callbackURLScheme;

/// Set of requested scope-values.
/// Available scope-values are listed at https://developer.paypal.com/webapps/developer/docs/integration/direct/identity/attributes/
@property (nonatomic, readonly) NSSet *scopeValues;

/// The URL of the merchant's privacy policy
@property (nonatomic, readonly) NSURL *privacyURL;

/// The URL of the merchant's user agreement
@property (nonatomic, readonly) NSURL *agreementURL;

@end


/// Request approval of a payment
@interface PayPalOneTouchCheckoutRequest : PayPalOneTouchRequest

/// Factory method. Non-empty values for all parameters MUST be provided.
///
/// @param approvalURL Client has already created a payment on PayPal server; this is the resulting HATEOS ApprovalURL
/// @param clientID The app's Client ID, as obtained from developer.paypal.com
/// @param environment `live`, `mock`, or `sandbox`; or else a stage indicated as `base-url:port`
/// @param callbackURLScheme The URL scheme to be used for returning to this app, following an app-switch
+ (instancetype)requestWithApprovalURL:(NSURL *)approvalURL
                              clientID:(NSString *)clientID
                           environment:(NSString *)environment
                     callbackURLScheme:(NSString *)callbackURLScheme;

/// Client has already created a payment on PayPal server; this is the resulting HATEOS ApprovalURL
@property (nonatomic, readonly) NSURL *approvalURL;

@end

