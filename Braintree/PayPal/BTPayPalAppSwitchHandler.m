#import "BTPayPalAppSwitchHandler_Internal.h"

#import "BTClient_Internal.h"
#import "BTClient+BTPayPal.h"
#import "BTMutablePayPalPaymentMethod.h"
#import "BTLogger_Internal.h"
#import "BTErrors+BTPayPal.h"

#import "PayPalOneTouchRequest.h"
#import "PayPalOneTouchCore.h"

@implementation BTPayPalAppSwitchHandler

@synthesize returnURLScheme = _returnURLScheme;
@synthesize delegate = _delegate;

+ (instancetype)sharedHandler {
    static BTPayPalAppSwitchHandler *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[BTPayPalAppSwitchHandler alloc] init];
    });
    return instance;
}

#pragma mark BTAppSwitching

- (BOOL)canHandleReturnURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication {
    if (self.client == nil || self.delegate == nil) {
        return NO;
    }

    if (![[url.scheme lowercaseString] isEqualToString:[self.returnURLScheme lowercaseString]]) {
        return NO;
    }

    if (![PayPalOneTouchCore canParseURL:url sourceApplication:sourceApplication]) {
        return NO;
    }
    return YES;
}

- (void)handleReturnURL:(NSURL *)url {
    [PayPalOneTouchCore parseResponseURL:url
                         completionBlock:^(PayPalOneTouchCoreResult *result) {
                             BTClient *client = [self clientWithMetadataForResult:result];

                             [self postAnalyticsEventWithClient:client forHandlingOneTouchResult:result];

                             switch (result.type) {
                                 case PayPalOneTouchResultTypeError: {
                                     NSError *error = [NSError errorWithDomain:BTBraintreePayPalErrorDomain code:BTPayPalUnknownError userInfo:nil];
                                     [self informDelegateDidFailWithError:error];
                                     return;
                                 }
                                 case PayPalOneTouchResultTypeCancel:
                                     if (result.error) {
                                         [[BTLogger sharedLogger] error:@"PayPal Wallet error: %@", result.error];
                                         return;
                                     }
                                     [self informDelegateDidCancel];
                                     return;
                                 case PayPalOneTouchResultTypeSuccess:
                                     [self informDelegateWillCreatePayPalPaymentMethod];

                                     NSString *userDisplayStringFromAppSwitchResponse = result.response[@"user"][@"display_string"];
                                     [client savePaypalAccount:result.response
                                      applicationCorrelationID:[PayPalOneTouchCore clientMetadataID]
                                                       success:^(BTPayPalPaymentMethod *paypalPaymentMethod) {
                                                           [self postAnalyticsEventForTokenizationSuccessWithClient:client];

                                                           if ([userDisplayStringFromAppSwitchResponse isKindOfClass:[NSString class]]) {
                                                               if (paypalPaymentMethod.email == nil) {
                                                                   paypalPaymentMethod.email = userDisplayStringFromAppSwitchResponse;
                                                               }
                                                               if (paypalPaymentMethod.description == nil) {
                                                                   paypalPaymentMethod.description = userDisplayStringFromAppSwitchResponse;
                                                               }
                                                           }
                                                           [self informDelegateDidCreatePayPalPaymentMethod:paypalPaymentMethod];
                                                       } failure:^(NSError *error) {
                                                           [self postAnalyticsEventForTokenizationFailureWithClient:client];
                                                           [self informDelegateDidFailWithError:error];
                                                       }];

                                     break;
                             }
                         }];
}

- (BOOL)initiateAppSwitchWithClient:(BTClient *)client delegate:(id<BTAppSwitchingDelegate>)delegate error:(NSError *__autoreleasing *)error {
    client = [client copyWithMetadata:^(BTClientMutableMetadata *metadata) {
        if ([PayPalOneTouchCore isWalletAppInstalled]) {
            metadata.source = BTClientMetadataSourcePayPalApp;
        } else {
            metadata.source = BTClientMetadataSourcePayPalBrowser;
        }
    }];

    if (delegate == nil) {
        [client postAnalyticsEvent:@"ios.paypal-otc.preflight.nil-delegate"];
        if (error != NULL) {
            *error = [NSError errorWithDomain:BTAppSwitchErrorDomain
                                         code:BTAppSwitchErrorIntegrationInvalidParameters
                                     userInfo:@{ NSLocalizedDescriptionKey: @"PayPal app switch is missing a delegate." }];
        }
        return NO;
    }

    if (![self verifyAppSwitchConfigurationForClient:client postingAnalytics:YES error:error]) {
        return NO;
    }

    self.delegate = delegate;
    self.client = client;

    PayPalOneTouchAuthorizationRequest *request =
    [PayPalOneTouchAuthorizationRequest requestWithScopeValues:client.btPayPal_scopes
                                                    privacyURL:client.configuration.payPalPrivacyPolicyURL
                                                  agreementURL:client.configuration.payPalMerchantUserAgreementURL
                                                      clientID:[self payPalClientIdForClient:client]
                                                   environment:client.btPayPal_environment
                                             callbackURLScheme:[self returnURLScheme]];
    request.additionalPayloadAttributes = @{ @"client_token": client.clientToken.originalValue };

    [request performWithCompletionBlock:^(BOOL success, PayPalOneTouchRequestTarget target, NSError *error) {
        [self postAnalyticsEventWithClient:client forInitiatingOneTouchWithSuccess:success target:target];
        if (!success) {
            [self informDelegateDidFailWithError:error];
        }
    }];

    return YES;
}

