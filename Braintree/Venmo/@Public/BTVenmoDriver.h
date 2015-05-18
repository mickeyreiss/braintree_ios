#import <UIKit/UIKit.h>

#import "BTClient.h"
#import "BTCardPaymentMethod.h"

NS_ASSUME_NONNULL_BEGIN

@protocol BTVenmoDriverDelegate;

@interface BTVenmoDriver : NSObject

- (nullable instancetype)initWithClient:(BTClient *)client
                        returnURLScheme:(NSString *)returnURLScheme NS_DESIGNATED_INITIALIZER;

+ (void)setReturnURLScheme:(NSString *)returnURLScheme;
+ (BOOL)canHandleAppSwitchReturnURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication;
+ (void)handleAppSwitchReturnURL:(NSURL *)url;

- (void)startAuthorizationWithCompletion:(void (^)(BTCardPaymentMethod *__nullable paymentMethod, NSError *__nullable error))completionBlock;

- (BOOL)isAvailable;

@property (nonatomic, weak, nullable) id<BTVenmoDriverDelegate> delegate;

@end

@protocol BTVenmoDriver

@optional

- (void)venmoDriverDidPerformAppSwitch:(BTVenmoDriver *)venmoDriver;
- (void)venmoDriverWillProcessAppSwitchResult:(BTVenmoDriver *)venmoDriver;

@end

NS_ASSUME_NONNULL_END
