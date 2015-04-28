#import "BTPayPalDriver.h"

#import "PayPalOneTouchRequest.h"
#import "PayPalOneTouchCore.h"

#import "BTPayPalPaymentMethod_Mutable.h"
#import "BTClient_Internal.h"
#import "BTLogger_Internal.h"

#import "BTAppSwitchErrors.h"
#import "BTErrors+BTPayPal.h"

static void (^BTPayPalHandleURLContinuation)(NSURL *url);

NS_ASSUME_NONNULL_BEGIN

@interface BTPayPalDriver ()
@property (nonatomic, strong) BTClient *client;
@property (nonatomic, copy) NSString *returnURLScheme;
@end

@implementation BTPayPalDriver

- (nullable instancetype)initWithClient:(BTClient * __nonnull)client returnURLScheme:(NSString * __nonnull)returnURLScheme {
    NSError *initializationError;
    if (![BTPayPalDriver verifyAppSwitchConfigurationForClient:client
                                               returnURLScheme:returnURLScheme
                                                         error:&initializationError]) {
        [[BTLogger sharedLogger] log:@"Failed to initialize BTPayPalDriver: %@", initializationError];
        return nil;
    }

    self = [super init];
    if (self) {
        self.client = client;
        self.returnURLScheme = returnURLScheme;
    }
    return self;
}

#pragma mark - PayPal Lifecycle

- (void)startAuthorizationWithCompletion:(nullable void (^)(BTPayPalPaymentMethod * __nullable, NSError * __nullable))completionBlock {
    BTClient *client = [self.client copyWithMetadata:^(BTClientMutableMetadata *metadata) {
        if ([PayPalOneTouchCore isWalletAppInstalled]) {
            metadata.source = BTClientMetadataSourcePayPalApp;
        } else {
            metadata.source = BTClientMetadataSourcePayPalBrowser;
        }
    }];

    NSError *error;
    if (![BTPayPalDriver verifyAppSwitchConfigurationForClient:client returnURLScheme:self.returnURLScheme error:&error]) {
        if (completionBlock) {
            completionBlock(nil, error);
        }
        return;
    }

    BTPayPalHandleURLContinuation = ^(NSURL *url){
        [self informDelegateWillProcessAppSwitchResult];

        [PayPalOneTouchCore parseResponseURL:url
                             completionBlock:^(PayPalOneTouchCoreResult *result) {
                                 BTClient *client = [self clientWithMetadataForResult:result];

                                 [self postAnalyticsEventWithClient:client forHandlingOneTouchResult:result];

                                 switch (result.type) {
                                     case PayPalOneTouchResultTypeError:
                                         if (completionBlock) {
                                             completionBlock(nil, result.error);
                                         }
                                         break;
                                     case PayPalOneTouchResultTypeCancel:
                                         if (result.error) {
                                             [[BTLogger sharedLogger] error:@"PayPal Wallet error: %@", result.error];
                                             return;
                                         }
                                         if (completionBlock) {
                                             completionBlock(nil, nil);
                                         }
                                         break;
                                     case PayPalOneTouchResultTypeSuccess: {
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
                                                               if (completionBlock) {
                                                                   completionBlock(paypalPaymentMethod, nil);
                                                               }
                                                           } failure:^(NSError *error) {
                                                               [self postAnalyticsEventForTokenizationFailureWithClient:client];
                                                               if (completionBlock) {
                                                                   completionBlock(nil, error);
                                                               }
                                                           }];

                                     }
                                         break;
                                 }
                                 BTPayPalHandleURLContinuation = nil;
                             }];
    };

    PayPalOneTouchAuthorizationRequest *request =
    [PayPalOneTouchAuthorizationRequest requestWithScopeValues:self.OAuth2Scopes
                                                    privacyURL:client.configuration.payPalPrivacyPolicyURL
                                                  agreementURL:client.configuration.payPalMerchantUserAgreementURL
                                                      clientID:[self paypalClientIdForClient:client]
                                                   environment:[self payPalEnvironmentForClient:client]
                                             callbackURLScheme:[self returnURLScheme]];
    request.additionalPayloadAttributes = @{ @"client_token": client.clientToken.originalValue };

    [self informDelegateWillPerformAppSwitch];
    [request performWithCompletionBlock:^(BOOL success, PayPalOneTouchRequestTarget target, NSError *error) {
        [self postAnalyticsEventWithClient:client forInitiatingOneTouchWithSuccess:success target:target];
        if (success) {
            [self informDelegateDidPerformAppSwitchToTarget:target];
        } else {
            if (completionBlock) {
                completionBlock(nil, error);
            }
        }
    }];
}

- (void)startCheckout:(__unused BTPayPalCheckout * __nonnull)checkout completion:(nullable __unused void (^)(BTPayPalPaymentMethod * __nullable paymentMethod, NSError * __nullable error))completionBlock {
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:@"Checkout is not yet implemented 😩."
                                 userInfo:nil];
}

