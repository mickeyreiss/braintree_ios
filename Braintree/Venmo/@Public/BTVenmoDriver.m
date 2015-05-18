#import "BTVenmoDriver.h"
#import "BTVenmoAppSwitchHandler_Internal.h"
#import "BTVenmoAppSwitchRequestURL.h"
#import "BTVenmoAppSwitchReturnURL.h"
#import "BTClient+BTVenmo.h"
#import "BTClient_Internal.h"
#import "BTMutableCardPaymentMethod.h"

static void (^BTVenmoHandleURLContinuation)(NSURL *url);

@interface BTVenmoDriver ()
@property (nonatomic, strong) BTClient *client;
@property (nonatomic, copy) NSString *returnURLScheme;
@end

@implementation BTVenmoDriver

- (instancetype)initWithClient:(BTClient *)client returnURLScheme:(NSString *)returnURLScheme {
    self = [super init];
    if (self) {
        self.client = client;
        self.returnURLScheme = returnURLScheme;
    }
    return self;
}

- (void)setClient:(BTClient *)client {
    client = [client copyWithMetadata:^(BTClientMutableMetadata *metadata) {
        metadata.source = BTClientMetadataSourceVenmoApp;
    }];
}

- (void)startAuthorizationWithCompletion:(void (^)(BTCardPaymentMethod *__nullable paymentMethod, NSError *__nullable error))completionBlock {
    NSError *appSwitchError = [self appSwitchErrorForClient:self.client];
    if (appSwitchError) {
        if ([appSwitchError.domain isEqualToString:BTAppSwitchErrorDomain]) {
            switch (appSwitchError.code) {
                case BTAppSwitchErrorDisabled:
                    [self.client postAnalyticsEvent:@"ios.venmo.appswitch.initiate.error.disabled"];
                    break;
                case BTAppSwitchErrorIntegrationReturnURLScheme:
                    [self.client postAnalyticsEvent:@"ios.venmo.appswitch.initiate.error.invalid.return-url-scheme"];
                    break;
                case BTAppSwitchErrorIntegrationMerchantId:
                    [self.client postAnalyticsEvent:@"ios.venmo.appswitch.initiate.error.invalid.merchant-id"];
                    break;
                case BTAppSwitchErrorAppNotAvailable:
                    [self.client postAnalyticsEvent:@"ios.venmo.appswitch.initiate.error.unavailable"];
                    break;
                default:
                    [self.client postAnalyticsEvent:@"ios.venmo.appswitch.initiate.error.unrecognized-error"];
                    break;
            }
        }
        if (appSwitchError != nil) {
            if (completionBlock) {
                completionBlock(nil, appSwitchError);
            }
            return;
        }
    }

    BOOL offline = (self.client.configuration.venmoStatus == BTConfigurationVenmoStatusOff);

    NSError *venmoAppSwitchError;
    NSURL *venmoAppSwitchURL = [BTVenmoAppSwitchRequestURL appSwitchURLForMerchantID:self.client.configuration.merchantId
                                                                     returnURLScheme:self.returnURLScheme
                                                                             offline:offline
                                                                               error:&venmoAppSwitchError];
    if (venmoAppSwitchError != nil) {
        if (completionBlock) {
            completionBlock(nil, venmoAppSwitchError);
        }
        return;
    }

    BOOL success = [[UIApplication sharedApplication] openURL:venmoAppSwitchURL];
    if (success) {
        [self.client postAnalyticsEvent:@"ios.venmo.appswitch.initiate.success"];
        [self informDelegateDidPerformAppSwitch];
    } else {
        [self.client postAnalyticsEvent:@"ios.venmo.appswitch.initiate.error.failure"];
        if (completionBlock) {
            NSError *openURLError = [NSError errorWithDomain:BTAppSwitchErrorDomain
                                                        code:BTAppSwitchErrorFailed
                                                    userInfo:@{NSLocalizedDescriptionKey: @"UIApplication failed to perform app switch to Venmo."}];
            completionBlock(nil, openURLError);
        }
        return;
    }

    BTVenmoHandleURLContinuation = ^(NSURL *url) {
        [self informDelegateWillProcessAppSwitchResult];
        BTVenmoAppSwitchReturnURL *returnURL = [[BTVenmoAppSwitchReturnURL alloc] initWithURL:url];
        switch (returnURL.state) {
            case BTVenmoAppSwitchReturnURLStateSucceeded: {
                [self.client postAnalyticsEvent:@"ios.venmo.appswitch.handle.authorized"];

                switch (self.client.configuration.venmoStatus) {
                    case BTConfigurationVenmoStatusOffline:
                        /* FALLTHROUGH */
                        [self.client postAnalyticsEvent:@"ios.venmo.appswitch.handle.offline"];
                    case BTConfigurationVenmoStatusProduction: {
                        [self.client fetchPaymentMethodWithNonce:returnURL.paymentMethod.nonce
                                                         success:^(BTPaymentMethod *paymentMethod) {
                                                             [self.client postAnalyticsEvent:@"ios.venmo.appswitch.handle.success"];
                                                             if (completionBlock) {
                                                                 completionBlock(paymentMethod, nil)
                                                             }
                                                         }
                                                         failure:^(NSError *error) {
                                                             [self.client postAnalyticsEvent:@"ios.venmo.appswitch.handle.client-failure"];
                                                             NSError *venmoError = [NSError errorWithDomain:BTAppSwitchErrorDomain
                                                                                                       code:BTAppSwitchErrorFailureFetchingPaymentMethod
                                                                                                   userInfo:@{NSLocalizedDescriptionKey : @"Failed to fetch payment method",
                                                                                                           NSUnderlyingErrorKey : error}];
                                                             [self informDelegateDidFailWithError:venmoError];
                                                             if (completionBlock) {
                                                                 completionBlock(paymentMethod, nil);
                                                             }
                                                         }];
                        break;
                    }
                    case BTVenmoStatusOff: {
                        NSError *cancelationError = [NSError errorWithDomain:BTAppSwitchErrorDomain
                                                             code:BTAppSwitchErrorDisabled
                                                         userInfo:@{ NSLocalizedDescriptionKey: @"Received a Venmo app switch return while Venmo is disabled" }];
                        [self.client postAnalyticsEvent:@"ios.venmo.appswitch.handle.off"];
                        if (completionBlock) {
                            completionBlock(nil, cancelationError);
                        }
                        break;
                    }
                }
                break;
            }
            case BTVenmoAppSwitchReturnURLStateFailed:
                [self.client postAnalyticsEvent:@"ios.venmo.appswitch.handle.error"];
                if (completionBlock) {
                    completionBlock(nil, error);
                }
                break;
            case BTVenmoAppSwitchReturnURLStateCanceled:
                [self.client postAnalyticsEvent:@"ios.venmo.appswitch.handle.cancel"];
                if (completionBlock) {
                    completionBlock(nil, nil);
                }
                break;
            default:
                // should not happen
                break;
        }
    };
}

