@import Foundation;

#import "BTClientTokenizable.h"
#import "BTConfiguration.h"
#import "BTThreeDSecureLookupResult.h"
#import "BTClientPayPalPaymentResource.h"
#import "BTClientToken.h"

#import "BTClientMetadata.h"
#import "BTHTTP.h"

@interface BTClient : NSObject <NSCoding, NSCopying>

/// Initialize and configure a `BTClient` with a client token.
/// The client token dictates the behavior of subsequent operations.
///
/// Grand Central Dispatch: Each method in this class is asynchronous
/// and performs network activity. Upon completion, the completion
/// blocks will be dispatched on the calling queue. For example, if you
/// call tokenizePaymentMethod:completion: on the main queue, the
/// completion block will be dispatched back to the main queue.
///
/// @param clientTokenString Braintree client token for authorization, obtained from your server
- (instancetype)initWithClientToken:(NSString *)clientTokenString;

- (void)GET:(NSString *)endpoint
 parameters:(NSDictionary *)json
 completion:(void (^)(BTHTTPResponse *response, NSError *error))completionBlock;

- (void)POST:(NSString *)endpoint
  parameters:(NSDictionary *)json
  completion:(void (^)(BTHTTPResponse *response, NSError *error))completionBlock;

- (void)PUT:(NSString *)endpoint
 parameters:(NSDictionary *)json
 completion:(void (^)(BTHTTPResponse *response, NSError *error))completionBlock;

- (void)DELETE:(NSString *)endpoint
    parameters:(NSDictionary *)json
    completion:(void (^)(BTHTTPResponse *response, NSError *error))completionBlock;

#pragma mark Payment Method Tokenization

/// Tokenize a payment method to Braintree for subsequent use on your server
///
/// @param paymentMethod an object that includes the raw card details
/// @param completionBlock success callback for handling the resulting new card
///
/// @see challenges
- (void)tokenizePaymentMethod:(id <BTClientTokenizable>)paymentMethod
                   completion:(void (^)(BTPaymentMethod *paymentMethod, NSError *error))completionBlock DEPRECATED_ATTRIBUTE;

#pragma mark - Payment Setup Operations

- (void)lookupNonceForThreeDSecure:(NSString *)nonce
                 transactionAmount:(NSDecimalNumber *)amount
                        completion:(void (^)(BTThreeDSecureLookupResult *result, NSError *error))completionBlock DEPRECATED_ATTRIBUTE;

- (void)createPayPalPaymentResourceWithAmount:(NSDecimalNumber *)amount
                                 currencyCode:(NSString *)currencyCode
                                  redirectUri:(NSString *)redirectUri
                                    cancelUri:(NSString *)cancelUri
                             clientMetadataID:(NSString *)clientMetadataID
                                   completion:(void (^)(BTClientPayPalPaymentResource *))completionBlock DEPRECATED_ATTRIBUTE;

#pragma mark - Other Stuff

/// Models the contents of the client token, as it is received from the merchant server
@property(nonatomic, strong) BTClientToken *clientToken;
@property(nonatomic, strong) BTJSON *configuration;

@property(nonatomic) BOOL hasConfiguration; // YES if configuration was retrieved directly from Braintree, rather than from the client token

@property(nonatomic, copy, readonly) BTClientMetadata *metadata;

///  Copy of the instance, but with different metadata
///
///  Useful for temporary metadata overrides.
///
///  @param metadataBlock block for customizing metadata
- (instancetype)copyWithMetadata:(void (^)(BTClientMutableMetadata *metadata))metadataBlock;

+ (NSString *)libraryVersion;

@end
