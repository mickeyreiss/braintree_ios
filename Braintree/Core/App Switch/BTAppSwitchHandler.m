#import "BTAppSwitchHandler+HandlerRegistration.h"

@implementation BTAppSwitchHandler

+ (NSMutableOrderedSet *)appSwitchHandlers {
    static NSMutableOrderedSet *appSwitchHandlers;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        appSwitchHandlers = [NSMutableOrderedSet orderedSet];
    });
    return appSwitchHandlers;
}

+ (BOOL)handleURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication {
    for (id<BTAppSwitchHandling> handler in [BTAppSwitchHandler appSwitchHandlers]) {
        if ([handler canHandleURL:url sourceApplication:sourceApplication]) {
            return [handler handleURL:url];
        }
    }
    return NO;
}

+ (BOOL)canHandleURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication {
    for (id<BTAppSwitchHandling> handler in [BTAppSwitchHandler appSwitchHandlers]) {
        if ([handler canHandleURL:url sourceApplication:sourceApplication]) {
            return YES;
        }
    }
    return NO;
}

+ (void)registerAppSwitchHandler:(id<BTAppSwitchHandling>)handler {
    if (handler != nil) {
        [[BTAppSwitchHandler appSwitchHandlers] addObject:handler];
    }
}

+ (void)unregisterAppSwitchHandler:(id<BTAppSwitchHandling>)handler {
    if (handler != nil) {
        [[BTAppSwitchHandler appSwitchHandlers] removeObject:handler];
    }
}


@end
