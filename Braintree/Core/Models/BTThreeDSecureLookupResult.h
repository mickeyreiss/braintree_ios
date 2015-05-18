@import Foundation;

#import "BTPaymentMethod.h"

@interface BTThreeDSecureLookupResult : NSObject

@property (nonatomic, copy) NSString *PAReq;
@property (nonatomic, copy) NSString *MD;
@property (nonatomic, copy) NSURL *acsURL;
@property (nonatomic, copy) NSURL *termURL;

@property (nonatomic, strong) BTPaymentMethod *card;

- (BOOL)requiresUserAuthentication;

@end
