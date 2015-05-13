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

- (BOOL)initiateAppSwitchWithClient:(BTClient *)client delegate:(id<BTAppSwitchingDelegate>)delegate error:(NSError *__autoreleasing *)errorPtr {

    if (delegate == nil) {
        [client postAnalyticsEvent:@"ios.paypal-otc.preflight.nil-delegate"];
        if (errorPtr != NULL) {
            *errorPtr = [NSError errorWithDomain:BTAppSwitchErrorDomain
                                         code:BTAppSwitchErrorIntegrationInvalidParameters
                                     userInfo:@{ NSLocalizedDescriptionKey: @"PayPal app switch is missing a delegate." }];
        }
        return NO;
    }

    self.delegate = delegate;
    self.client = client;

    BTPayPalDriver *payPalDriver = [[BTPayPalDriver alloc] initWithClient:client];
    [payPalDriver setReturnURLScheme:self.returnURLScheme];
    payPalDriver.delegate = self;

    // Capture return in block in case there is a synchronous failure
    __block BOOL returnValue = YES;
    __block BOOL didReturn = NO;

    [payPalDriver startAuthorizationWithCompletion:^(BTPayPalPaymentMethod * __nullable paymentMethod, NSError * __nullable error) {
        if (didReturn) {
            if (paymentMethod) {
                [self informDelegateDidCreatePayPalPaymentMethod:paymentMethod];
            } else if (error) {
                [self informDelegateDidFailWithError:error];
            } else {
                [self informDelegateDidCancel];
            }
        } else {
            returnValue = NO;
            if (errorPtr != NULL) {
                *errorPtr = error;
            }
        }
    }];

    // For backwards compatibility, set a default error message, in case PayPal driver fails without a specific error
    if (returnValue == NO && errorPtr != NULL && *errorPtr == NULL) {
        *errorPtr = [NSError errorWithDomain:BTAppSwitchErrorDomain
                                        code:BTAppSwitchErrorFailed
                                    userInfo:@{NSLocalizedDescriptionKey: @"Failed to initiate PayPal app switch."}];
    }

    didReturn = YES;

    return returnValue;
}

- (BOOL)appSwitchAvailableForClient:(BTClient *)client {
    BTPayPalDriver *payPalDriver = [[BTPayPalDriver alloc] initWithClient:client];
    [payPalDriver setReturnURLScheme:self.returnURLScheme];

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