- (BOOL)appSwitchAvailableForClient:(BTClient *)client {
    return [self verifyAppSwitchConfigurationForClient:client postingAnalytics:NO error:NULL];
}


#pragma mark Helpers

- (BOOL)verifyAppSwitchConfigurationForClient:(BTClient *)client postingAnalytics:(BOOL)shouldPostAnalytics error:(NSError * __autoreleasing *)error {
    if (client == nil) {
        if (error != NULL) {
            *error = [NSError errorWithDomain:BTAppSwitchErrorDomain
                                         code:BTAppSwitchErrorIntegrationInvalidParameters
                                     userInfo:@{ NSLocalizedDescriptionKey: @"PayPal app switch is missing a BTClient." }];
        }
        return NO;
    }

    if (![client btPayPal_isPayPalEnabled]){
        if (shouldPostAnalytics) {
            [client postAnalyticsEvent:@"ios.paypal-otc.preflight.disabled"];
        }
        if (error != NULL) {
            *error = [NSError errorWithDomain:BTBraintreePayPalErrorDomain
                                         code:BTPayPalErrorPayPalDisabled
                                     userInfo:@{NSLocalizedDescriptionKey: @"PayPal is not enabled for this merchant."}];
        }
        return NO;
    }

    if (self.returnURLScheme == nil) {
        if (shouldPostAnalytics) {
            [client postAnalyticsEvent:@"ios.paypal-otc.preflight.nil-return-url-scheme"];
        }
        if (error != NULL) {
            *error = [NSError errorWithDomain:BTAppSwitchErrorDomain
                                         code:BTAppSwitchErrorIntegrationReturnURLScheme
                                     userInfo:@{ NSLocalizedDescriptionKey: @"PayPal app switch is missing a returnURLScheme. See +[Braintree setReturnURLScheme:]." }];
        }
        return NO;
    }

    if (![PayPalOneTouchCore doesApplicationSupportOneTouchCallbackURLScheme:self.returnURLScheme]) {
        if (shouldPostAnalytics) {
            [client postAnalyticsEvent:@"ios.paypal-otc.preflight.invalid-return-url-scheme"];
        }
        if (error != NULL) {
            NSString *errorMessage = [NSString stringWithFormat:@"Can not app switch to PayPal. Verify that the return URL scheme (%@) starts with this app's bundle id, and that the PayPal app is installed.", self.returnURLScheme];
            return [NSError errorWithDomain:BTAppSwitchErrorDomain
                                       code:BTAppSwitchErrorIntegrationReturnURLScheme
                                   userInfo:@{ NSLocalizedDescriptionKey: errorMessage }];
        }
        return NO;
    }

    return YES;
}

- (NSString *)payPalClientIdForClient:(BTClient *)client {
    NSString *payPalClientId = client.configuration.payPalClientId;
    if (payPalClientId != nil) {
        return payPalClientId;
    } else if ([client.btPayPal_environment isEqualToString:PayPalEnvironmentMock]) {
        return @"mock-paypal-client-id";
    } else {
        return nil;
    }
}

- (BTClient *)clientWithMetadataForResult:(PayPalOneTouchCoreResult *)result {
    return [self.client copyWithMetadata:^(BTClientMutableMetadata *metadata) {
        switch (result.target) {
            case PayPalOneTouchRequestTargetNone:
            case PayPalOneTouchRequestTargetUnknown:
                metadata.source = BTClientMetadataSourceUnknown;
                break;
            case PayPalOneTouchRequestTargetBrowser:
                metadata.source = BTClientMetadataSourcePayPalBrowser;
                break;
            case PayPalOneTouchRequestTargetOnDeviceApplication:
                metadata.source = BTClientMetadataSourcePayPalBrowser;
                break;
        }
    }];
}


