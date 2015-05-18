#import "DeviceCollectorSDK.h"
#import "BTClient.h"

NS_ASSUME_NONNULL_BEGIN

@protocol BTDataCollectorDelegate;

/// BT Data - Braintree's advanced fraud protection solution
@interface BTDataCollector : NSObject

/// The instance of BTClient that is used to configure this data collector
@property (nonatomic, readonly) BTClient *client;

/// Set a BTDataCollectorDelegate to receive notifications about collector events.
///
/// @param delegate Object to notify
@property (nonatomic, weak) id<BTDataCollectorDelegate> delegate;

/// Initialize a BTData instance for use alongside an existing BTClient instance
///
/// @param client       A BTClient instance
- (instancetype)initWithClient:(BTClient *)client NS_DESIGNATED_INITIALIZER;

/// Collect fraud data for the current session.
///
/// While this operation is asynchronous, it is not necessary to block your UI on completion, as the device data returned
/// is available before the collection completes.
///
/// @return an opaque string of the device data that can be passed into server-side calls, such as Transaction.create.
- (NSString *)collectDeviceData;

@end

/// Protocol that provides status updates from BTData
@protocol BTDataCollectorDelegate <NSObject>
@optional

/// Notfication that the collector finished successfully.
///
/// @param data The instance of BTData that completed data collection
- (void)dataCollectorDidCollectDeviceData:(BTDataCollector *)data;

/// Notification that an error occurred.
///
/// @param data The instance of BTData that failed to collect data
/// @param error Triggering error if available
- (void)dataCollector:(BTDataCollector *)data didFailWithError:(NSError *)error;

@end

NS_ASSUME_NONNULL_END
