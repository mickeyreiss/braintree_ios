@import Foundation;

@class BTClient;
@protocol BTAnalyticsClientDelegate;

NS_ASSUME_NONNULL_BEGIN

@interface BTAnalyticsClient : NSObject

- (instancetype)initWithClient:(BTClient *)client NS_DESIGNATED_INITIALIZER;

- (void)postEvent:(NSString *)eventName;

@property (nonatomic, weak) id<BTAnalyticsClientDelegate> delegate;

@end

@protocol BTAnalyticsClientDelegate <NSObject>

- (void)analyticsClientWillPostPayload:(BTAnalyticsClient *)client;
- (void)analyticsClient:(BTAnalyticsClient *)client didPostPayload:(NSDictionary *)payload;
- (void)analyticsClient:(BTAnalyticsClient *)client didFailWithError:(NSError *)error;

@end

NS_ASSUME_NONNULL_END
