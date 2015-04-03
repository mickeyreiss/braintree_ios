#import "BTPayPalAppSwitchHandler_Internal.h"

#import "BTClient_Internal.h"
#import "BTClient+BTPayPal.h"
#import "BTMutablePayPalPaymentMethod.h"
#import "BTLogger_Internal.h"
#import "BTErrors+BTPayPal.h"

#import "PayPalOneTouchRequest.h"
#import "PayPalOneTouchCore.h"

@implementation BTPayPalAppSwitchHandler

@synthesize returnURLScheme;
@synthesize delegate;

+ (instancetype)sharedHandler {
    static BTPayPalAppSwitchHandler *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[BTPayPalAppSwitchHandler alloc] init];
    });
    return instance;
}

- (BOOL)canHandleReturnURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication {
    if (self.client == nil || self.delegate == nil) {
        [self.client postAnalyticsEvent:@"ios.paypal.appswitch.can-handle.invalid"];
        return NO;
    }

    if (![url.scheme isEqualToString:self.returnURLScheme]) {
        [self.client postAnalyticsEvent:@"ios.paypal.appswitch.can-handle.different-scheme"];
        return NO;
    }

    if (![PayPalOneTouchCore canParseURL:url sourceApplication:sourceApplication]) {
        [self.client postAnalyticsEvent:@"ios.paypal.appswitch.can-handle.paypal-cannot-handle"];
        return NO;
    }
    return YES;
}

- (void)handleReturnURL:(NSURL *)url {
    [PayPalOneTouchCore parseResponseURL:url completionBlock:^(PayPalOneTouchCoreResult *result) {
        switch (result.type) {
            case PayPalOneTouchResultTypeError: {
                // TODO: switch analytics based on appswitch vs. browser switch
                [self.client postAnalyticsEvent:@"ios.paypal.appswitch.handle.error"];
                NSError *error = [NSError errorWithDomain:BTBraintreePayPalErrorDomain code:BTPayPalUnknownError userInfo:nil];
                [self informDelegateDidFailWithError:error];
                return;
            }
            case PayPalOneTouchResultTypeCancel:
                // TODO: switch analytics based on appswitch vs. browser switch
                [self.client postAnalyticsEvent:@"ios.paypal.appswitch.handle.cancel"];
                if (result.error) {
                    [self.client postAnalyticsEvent:@"ios.paypal.appswitch.handle.cancel-error"];
                    [[BTLogger sharedLogger] error:@"PayPal Wallet error: %@", result.error];
                    return;
                }
                [self informDelegateDidCancel];
                return;
            case PayPalOneTouchResultTypeSuccess:
//                if (!code) {
//                    NSError *error = [NSError errorWithDomain:BTBraintreePayPalErrorDomain code:BTPayPalUnknownError userInfo:@{NSLocalizedDescriptionKey: @"Auth code not found in PayPal Touch app switch response" }];
//                    [self.client postAnalyticsEvent:@"ios.paypal.appswitch.handle.code-error"];
//                    [self informDelegateDidFailWithError:error];
//                    return;
//                }
// TODO: Will we ever receive PayPalOneTouchResultTypeSuccess without a code?

                // TODO: switch analytics based on appswitch vs. browser switch
                [self.client postAnalyticsEvent:@"ios.paypal.appswitch.handle.authorized"];
                
                [self informDelegateWillCreatePayPalPaymentMethod];

                // TODO: is the application correlation id included in the initial response?
                [self.client savePaypalAccount:result.response
                                       success:^(BTPayPalPaymentMethod *paypalPaymentMethod) {
                                           // TODO: How do I obtain the user display string?
                                           NSString *userDisplayStringFromAppSwitchResponse = result.response[@"user"][@"display_string"];
                                           if (paypalPaymentMethod.email == nil && [userDisplayStringFromAppSwitchResponse isKindOfClass:[NSString class]]) {
                                               BTMutablePayPalPaymentMethod *mutablePayPalPaymentMethod = [paypalPaymentMethod mutableCopy];
                                               mutablePayPalPaymentMethod.email = userDisplayStringFromAppSwitchResponse;
                                               paypalPaymentMethod = mutablePayPalPaymentMethod;
                                           }
                                           [self.client postAnalyticsEvent:@"ios.paypal.appswitch.handle.success"];
                                           [self informDelegateDidCreatePayPalPaymentMethod:paypalPaymentMethod];
                                       } failure:^(NSError *error) {
                                           [self.client postAnalyticsEvent:@"ios.paypal.appswitch.handle.client-failure"];
                                           [self informDelegateDidFailWithError:error];
                                       }];
                
                break;
        }
    }];
}

