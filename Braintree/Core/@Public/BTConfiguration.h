@import Foundation;
#import "BTJSON.h"

typedef NS_ENUM(NSUInteger, BTConfigurationApplePayStatus) {
    BTConfigurationApplePayStatusOff = 0,
    BTConfigurationApplePayStatusMock = 1,
    BTConfigurationApplePayStatusProduction = 2,
};

typedef NS_ENUM(NSUInteger, BTConfigurationVenmoStatus) {
    BTConfigurationVenmoStatusOff = 0,
    BTConfigurationVenmoStatusOffline,
    BTConfigurationVenmoStatusProduction
};

// TODO: Deprecate this in favor of directly using BTJSON with smart value transformers
@interface BTConfiguration : NSObject <NSCoding, NSCopying>

#pragma mark Braintree Client API

@property (nonatomic, readonly, strong) NSURL *clientApiURL;
@property (nonatomic, readonly, copy) NSString *merchantId;
@property (nonatomic, readonly, copy) NSString *merchantAccountId;

#pragma mark Analytics

@property (nonatomic, readonly, strong) NSURL *analyticsURL;
- (BOOL)analyticsEnabled;

#pragma mark Credit Card Processing

@property (nonatomic, readonly, strong) NSSet *challenges;

#pragma mark PayPal

// Returns the PayPal client id determined by Braintree control panel settings
- (NSString *)payPalClientId;

// Returns a boolean if PayPal is enabled.
- (BOOL)payPalEnabled;

// Returns the PayPal environment name
- (NSString *)payPalEnvironment;

- (NSString *)payPalMerchantName;
- (NSURL *)payPalMerchantUserAgreementURL;
- (NSURL *)payPalPrivacyPolicyURL;
- (NSString *)payPalCurrencyCode;

#pragma mark Coinbase

- (BOOL)coinbaseEnabled;
- (NSString *)coinbaseClientId;
- (NSString *)coinbaseMerchantAccount;
- (NSString *)coinbaseScope;
- (NSString *)coinbaseEnvironment;

#pragma mark Venmo

- (NSString *)venmoStatus;

#pragma mark Apple Pay

- (BTConfigurationApplePayStatus)applePayStatus;
- (NSString *)applePayCountryCode;
- (NSString *)applePayCurrencyCode;
- (NSString *)applePayMerchantIdentifier;
- (NSArray *)applePaySupportedNetworks;

#pragma mark -

//// Initialize Configuration with a configuration response parser fetched from Braintree.
- (instancetype)initWithResponseParser:(BTJSON *)responseParser error:(NSError **)error NS_DESIGNATED_INITIALIZER;

@end
