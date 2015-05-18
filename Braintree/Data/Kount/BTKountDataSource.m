#import "DeviceCollectorSDK.h"

#import "BTKountDataSource.h"

#import "BTDataCollector+DataSourceRegistration.h"

static NSString *const BTKountDataSharedMerchantId = @"600000";

static NSString *BTKountDataSourceMerchantId = BTKountDataSharedMerchantId;
static NSString *BTKountDataSourceCollectorUrl = nil;

@interface BTKountDataSource () <BTDataCollectorDataSource, DeviceCollectorSDKDelegate>
@property (nonatomic, strong) DeviceCollectorSDK *kount;
@property (nonatomic, weak) id <BTDataCollectorDelegate> delegate;
@end

@implementation BTKountDataSource

+ (void)load {
    [BTDataCollector registerDataSource:[[self alloc] init]];
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.kount = [[DeviceCollectorSDK alloc] initWithDebugOn:NO];
        self.kount.delegate = self;
    }
    return self;
}

- (NSDictionary *)dataForDataCollector:(BTDataCollector *)data delegate:(id <BTDataCollectorDelegate>)delegate {
    self.delegate = delegate;

    // Create a random device session id
    NSString *sessionId = [[[NSUUID UUID] UUIDString] stringByReplacingOccurrencesOfString:@"-" withString:@""];

    // Avoid blocking for any device data collection
    dispatch_async(dispatch_get_main_queue(), ^{
    // Setup the url based on the environment unless it has already been overridden
    NSString *collectorUrl = BTKountDataSourceCollectorUrl;
    if (collectorUrl == nil) {
        switch (data.client.configuration.environment) {
            case BTConfigurationEnvironmentDevelopment:
                break;
            case BTConfigurationEnvironmentQA:
                defaultCollectorUrl = @"https://assets.qa.braintreegateway.com/data/logo.htm";
                break;
            case BTConfigurationEnvironmentSandbox:
                defaultCollectorUrl = @"https://assets.braintreegateway.com/sandbox/data/logo.htm";
                break;
            case BTConfigurationEnvironmentProduction:
                defaultCollectorUrl = @"https://assets.braintreegateway.com/data/logo.htm";
                break;
        }
    }

    [self.kount setCollectorUrl:defaultCollectorUrl];
    [self.kount setMerchantId:BTKountDataSourceMerchantId];

    // Setup Kount skip list to avoid IDFA and location services prompt
    NSArray *skipList;
    CLAuthorizationStatus locationStatus = [CLLocationManager authorizationStatus];
    if ((locationStatus == kCLAuthorizationStatusAuthorizedWhenInUse || locationStatus == kCLAuthorizationStatusAuthorizedAlways) && [CLLocationManager locationServicesEnabled]) {
        skipList = @[DC_COLLECTOR_DEVICE_ID];
    } else {
        skipList = @[DC_COLLECTOR_DEVICE_ID, DC_COLLECTOR_GEO_LOCATION];
    }
    [self.kount setSkipList:skipList];
    });
    return @{ @"device_session_id": sessionId,
              @"fraud_merchant_id": self.fraudMerchantId };
}

#pragma mark DeviceCollectorSDKDelegate methods

- (void)onCollectorStart {
    if ([self.delegate respondsToSelector:@selector(btDataDidStartCollectingData:)]) {
        [self.delegate btDataDidStartCollectingData:self];
    }
}

- (void)onCollectorSuccess {
    if ([self.delegate respondsToSelector:@selector(btDataDidComplete:)]) {
        [self.delegate btDataDidComplete:self];
    }
}

- (void)onCollectorError:(int)errorCode :(NSError *)error {
    if ([self.delegate respondsToSelector:@selector(btData:didFailWithErrorCode:error:)]) {
        [self.delegate btData:self didFailWithErrorCode:errorCode error:error];
    }
}

@end
