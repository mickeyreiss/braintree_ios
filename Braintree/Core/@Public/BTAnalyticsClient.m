#import "BTAnalyticsClient.h"
#import "BTClient.h"
#import "BTLogger_Internal.h"
#import "BTAnalyticsMetadata.h"
#import "BTClient_Internal.h"

@interface BTAnalyticsClient ()
@property(nonatomic, strong) BTClient *client;
@property(nonatomic, strong) BTHTTP *http;
@end

@implementation BTAnalyticsClient

- (instancetype)initWithClient:(BTClient *)client {
    self = [super init];
    if (self) {
        self.client = client;

        if (self.client.configuration[@"analytics"][@"url"].isURL) {
            NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration ephemeralSessionConfiguration];
            NSOperationQueue *delegateQueue = [[NSOperationQueue alloc] init];
            delegateQueue.name = @"BTAnlayticsClient Delegate Queue";
            if ([delegateQueue respondsToSelector:@selector(setQualityOfService:)]) {
                delegateQueue.qualityOfService = NSQualityOfServiceBackground;
            }
            delegateQueue.maxConcurrentOperationCount = NSOperationQueueDefaultMaxConcurrentOperationCount;
            
            self.http = [[BTHTTP alloc] initWithBaseURL:self.client.configuration[@"analytics"][@"URL"].asURL
                                   sessionConfiguration:configuration
                                          delegateQueue:delegateQueue];
        }
    }
    return self;
}

- (void)postEvent:(NSString *)eventName {
    if (self.client.configuration[@"analytics"][@"url"].isURL) {
        NSDictionary *requestParameters = @{
                @"_meta" : [BTAnalyticsMetadata metadata],
                @"analytics" : @[@{ @"kind": eventName, }],
                @"authorization_fingerprint" : self.client.clientToken.authorizationFingerprint,
        };

        [[BTLogger sharedLogger] debug:@"BTClient postAnalyticsEvent:%@", eventName];

        if ([self.delegate respondsToSelector:@selector(analyticsClientWillPostPayload:)]) {
            [self.delegate analyticsClientWillPostPayload:self];
        }
        [self.http POST:@"/"
             parameters:requestParameters
             completion:^(BTHTTPResponse *response, NSError *error) {
                 if (response.isSuccess) {
                     if ([self.delegate respondsToSelector:@selector(analyticsClient:didPostPayload:)]) {
                         [self.delegate analyticsClient:self didPostPayload:requestParameters];
                     }
                 } else {
                     if ([self.delegate respondsToSelector:@selector(analyticsClient:didFailWithError:)]) {
                         [self.delegate analyticsClient:self didFailWithError:error];
                     }
                 }
             }];
    }
}


@end
