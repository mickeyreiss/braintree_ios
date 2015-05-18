#import "BTCard.h"
#import "BTClientPaymentMethodValueTransformer.h"

@interface BTCard ()
@property (nonatomic, strong) NSMutableDictionary *mutableParameters;
@end

@implementation BTCard

+ (instancetype)cardWithNumber:(NSString *)number expirationDate:(NSString *)date {
    BTCard *card = [[BTCard alloc] init];
    card.number = number;
    card.expirationDate = date;
    return card;
}

+ (instancetype)cardWithNumber:(NSString *)number expirationMonth:month expirationYear:(NSString *)year {
    BTCard *card = [[BTCard alloc] init];
    card.number = number;
    card.expirationMonth = month;
    card.expirationYear = year;
    return card;
}

+ (instancetype)cardWithParameters:(NSDictionary *)parameters {
    BTCard *card = [[BTCard alloc] init];
    card.parameters = parameters;
    return card;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.mutableParameters = [NSMutableDictionary dictionary];
    }
    return self;
}

#pragma mark - Tokenization

- (void)tokenizeWithClient:(BTClient *)client
                completion:(void (^)(BTPaymentMethod *paymentMethod, NSError *error))completionBlock {
    [client POST:@"v1/payment_methods/credit_cards"
      parameters:@{ @"credit_card": self.parameters }
      completion:^(BTClientResponse *response, NSError *error) {
          if (completionBlock) {
              if (error) {
                  completionBlock(nil, error);
              } else if (response.statusCode == 201 || response.statusCode == 202) {
                  completionBlock([[response.body[@"creditCards"] asArrayWithValueTransformer:[BTClientPaymentMethodValueTransformer class]] firstObject], error);
              } else if (response.statusCode == 422) {
                  // TODO: Figure out error handling
                  completionBlock(nil, [NSError errorWithDomain:BraintreeErrorDomain
                                                           code:BTRecoverableError
                                                       userInfo:@{}]);
              } else {
                  completionBlock(nil, error);
              }
          }
      }];
}

#pragma mark - Parameters

- (void)setNumber:(NSString *)number {
    self[BTCardParameterNumberKey] = number;
}

- (NSString *)number {
    return self.mutableParameters[BTCardParameterNumberKey];
}

- (void)setCvv:(NSString *)cvv {
    self[BTCardParameterCVVKey] = cvv;
}

- (NSString *)cvv {
    return self.mutableParameters[BTCardParameterCVVKey];
}

- (void)setPostalCode:(NSString *)postalCode {
    self[BTCardParameterPostalCodeKey] = postalCode;
}

- (NSString *)postalCode {
    return self.mutableParameters[BTCardParameterPostalCodeKey];
}

- (void)setExpirationYear:(NSString *)expirationYear {
    self[BTCardParameterExpirationYearKey] = expirationYear;
}

- (NSString *)expirationYear {
    return self.mutableParameters[BTCardParameterExpirationYearKey];
}

- (void)setExpirationMonth:(NSString *)expirationMonth {
    self[BTCardParameterExpirationMonthKey] = expirationMonth;
}

- (NSString *)expirationMonth {
    return self.mutableParameters[BTCardParameterExpirationMonthKey];
}

- (void)setExpirationDate:(NSString *)expirationDate {
    self[BTCardParameterExpirationDateKey] = expirationDate;
}

- (NSString *)expirationDate {
    return self.mutableParameters[BTCardParameterExpirationDateKey];
}

- (void)setObject:(id)value forKeyedSubscript:(NSString *)key {
    if (value == nil) {
        [self.mutableParameters removeObjectForKey:key];
    } else {
        self.mutableParameters[key] = value;
    }
}

- (NSDictionary *)parameters {
    return [self.mutableParameters copy];
}

- (void)setParameters:(NSDictionary *)parameters {
    [self.mutableParameters removeAllObjects];
    [self.mutableParameters addEntriesFromDictionary:parameters];
}

@end
