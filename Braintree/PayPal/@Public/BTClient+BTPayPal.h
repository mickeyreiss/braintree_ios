#import "BTClient.h"

@class PayPalProfileSharingViewController;
@class PayPalConfiguration;

@protocol PayPalProfileSharingDelegate;

extern NSString *const BTClientPayPalMobileEnvironmentName;

@interface BTClient (BTPayPal)

+ (NSString *)btPayPal_offlineTestClientToken;
- (BOOL)btPayPal_preparePayPalMobileWithError:(NSError * __autoreleasing *)error DEPRECATED_ATTRIBUTE;
- (BOOL)btPayPal_isPayPalEnabled;
- (PayPalProfileSharingViewController *)btPayPal_profileSharingViewControllerWithDelegate:(id<PayPalProfileSharingDelegate>)delegate DEPRECATED_ATTRIBUTE;
- (NSString *)btPayPal_applicationCorrelationId;
- (PayPalConfiguration *)btPayPal_configuration DEPRECATED_ATTRIBUTE;
- (NSString *)btPayPal_environment;
- (BOOL)btPayPal_isTouchDisabled DEPRECATED_ATTRIBUTE;
- (NSSet *)btPayPal_scopes;
@end
