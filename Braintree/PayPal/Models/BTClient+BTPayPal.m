#import "BTClient+BTPayPal.h"
#import "BTErrors+BTPayPal.h"

#import "PayPalOneTouchCore.h"
#import "PayPalOneTouchRequest.h"
#import "BTClient_Internal.h"
#import "BTClient+Offline.h"

NSString *const BTClientPayPalMobileEnvironmentName = @"Braintree";
NSString *const BTClientPayPalConfigurationError = @"The PayPal SDK could not be initialized. Perhaps client token did not contain a valid PayPal configuration.";

@implementation BTClient (BTPayPal)

+ (NSString *)btPayPal_offlineTestClientToken {
    NSDictionary *payPalClientTokenData = @{ BTConfigurationKeyPayPal: @{
                                                     BTConfigurationKeyPayPalMerchantName: @"Offline Test Merchant",
                                                     BTConfigurationKeyPayPalClientId: @"paypal-client-id",
                                                     BTConfigurationKeyPayPalMerchantPrivacyPolicyUrl: @"http://example.com/privacy",
                                                     BTConfigurationKeyPayPalEnvironment: BTConfigurationPayPalEnvironmentOffline,
                                                     BTConfigurationKeyPayPalMerchantUserAgreementUrl: @"http://example.com/tos" }
                                             };

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    return [self offlineTestClientTokenWithAdditionalParameters:payPalClientTokenData];
#pragma clang diagnostic pop
}

- (BOOL)btPayPal_preparePayPalMobileWithError:(__unused NSError * __autoreleasing *)error {
    return YES;
}

- (NSSet *)btPayPal_scopes {
    return [NSSet setWithObjects:@"https://uri.paypal.com/services/payments/futurepayments", @"kPayPalOAuth2ScopeEmail", nil];
}

- (PayPalProfileSharingViewController *)btPayPal_profileSharingViewControllerWithDelegate:(__unused id<PayPalProfileSharingDelegate>)delegate {
    return nil;
}

- (BOOL)btPayPal_isPayPalEnabled {
    return self.configuration.payPalEnabled;
}

- (NSString *)btPayPal_applicationCorrelationId {
    return [PayPalOneTouchCore clientMetadataID];
}

- (PayPalConfiguration *)btPayPal_configuration {
    return nil;
}

- (NSString *)btPayPal_environment {
    if ([self.configuration.payPalEnvirnoment isEqualToString:BTConfigurationPayPalEnvironmentLive]) {
        return PayPalEnvironmentProduction;
    } else if ([self.configuration.payPalEnvirnoment isEqualToString:BTConfigurationPayPalEnvironmentOffline]) {
        return PayPalEnvironmentMock;
    }

    return nil;
}

- (BOOL)btPayPal_isTouchDisabled {
    return NO;
}

@end
