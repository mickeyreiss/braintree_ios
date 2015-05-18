#import <Foundation/Foundation.h>
#import "BTPaymentMethod.h"

@interface BTPaymentMethod (Internal)

- (void)setNonce:(NSString *)nonce;
- (void)setName:(NSString *)name;
- (void)setType:(BTPaymentMethodType)type;
- (void)setSingleUse:(BOOL)singleUse;
- (void)setThreeDSecureInfo:(NSDictionary *)threeDSecureInfo;

@end
