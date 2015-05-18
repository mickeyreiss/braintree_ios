@import Foundation;

typedef NS_ENUM(NSInteger, BTConfigurationEnvironment) {
    BTConfigurationEnvironmentUnknown = 0,
    BTConfigurationEnvironmentProduction,
    BTConfigurationEnvironmentSandbox,
    BTConfigurationEnvironmentQA,
    BTConfigurationEnvironmentDevelopment,
};

@interface BTConfigurationEnvironmentValueTransformer : NSValueTransformer

@end
