@import Foundation;
#import "BTClient.h"
#import "BTAppSwitchingDelegate.h"

@protocol BTAppSwitchHandling <NSObject>

///  Whether this instance can be used to handle this response URL.
///
///  @param url
///  @param sourceApplication
///
///  @return Whether this instance can handle the given callback URL from
///  the given source application.
- (BOOL)canHandleURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication;

///  Handle the actual response URL that contains payment authorization,
///  indication of cancellation, or error information.
///
///  @param url The callback response URL.
- (BOOL)handleURL:(NSURL *)url;

@end
