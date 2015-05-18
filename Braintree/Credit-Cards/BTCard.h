@import Foundation;

#import "BTClient.h"
#import "BTPaymentMethod.h"

extern NSString *const BTCardParameterNumberKey;
extern NSString *const BTCardParameterExpirationMonthKey;
extern NSString *const BTCardParameterExpirationYearKey;
extern NSString *const BTCardParameterExpirationDateKey;
extern NSString *const BTCardParameterCVVKey;
extern NSString *const BTCardParameterPostalCodeKey;

@interface BTCard : NSObject

+ (instancetype)cardWithNumber:(NSString *)number expirationDate:(NSString *)date;

+ (instancetype)cardWithNumber:(NSString *)number expirationMonth:month expirationYear:(NSString *)year;

+ (instancetype)cardWithParameters:(NSDictionary *)parameters;

#pragma mark -

- (instancetype)init;

- (void)tokenizeWithClient:(BTClient *)client
                completion:(void (^)(BTPaymentMethod *paymentMethod, NSError *error))completionBlock;

#pragma mark -

@property (nonatomic, copy) NSString *number;

@property (nonatomic, copy) NSString *cvv;

@property (nonatomic, copy) NSString *postalCode;

@property (nonatomic, copy) NSString *expirationYear;

@property (nonatomic, copy) NSString *expirationMonth;

@property (nonatomic, copy) NSString *expirationDate;

@property (nonatomic, copy) NSDictionary *parameters;

- (void)setObject:(id)value forKeyedSubscript:(NSString *)key;

@end
