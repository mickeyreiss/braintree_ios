#import <Foundation/Foundation.h>
#import "BTCard.h"

@interface BTCard (BTEncryption)

/// Encrypts the credit card data for the Braintree CSE integration style, which is now deprecated.
///
/// @param key The CSE Key obtained from the production control panel (https://braintreegateway.com).
/// @param completionBlock A completion block that will be called when encryption is complete
- (void)encryptWithClient:(BTClient *)client
                   CSEKey:(NSString *)key
               completion:(void (^)(NSDictionary *encryptedParameters))completionBlock;

/// Encrypts the credit card data for the Braintree CSE integration style, which is now deprecated, for the current environment.
///
/// @param key The Production CSE Key obtained from the Braintree control panel.
/// @param key The Sandbox CSE Key obtained from the Braintree control panel.
/// @param completionBlock A completion block that will be called when encryption is complete
- (void)encryptWithClient:(BTClient *)client
         productionCSEKey:(NSString *)productionKey
            sandboxCSEKey:(NSString *)sandboxKey
               completion:(void (^)(NSDictionary *encryptedParameters))completionBlock;

@end