+ (BOOL)canHandleAppSwitchReturnURL:(NSURL * __nonnull)url sourceApplication:(NSString * __nonnull)sourceApplication {
    return BTPayPalHandleURLContinuation != nil && [PayPalOneTouchCore canParseURL:url sourceApplication:sourceApplication];
}

+ (void)handleAppSwitchReturnURL:(NSURL * __nonnull)url {
    if (BTPayPalHandleURLContinuation) {
        BTPayPalHandleURLContinuation(url);
    }
}


#pragma mark - Delegate Informers

- (void)informDelegateWillPerformAppSwitch {
    if ([self.delegate respondsToSelector:@selector(payPalDriverWillPerformAppSwitch:)]) {
        [self.delegate payPalDriverWillPerformAppSwitch:self];
    }
}

- (void)informDelegateDidPerformAppSwitchToTarget:(PayPalOneTouchRequestTarget)target {
    if ([self.delegate respondsToSelector:@selector(payPalDriver:didPerformAppSwitchToTarget:)]) {
        switch (target) {
            case PayPalOneTouchRequestTargetBrowser:
                [self.delegate payPalDriver:self didPerformAppSwitchToTarget:BTPayPalDriverAppSwitchTargetBrowser];
                break;
            case PayPalOneTouchRequestTargetOnDeviceApplication:
                [self.delegate payPalDriver:self didPerformAppSwitchToTarget:BTPayPalDriverAppSwitchTargetPayPalApp];
                break;
            default:
                // Should never happen.
                break;
        }
    }

}

- (void)informDelegateWillProcessAppSwitchResult {
    if ([self.delegate respondsToSelector:@selector(payPalDriverWillProcessAppSwitchResult:)]) {
        [self.delegate payPalDriverWillProcessAppSwitchResult:self];
    }
}


#pragma mark -

+ (BOOL)verifyAppSwitchConfigurationForClient:(BTClient *)client returnURLScheme:(NSString *)returnURLScheme error:(NSError * __autoreleasing *)error {
    if (client == nil) {
        if (error != NULL) {
            *error = [NSError errorWithDomain:BTAppSwitchErrorDomain
                                         code:BTAppSwitchErrorIntegrationInvalidParameters
                                     userInfo:@{ NSLocalizedDescriptionKey: @"PayPal app switch is missing a BTClient." }];
        }
        return NO;
    }

    if (!client.configuration.payPalEnabled) {
        [client postAnalyticsEvent:@"ios.paypal-otc.preflight.disabled"];
        if (error != NULL) {
            *error = [NSError errorWithDomain:BTBraintreePayPalErrorDomain
                                         code:BTPayPalErrorPayPalDisabled
                                     userInfo:@{ NSLocalizedDescriptionKey: @"PayPal is not enabled for this merchant." }];
        }
        return NO;
    }

    if (returnURLScheme == nil) {
        [client postAnalyticsEvent:@"ios.paypal-otc.preflight.nil-return-url-scheme"];
        if (error != NULL) {
            *error = [NSError errorWithDomain:BTAppSwitchErrorDomain
                                         code:BTAppSwitchErrorIntegrationReturnURLScheme
                                     userInfo:@{ NSLocalizedDescriptionKey: @"PayPal app switch is missing a returnURLScheme. See +[Braintree setReturnURLScheme:]." }];
        }
        return NO;
    }

    if (![PayPalOneTouchCore doesApplicationSupportOneTouchCallbackURLScheme:returnURLScheme]) {
        [client postAnalyticsEvent:@"ios.paypal-otc.preflight.invalid-return-url-scheme"];
        if (error != NULL) {
            NSString *errorMessage = [NSString stringWithFormat:@"Cannot app switch to PayPal. Verify that the return URL scheme (%@) starts with this app's bundle id, and that the PayPal app is installed.", returnURLScheme];
            *error = [NSError errorWithDomain:BTAppSwitchErrorDomain
                                         code:BTAppSwitchErrorIntegrationReturnURLScheme
                                     userInfo:@{ NSLocalizedDescriptionKey: errorMessage }];
        }
        return NO;
    }

    return YES;
}

- (NSString *)payPalEnvironmentForClient:(BTClient *)client {
    NSString *btPayPalEnvironmentName = client.configuration.payPalEnvironment;
    if ([btPayPalEnvironmentName isEqualToString:@"offline"]) {
        return @"mock";
    } else {
        return btPayPalEnvironmentName;
    }
}

- (NSString *)paypalClientIdForClient:(BTClient *)client {
    if ([client.configuration.payPalEnvironment isEqualToString:@"offline"] && client.configuration.payPalClientId == nil) {
        return @"mock-paypal-client-id";
    } else {
        return client.configuration.payPalClientId;
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

- (NSSet *)OAuth2Scopes {
    return [NSSet setWithObjects:@"https://uri.paypal.com/services/payments/futurepayments", @"email", nil];
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

@end

NS_ASSUME_NONNULL_END
