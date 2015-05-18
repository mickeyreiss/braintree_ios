#import "BTDataCollector.h"

@protocol BTDataCollectorDataSource <NSObject>
- (NSDictionary *)dataForDataCollector:(BTDataCollector *)data delegate:(id<BTDataCollectorDelegate>)delegate;
@end

@interface BTDataCollector (DataSourceRegistration)
+ (void)registerDataSource:(id<BTDataCollectorDataSource>)dataSource;
+ (void)unregisterDataSource:(id<BTDataCollectorDataSource>)dataSource;
@end