#pragma mark Analytics Helpers

- (void)postAnalyticsEventWithClient:(BTClient *)client forInitiatingOneTouchWithSuccess:(BOOL)success target:(PayPalOneTouchRequestTarget)target {
    if (success) {
        switch (target) {
            case PayPalOneTouchRequestTargetNone:
                return [client postAnalyticsEvent:@"ios.paypal-otc.none.initiate.started"];
            case PayPalOneTouchRequestTargetUnknown:
                return [client postAnalyticsEvent:@"ios.paypal-otc.unknown.initiate.started"];
            case PayPalOneTouchRequestTargetOnDeviceApplication:
                return [client postAnalyticsEvent:@"ios.paypal-otc.appswitch.initiate.started"];
            case PayPalOneTouchRequestTargetBrowser:
                return [client postAnalyticsEvent:@"ios.paypal-otc.webswitch.initiate.started"];
        }
    } else {
        switch (target) {
            case PayPalOneTouchRequestTargetNone:
                return [client postAnalyticsEvent:@"ios.paypal-otc.none.initiate.failed"];
            case PayPalOneTouchRequestTargetUnknown:
                return [client postAnalyticsEvent:@"ios.paypal-otc.unknown.initiate.failed"];
            case PayPalOneTouchRequestTargetOnDeviceApplication:
                return [client postAnalyticsEvent:@"ios.paypal-otc.appswitch.initiate.failed"];
            case PayPalOneTouchRequestTargetBrowser:
                return [client postAnalyticsEvent:@"ios.paypal-otc.webswitch.initiate.failed"];
        }
    }
}

- (void)postAnalyticsEventWithClient:(BTClient *)client forHandlingOneTouchResult:(PayPalOneTouchCoreResult *)result {
    switch (result.type) {
        case PayPalOneTouchResultTypeError:
            switch (result.target) {
                case PayPalOneTouchRequestTargetNone:
                case PayPalOneTouchRequestTargetUnknown:
                    return [client postAnalyticsEvent:@"ios.paypal-otc.unknown.failed"];
                case PayPalOneTouchRequestTargetOnDeviceApplication:
                    return [client postAnalyticsEvent:@"ios.paypal-otc.appswitch.failed"];
                case PayPalOneTouchRequestTargetBrowser:
                    return [client postAnalyticsEvent:@"ios.paypal-otc.webswitch.failed"];
            }
        case PayPalOneTouchResultTypeCancel:
            if (result.error) {
                switch (result.target) {
                    case PayPalOneTouchRequestTargetNone:
                    case PayPalOneTouchRequestTargetUnknown:
                        return [client postAnalyticsEvent:@"ios.paypal-otc.unknown.canceled-with-error"];
                    case PayPalOneTouchRequestTargetOnDeviceApplication:
                        return [client postAnalyticsEvent:@"ios.paypal-otc.appswitch.canceled-with-error"];
                    case PayPalOneTouchRequestTargetBrowser:
                        return [client postAnalyticsEvent:@"ios.paypal-otc.webswitch.canceled-with-error"];
                }
            } else {
                switch (result.target) {
                    case PayPalOneTouchRequestTargetNone:
                    case PayPalOneTouchRequestTargetUnknown:
                        return [client postAnalyticsEvent:@"ios.paypal-otc.unknown.canceled"];
                    case PayPalOneTouchRequestTargetOnDeviceApplication:
                        return [client postAnalyticsEvent:@"ios.paypal-otc.appswitch.canceled"];
                    case PayPalOneTouchRequestTargetBrowser:
                        return [client postAnalyticsEvent:@"ios.paypal-otc.webswitch.canceled"];
                }
            }
        case PayPalOneTouchResultTypeSuccess:
            switch (result.target) {
                case PayPalOneTouchRequestTargetNone:
                case PayPalOneTouchRequestTargetUnknown:
                    return [client postAnalyticsEvent:@"ios.paypal-otc.unknown.succeeded"];
                case PayPalOneTouchRequestTargetOnDeviceApplication:
                    return [client postAnalyticsEvent:@"ios.paypal-otc.appswitch.succeeded"];
                case PayPalOneTouchRequestTargetBrowser:
                    return [client postAnalyticsEvent:@"ios.paypal-otc.webswitch.succeeded"];
            }
    }
}

- (void)postAnalyticsEventForTokenizationSuccessWithClient:(BTClient *)client {
    return [client postAnalyticsEvent:@"ios.paypal-otc.tokenize.succeeded"];
}

- (void)postAnalyticsEventForTokenizationFailureWithClient:(BTClient *)client {
    return [client postAnalyticsEvent:@"ios.paypal-otc.tokenize.failed"];
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
