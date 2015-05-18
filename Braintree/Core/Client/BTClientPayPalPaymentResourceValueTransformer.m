#import "BTClientPayPalPaymentResourceValueTransformer.h"

@implementation BTClientPayPalPaymentResourceValueTransformer

+ (BOOL)allowsReverseTransformation {
    return NO;
}

+ (Class)transformedValueClass {
    return [BTClientPayPalPaymentResource class];
}

- (id)transformedValue:(id)value {
    if (![value isKindOfClass:[NSDictionary class]]) {
        return nil;
    }
          
    BTJSON *parser = [BTJSON JSONWithDictionary:value];
    
    BTClientPayPalPaymentResource *paymentResource = [[BTClientPayPalPaymentResource alloc] init];
    
    paymentResource.redirectURL = parser[@"redirectUrl"].asURL;
    
    return paymentResource;
}

@end
