#import "BTClient.h"
#import "BTCard+BTEncryption.h"
#import "BTEncryption.h"
#import "BTConfigurationEnvironmentValueTransformer.h"

@implementation BTCard (BTEncryption)

- (void)encryptWithClient:(BTClient *)client
                   CSEKey:(NSString *)key
               completion:(void (^)(NSDictionary *encryptedParameters))completionBlock {
    [self encryptWithClient:client
           productionCSEKey:key
              sandboxCSEKey:nil
                 completion:completionBlock];
}

- (void)encryptWithClient:(BTClient *)client
         productionCSEKey:(NSString *)productionKey
            sandboxCSEKey:(NSString *)sandboxKey
               completion:(void (^)(NSDictionary *encryptedParameters))completionBlock {
    // TODO Post analytics event

    BTConfigurationEnvironment environment = [client.configuration[@"environment"] asIntegerWithValueTransformer:[BTConfigurationEnvironmentValueTransformer class]];
    BTEncryption *encryption;
    switch (environment) {
        case BTConfigurationEnvironmentSandbox:
            encryption = [[BTEncryption alloc] initWithPublicKey:sandboxKey];
            break;
        default:
            encryption = [[BTEncryption alloc] initWithPublicKey:productionKey];
            break;
    }

    NSMutableDictionary *encryptedParameters = [NSMutableDictionary dictionaryWithCapacity:self.parameters.count];
    [self.parameters enumerateKeysAndObjectsUsingBlock:^(id key, id obj, __unused BOOL *stop) {
        if ([obj isKindOfClass:[NSString class]]) {
            encryptedParameters[key] = [encryption encryptString:obj];
        }
    }];

    completionBlock([encryptedParameters copy]);
}

@end
