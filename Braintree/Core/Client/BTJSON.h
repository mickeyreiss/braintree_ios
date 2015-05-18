@import Foundation;

NS_ASSUME_NONNULL_BEGIN

@interface BTJSON : NSObject <NSCopying, NSCoding>

+ (instancetype)empty;

+ (instancetype)JSONWithData:(NSData *)data;

/// Accepts a base64 JSON string (assumes UTF8 encoding)
+ (instancetype)JSONWithBase64EncodedString:(NSString *)base64EncodedString;

+ (instancetype)JSONWithDictionary:(NSDictionary *)dictionary;

- (instancetype)initWithData:(NSData *)dictionary NS_DESIGNATED_INITIALIZER;

- (instancetype)initWithDictionary:(NSDictionary *)dictionary;

#pragma mark - Accessors with Specified Types

- (nullable NSString *)asString;
- (nullable NSURL *)asURL;
- (nullable NSArray *)asArray;
- (nullable NSSet *)asSet;
- (nullable NSDictionary *)asObject;
- (nullable NSDecimalNumber *)asNumber;
- (nullable id)asNativeObject;

- (BOOL)isTrue;
- (BOOL)isFalse;
- (BOOL)isNull;

#pragma mark - Errors

- (nullable NSError *)asError;

#pragma mark - Accessors with Transformed Values

- (nullable id)asNativeObjectWithValueTransformer:(Class)valueTransformer;
- (nullable NSArray *)asArrayWithValueTransformer:(Class)valueTransformer;
- (NSInteger)asIntegerWithValueTransformer:(Class)valueTransformer;

#pragma mark - Checkers

- (BOOL)isError;
- (BOOL)isString;
- (BOOL)isURL;
- (BOOL)isArray;
- (BOOL)isSet;
- (BOOL)isDictionary;
- (BOOL)isNumber;
- (BOOL)isObject;

#pragma mark - Accessors for Nested Resources

- (BTJSON *)JSONObjectForKey:(NSString *)key;
- (BTJSON *)objectForKeyedSubscript:(NSString *)key;

#pragma mark - Writing out to JSON

- (nullable NSData *)asJSONData;

@end

NS_ASSUME_NONNULL_END
