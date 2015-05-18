@import Foundation;
#import "BTAppSwitching.h"

@interface BTAppSwitchHandler : NSObject

+ (BOOL)canHandleURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication;

/// Handle app switch URL requests for the Braintree SDK
///
/// @param url               The URL received by the application delegate `openURL` method
/// @param sourceApplication The source application received by the application delegate `openURL` method
///
/// @return Whether Braintree was able to handle the URL and source application
+ (BOOL)handleURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication;

@end
