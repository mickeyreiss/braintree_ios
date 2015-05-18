@import Foundation;
#import "BTJSON.h"

@interface BTHTTPResponse : NSObject

@property (nonatomic, readonly, strong) BTJSON *object;
@property (nonatomic, readonly, strong) NSHTTPURLResponse *response;
@property (nonatomic, readonly, assign, getter = isSuccess) BOOL success;

- (instancetype)initWithResponse:(NSHTTPURLResponse *)response data:(BTJSON *)data;

@end
