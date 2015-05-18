#import "BTPaymentMethod.h"
#import "BTPaymentMethod+Internal.h"

@implementation BTPaymentMethod

- (id)initWithCoder:(NSCoder *)coder {
    BTPaymentMethod *paymentMethod = [[BTPaymentMethod alloc] init];
    if (paymentMethod) {
        paymentMethod.nonce = [coder decodeObjectForKey:@"nonce"];
        paymentMethod.name = [coder decodeObjectForKey:@"name"];
        paymentMethod.type = [coder decodeIntegerForKey:@"type"];
        paymentMethod.singleUse = [coder decodeBoolForKey:@"singleUse"];
        paymentMethod.threeDSecureInfo = [coder decodeObjectForKey:@"threeDSecureInfo"];
    }
    return paymentMethod;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeObject:self.nonce forKey:@"nonce"];
    [coder encodeObject:self.name forKey:@"name"];
    [coder encodeObject:self.type forKey:@"type"];
    [coder encodeObject:self.singleUse forKey:@"singleUse"];
    [coder encodeObject:self.threeDSecureInfo forKey:@"threeDSecureInfo"];
}

#pragma mark NSCopying
- (id)copyWithZone:(NSZone *)zone {
    BTPaymentMethod *copy = [[BTPaymentMethod alloc] init];
    copy.nonce = _nonce;
    copy.name = _name;
    copy.type = _type;
    copy.singleUse = _singleUse;
    copy.threeDSecureInfo = _threeDSecureInfo;
}

- (void)setNonce:(NSString *)nonce {
    _nonce = nonce;
}

- (void)setName:(NSString *)name {
    _name = name;
}

- (void)setType:(BTPaymentMethodType)type {
    _type = type;
}

- (void)setSingleUse:(BOOL)singleUse {
    _singleUse = singleUse;
}

- (void)setThreeDSecureInfo:(NSDictionary *)threeDSecureInfo {
    _threeDSecureInfo = threeDSecureInfo;
}

- (NSString *)debugDescription {
    return [NSString stringWithFormat:@"<%@:%p \"%@\" nonce:%@>", NSStringFromClass([self class]), self, [self description], self.nonce];
}

@end
