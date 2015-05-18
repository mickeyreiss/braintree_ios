#import "BTDataCollector.h"
#import "BTDataCollector+DataSourceRegistration.h"

static NSString *BTDataSharedMerchantId = @"600000";

@interface BTDataCollector ()
@property(nonatomic, strong) BTClient *client;
@end

@implementation BTDataCollector

- (instancetype)initWithClient:(BTClient *)client {
    if (!client) {
        return nil;
    }

    self = [super init];
    if (self) {
        self.client = client;
    }
    return self;
}

- (NSString *)collectDeviceData {
   // TODO: Rename this event
    [self.client postAnalyticsEvent:@"ios.data-collector.collect.started"];

    NSMutableDictionary *deviceDataDictionary = [NSMutableDictionary dictionaryWithCapacity:[BTDataCollector allDataSources].count];
    for (id <BTDataCollectorDataSource> dataSource in [BTDataCollector allDataSources]) {
        NSDictionary *dataSourceData = [dataSource dataForDataCollector:self
                                                               delegate:self.delegate];
        [deviceDataDictionary addEntriesFromDictionary:dataSourceData];
    }

    NSError *jsonSerializationError;
    NSData *data = [NSJSONSerialization dataWithJSONObject:deviceDataDictionary
                                                   options:0
                                                     error:&jsonSerializationError];
    if (jsonSerializationError) {
        if ([self.delegate respondsToSelector:@selector(dataCollector:didFailWithError:)]) {
            [self.delegate dataCollector:self didFailWithError:jsonSerializationError];
        }

        return nil;
    }

    return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
}

#pragma mark -

+ (NSMutableOrderedSet *)allDataSources {
    static NSMutableOrderedSet *dataSources;
    static dispatch_once_t onceToken;
    dispatch_once(onceToken, ^{
        dataSources = [NSMutableOrderedSet orderedSet];
    });
    return dataSources;
}

+ (void)registerDataSource:(id <BTDataCollectorDataSource>)dataSource {
    if (dataSource) {
        [[self allDataSources] addObject:dataSource];
    }
}

+ (void)unregisterDataSource:(id <BTDataCollectorDataSource>)dataSource {
    if (dataSource) {
        [[self allDataSources] removeObject:dataSource];
    }
}

@end
