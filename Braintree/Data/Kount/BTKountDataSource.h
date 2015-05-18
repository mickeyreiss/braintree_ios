@import Foundation;

@interface BTKountDataSource : NSObject

#pragma mark Direct Integrations

/// Optionally override your Kount Fraud Merchant ID.
///
/// @note If you do not call this method, a generic Braintree value will be used.
///
/// @param fraudMerchantId The fraudMerchantId you have established with your Braintree account manager.
+ (void)setMerchantIdentifier:(NSString *)fraudMerchantId;

/// Set the URL that the Kount Device Collector will use.
///
/// @note If you do not call this method, a generic Braintree value will be used.
///
/// @param url Full URL to device collector 302-redirect page
+ (void)setCollectorUrl:(NSString *)url;

@end