- (BOOL)initiateAppSwitchWithClient:(BTClient *)client delegate:(id<BTAppSwitchingDelegate>)theDelegate error:(NSError *__autoreleasing *)error {
    client = [client copyWithMetadata:^(BTClientMutableMetadata *metadata) {
        metadata.source = BTClientMetadataSourcePayPalApp;
    }];

    NSError *appSwitchError = [self appSwitchErrorForClient:client delegate:theDelegate];
    if (appSwitchError) {
        BOOL analyticsEventPosted = NO;
        if ([appSwitchError.domain isEqualToString:BTAppSwitchErrorDomain]) {
            analyticsEventPosted = YES;
            switch (appSwitchError.code) {
                case BTAppSwitchErrorDisabled:
                    [client postAnalyticsEvent:@"ios.paypal.appswitch.initiate.error.app-switch-disabled"];
                    break;
                case BTAppSwitchErrorAppNotAvailable:
                    [client postAnalyticsEvent:@"ios.paypal.appswitch.initiate.error.unavailable"];
                    break;
                case BTAppSwitchErrorIntegrationReturnURLScheme:
                    [client postAnalyticsEvent:@"ios.paypal.appswitch.initiate.error.invalid.return-url-scheme"];
                    break;
                case BTAppSwitchErrorIntegrationInvalidParameters:
                    [client postAnalyticsEvent:@"ios.paypal.appswitch.initiate.error.invalid.parameters"];
                    break;
                default:
                    analyticsEventPosted = NO;
                    break;
            }
        } else if ([appSwitchError.domain isEqualToString:BTBraintreePayPalErrorDomain] && appSwitchError.code == BTPayPalErrorPayPalDisabled) {
            [client postAnalyticsEvent:@"ios.paypal.appswitch.initiate.error.disabled"];
            analyticsEventPosted = YES;
        }
        if (!analyticsEventPosted) {
            [client postAnalyticsEvent:@"ios.paypal.appswitch.initiate.error.unrecognized-error"];
        }
        if (error) {
            *error = appSwitchError;
        }
        return NO;
    }

    self.delegate = theDelegate;
    self.client = client;

    NSString *clientId;
    if ([self.client.btPayPal_environment isEqualToString:PayPalEnvironmentMock] && client.configuration.payPalClientId == nil) {
        clientId = @"mock-paypal-client-id";
    } else {
        clientId = client.configuration.payPalClientId;
    }

    PayPalOneTouchAuthorizationRequest *request =
    [PayPalOneTouchAuthorizationRequest requestWithScopeValues:client.btPayPal_scopes
                                                    privacyURL:client.configuration.payPalPrivacyPolicyURL
                                                  agreementURL:client.configuration.payPalMerchantUserAgreementURL
                                                      clientID:clientId
                                                   environment:client.btPayPal_environment
                                             callbackURLScheme:[self returnURLScheme]];
    request.additionalPayloadAttributes = @{ @"client_token": client.clientToken.originalValue };

    [request performWithCompletionBlock:^(BOOL success, __unused PayPalOneTouchRequestTarget target, NSError *error) {
        if (success) {
            // TODO: Switch analytics based on target
            [self.client postAnalyticsEvent:@"ios.paypal.appswitch.initiate.success"];
        } else {
            // TODO: Switch analytics based on target
            [self.client postAnalyticsEvent:@"ios.paypal.appswitch.initiate.error.failed"];
            [self informDelegateDidFailWithError:error];
        }
    }];

    return YES;
}

- (BOOL)appSwitchAvailableForClient:(BTClient *)client {
    return [self appSwitchErrorForClient:client] == nil;
}

- (NSError *)appSwitchErrorForClient:(BTClient *)client delegate:(id<BTAppSwitchingDelegate>)theDelegate {
    if (theDelegate == nil) {
        return [NSError errorWithDomain:BTAppSwitchErrorDomain
                                   code:BTAppSwitchErrorIntegrationInvalidParameters
                               userInfo:@{ NSLocalizedDescriptionKey: @"PayPal app switch is missing a delegate." }];
    }
    return [self appSwitchErrorForClient:client];
}

- (NSError *)appSwitchErrorForClient:(BTClient *)client {
    if (client == nil) {
        return [NSError errorWithDomain:BTAppSwitchErrorDomain
                                   code:BTAppSwitchErrorIntegrationInvalidParameters
                               userInfo:@{ NSLocalizedDescriptionKey: @"PayPal app switch is missing a BTClient." }];
    }

    if (![client btPayPal_isPayPalEnabled]){
        return [NSError errorWithDomain:BTBraintreePayPalErrorDomain
                                   code:BTPayPalErrorPayPalDisabled
                               userInfo:@{NSLocalizedDescriptionKey: @"PayPal is not enabled for this merchant."}];
    }

    if (self.returnURLScheme == nil) {
        return [NSError errorWithDomain:BTAppSwitchErrorDomain
                                   code:BTAppSwitchErrorIntegrationReturnURLScheme
                               userInfo:@{ NSLocalizedDescriptionKey: @"PayPal app switch is missing a returnURLScheme. See +[Braintree setReturnURLScheme:]." }];
    }

    if (![PayPalOneTouchCore doesApplicationSupportOneTouchCallbackURLScheme:self.returnURLScheme]) {
        NSString *errorMessage = [NSString stringWithFormat:@"Can not app switch to PayPal. Verify that the return URL scheme (%@) starts with this app's bundle id, and that the PayPal app is installed.", self.returnURLScheme];
        return [NSError errorWithDomain:BTAppSwitchErrorDomain
                                   code:BTAppSwitchErrorAppNotAvailable
                               userInfo:@{ NSLocalizedDescriptionKey: errorMessage }];
    }


    return nil;
}


#pragma mark Delegate Method Invocations

- (void)informDelegateWillCreatePayPalPaymentMethod {
    if ([self.delegate respondsToSelector:@selector(appSwitcherWillCreatePaymentMethod:)]) {
        [self.delegate appSwitcherWillCreatePaymentMethod:self];
    }
}

- (void)informDelegateDidCreatePayPalPaymentMethod:(BTPaymentMethod *)paymentMethod {
    [self.delegate appSwitcher:self didCreatePaymentMethod:paymentMethod];
}

- (void)informDelegateDidFailWithError:(NSError *)error {
    [self.delegate appSwitcher:self didFailWithError:error];
}

- (void)informDelegateDidFailWithErrorCode:(NSInteger)code localizedDescription:(NSString *)localizedDescription {
    NSError *error = [NSError errorWithDomain:BTBraintreePayPalErrorDomain
                                         code:code
                                     userInfo:@{ NSLocalizedDescriptionKey:localizedDescription }];
    [self informDelegateDidFailWithError:error];
}

- (void)informDelegateDidCancel {
    [self.delegate appSwitcherDidCancel:self];
}

@end
