#import "BTAppSwitchHandler.h"

@interface BTAppSwitchHandler (HandlerRegistration)

+ (void)registerAppSwitchHandler:(id<BTAppSwitchHandling>)handler;
+ (void)unregisterAppSwitchHandler:(id<BTAppSwitchHandling>)handler;

@end
