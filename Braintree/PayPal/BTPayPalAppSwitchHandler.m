#import "BTPayPalAppSwitchHandler_Internal.h"

#import "BTClient_Internal.h"
#import "BTMutablePayPalPaymentMethod.h"
#import "BTLogger_Internal.h"
#import "BTErrors+BTPayPal.h"

#import "PayPalOneTouchRequest.h"
#import "PayPalOneTouchCore.h"

#import "BTPayPalDriver.h"

@interface BTPayPalAppSwitchHandler () <BTPayPalDelegate>
@end

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
    [BTPayPalDriver handleAppSwitchReturnURL:url];
}

- (BOOL)initiateAppSwitchWithClient:(BTClient *)client delegate:(id<BTAppSwitchingDelegate>)delegate error:(NSError *__autoreleasing *)error {

    if (delegate == nil) {
        [client postAnalyticsEvent:@"ios.paypal-otc.preflight.nil-delegate"];
        if (error != NULL) {
            *error = [NSError errorWithDomain:BTAppSwitchErrorDomain
                                         code:BTAppSwitchErrorIntegrationInvalidParameters
                                     userInfo:@{ NSLocalizedDescriptionKey: @"PayPal app switch is missing a delegate." }];
        }
        return NO;
    }

    self.delegate = delegate;
    self.client = client;

<<<<<<< HEAD
    PayPalOneTouchAuthorizationRequest *request =
    [PayPalOneTouchAuthorizationRequest requestWithScopeValues:client.btPayPal_scopes
                                                    privacyURL:client.configuration.payPalPrivacyPolicyURL
                                                  agreementURL:client.configuration.payPalMerchantUserAgreementURL
                                                      clientID:[self payPalClientIdForClient:client]
                                                   environment:client.btPayPal_environment
                                             callbackURLScheme:[self returnURLScheme]];
    request.additionalPayloadAttributes = @{ @"client_token": client.clientToken.originalValue };
=======
    BTPayPalDriver *payPalDriver = [[BTPayPalDriver alloc] initWithClient:client];
    [payPalDriver setReturnURLScheme:self.returnURLScheme];
    payPalDriver.delegate = self;
>>>>>>> Refactor PayPal code to use future public interface BTPayPalDriver

    // Capture return in block in case there is a synchronous failure
    __block BOOL returnValue = YES;

    [payPalDriver startAuthorizationWithCompletion:^(BTPayPalPaymentMethod * __nullable paymentMethod, NSError * __nullable error) {
        if (paymentMethod) {
            [self informDelegateDidCreatePayPalPaymentMethod:paymentMethod];
        } else if (error) {
            returnValue = NO;
            [self informDelegateDidFailWithError:error];
        } else {
            [self informDelegateDidCancel];
        }
    }];

    return returnValue;
}

- (BOOL)appSwitchAvailableForClient:(BTClient *)client {
<<<<<<< HEAD
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
=======
    BTPayPalDriver *payPalDriver = [[BTPayPalDriver alloc] initWithClient:client];
    [payPalDriver setReturnURLScheme:self.returnURLScheme];
>>>>>>> Refactor PayPal code to use future public interface BTPayPalDriver

    return [payPalDriver isAvailable];
}

#pragma mark BTPayPalDelegate

- (void)payPal:(__unused BTPayPalDriver * __nonnull)payPal didChangeState:(BTPayPalState)state {
    if (state == BTPayPalStateProcessingAppSwitchReturn) {
        [self informDelegateWillCreatePayPalPaymentMethod];
    }
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
