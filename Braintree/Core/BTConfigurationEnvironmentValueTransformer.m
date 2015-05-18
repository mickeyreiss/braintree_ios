#import "BTConfigurationEnvironmentValueTransformer.h"

@implementation BTConfigurationEnvironmentValueTransformer

+ (Class)transformedValueClass {
    return [NSNumber class];
}

- (id)transformedValue:(id)value {
    if ([value isKindOfClass:[NSString class]]) {
        if ([value isEqualToString:@"production"]) {

        } else if ([value isEqualToString:@"production"]) {
            return @(BTConfigurationEnvironmentProduction);
        } else if ([value isEqualToString:@"sandbox"]) {
            return @(BTConfigurationEnvironmentSandbox);
        } else if ([value isEqualToString:@"qa"] || [value isEqualToString:@"qa2"]) {
            return @(BTConfigurationEnvironmentQA);
        } else if ([value isEqualToString:@"development"]) {
            return @(BTConfigurationEnvironmentDevelopment);
        }
    }

    return @(BTConfigurationEnvironmentUnknown);
}

- (id)reverseTransformedValue:(id)value {
    if ([value respondsToSelector:@selector(integerValue)]) {
       switch ([value integerValue]) {
           case BTConfigurationEnvironmentProduction:
               return @"production";
           case BTConfigurationEnvironmentSandbox:
               return @"sandbox";
           case BTConfigurationEnvironmentQA:
               return @"qa";
           case BTConfigurationEnvironmentDevelopment:
               return @"development";
       }
    }

    return nil;
}

@end