- (BOOL)isAvailable {
    return [self appSwitchErrorForClient:self.client] == nil;
}

- (NSError *)appSwitchErrorForClient:(BTClient *)client {
    if ([client.venmoStatus] == BTVenmoStatusOff) {
        return [NSError errorWithDomain:BTAppSwitchErrorDomain
                                   code:BTAppSwitchErrorDisabled
                               userInfo:@{ NSLocalizedDescriptionKey: @"Venmo is not available",
                                           NSLocalizedFailureReasonErrorKey:@"Venmo App Switch is not enabled." }];
    }

    if (!self.returnURLScheme) {
        return [NSError errorWithDomain:BTAppSwitchErrorDomain
                                   code:BTAppSwitchErrorIntegrationReturnURLScheme
                               userInfo:@{ NSLocalizedDescriptionKey: @"Venmo is not available",
                                       NSLocalizedFailureReasonErrorKey:@"Venmo App Switch requires you to set a returnURLScheme. Please call +[Braintree setReturnURLScheme:]." }];
    }

    if (client.configuration.merchantId == nil) {
        return [NSError errorWithDomain:BTAppSwitchErrorDomain
                                   code:BTAppSwitchErrorIntegrationMerchantId
                               userInfo:@{ NSLocalizedDescriptionKey: @"Venmo is not available",
                                       NSLocalizedFailureReasonErrorKey:@"Venmo App Switch could not find all required fields in the client token." }];
    }

    if (![BTVenmoAppSwitchRequestURL isAppSwitchAvailable]) {
        return [NSError errorWithDomain:BTAppSwitchErrorDomain
                                   code:BTAppSwitchErrorAppNotAvailable
                               userInfo:@{ NSLocalizedDescriptionKey: @"Venmo is not available",
                                       NSLocalizedFailureReasonErrorKey:@"No version of the Venmo app is installed on this device that is compatible with app switch." }];
    }

    return nil;
}

+ (BOOL)canHandleAppSwitchReturnURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication {
    return [BTVenmoAppSwitchReturnURL isValidURL:url sourceApplication:sourceApplication];
}

+ (void)handleAppSwitchReturnURL:(NSURL *)url {
    if (BTVenmoHandleURLContinuation) {
        BTVenmoHandleURLContinuation(url);
    }
}

#pragma mark Delegate Informers

- (void)informDelegateDidPerformAppSwitch {
    if ([self.delegate respondsToSelector:@selector(venmoDriverDidPerformAppSwitch:)]) {
        [self.delegate venmoDriverDidPerformAppSwitch:self];
    }
}

- (void)informDelegateWillProcessAppSwitchResult {
    if ([self.delegate respondsToSelector:@selector(venmoDriverWillProcessAppSwitchResult:)]) {
        [self.delegate venmoDriverWillProcessAppSwitchResult:self];
    }
}

@end
