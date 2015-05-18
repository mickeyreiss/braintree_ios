#import "BTPayPalDataSource.h"

#import "PayPalOneTouchCore.h"

@interface BTPayPalDataSource () <BTDataCollectorDataSource>
@end

@implementation BTPayPalDataSource

+ (void)load {
    [BTDataCollector registerDataSource:[[self alloc] init]];
}

- (NSDictionary *)dataForDataCollector:(__unused BTDataCollector *)collector {
    return @{@"correlation_id" : [PayPalOneTouchCore clientMetadataID]};
}

@end
