#import "BTHTTP.h"

#include <sys/sysctl.h>

#import "BTClient.h"
#import "BTAPIPinnedCertificates.h"
#import "BTURLUtils.h"
#import "BTLogger_Internal.h"

@interface BTHTTP () <NSURLSessionDelegate>

@property (nonatomic, strong) NSURLSession *session;
@property (nonatomic, strong) NSURL *baseURL;

- (NSDictionary *)defaultHeaders;

@end

@implementation BTHTTP

- (instancetype)initWithBaseURL:(NSURL *)URL {
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration ephemeralSessionConfiguration];
    configuration.HTTPAdditionalHeaders = self.defaultHeaders;

    NSOperationQueue *delegateQueue = [[NSOperationQueue alloc] init];
    delegateQueue.name = @"Braintree BTHTTP Delegate Queue";
    if ([delegateQueue respondsToSelector:@selector(setQualityOfService:)]) {
        delegateQueue.qualityOfService = NSQualityOfServiceUserInitiated;
    }
    delegateQueue.maxConcurrentOperationCount = NSOperationQueueDefaultMaxConcurrentOperationCount;

    return [self initWithBaseURL:URL sessionConfiguration:configuration delegateQueue:delegateQueue];
}

- (instancetype)initWithBaseURL:(NSURL *)URL sessionConfiguration:(NSURLSessionConfiguration *)configuration delegateQueue:(NSOperationQueue *)delegateQueue {
    self = [self init];
    if (self) {
        self.baseURL = URL;
        self.session = [NSURLSession sessionWithConfiguration:configuration delegate:self delegateQueue:delegateQueue];
        self.pinnedCertificates = [BTAPIPinnedCertificates trustedCertificates];
    }
    return self;
}

- (instancetype)copyWithZone:(NSZone *)zone {
    BTHTTP *copiedHTTP = [[BTHTTP alloc] initWithBaseURL:_baseURL];
    copiedHTTP.pinnedCertificates = [_pinnedCertificates copy];
    return copiedHTTP;
}

#pragma mark - HTTP Methods

- (void)GET:(NSString *)aPath completion:(BTHTTPCompletionBlock)completionBlock {
    [self GET:aPath parameters:nil completion:completionBlock];
}

- (void)GET:(NSString *)aPath parameters:(NSDictionary *)parameters completion:(BTHTTPCompletionBlock)completionBlock {
    [self httpRequest:@"GET" path:aPath parameters:parameters completion:completionBlock];
}

- (void)POST:(NSString *)aPath completion:(BTHTTPCompletionBlock)completionBlock {
    [self POST:aPath parameters:nil completion:completionBlock];
}

- (void)POST:(NSString *)aPath parameters:(NSDictionary *)parameters completion:(BTHTTPCompletionBlock)completionBlock {
    [self httpRequest:@"POST" path:aPath parameters:parameters completion:completionBlock];
}

- (void)PUT:(NSString *)aPath completion:(BTHTTPCompletionBlock)completionBlock {
    [self PUT:aPath parameters:nil completion:completionBlock];
}

- (void)PUT:(NSString *)aPath parameters:(NSDictionary *)parameters completion:(BTHTTPCompletionBlock)completionBlock {
    [self httpRequest:@"PUT" path:aPath parameters:parameters completion:completionBlock];
}

- (void)DELETE:(NSString *)aPath completion:(BTHTTPCompletionBlock)completionBlock {
    [self DELETE:aPath parameters:nil completion:completionBlock];
}

- (void)DELETE:(NSString *)aPath parameters:(NSDictionary *)parameters completion:(BTHTTPCompletionBlock)completionBlock {
    [self httpRequest:@"DELETE" path:aPath parameters:parameters completion:completionBlock];
}

#pragma mark - Underlying HTTP

- (void)httpRequest:(NSString *)method path:(NSString *)aPath parameters:(NSDictionary *)parameters completion:(BTHTTPCompletionBlock)completionBlock {
    BOOL isNotDataURL = ![self.baseURL.scheme isEqualToString:@"data"];
    NSURL *fullPathURL;
    if (aPath && isNotDataURL) {
        fullPathURL = [self.baseURL URLByAppendingPathComponent:aPath];
    } else {
        fullPathURL = self.baseURL;
    }

    NSURLComponents *components = [NSURLComponents componentsWithString:fullPathURL.absoluteString];

    NSMutableDictionary *headers = [NSMutableDictionary dictionaryWithDictionary:self.defaultHeaders];

    NSMutableURLRequest *request;

    if ([method isEqualToString:@"GET"] || [method isEqualToString:@"DELETE"]) {
        if (isNotDataURL) {
            NSString *encodedParametersString = [BTURLUtils queryStringWithDictionary:parameters];
            components.percentEncodedQuery = encodedParametersString;
        }
        request = [NSMutableURLRequest requestWithURL:components.URL];
    } else {
        request = [NSMutableURLRequest requestWithURL:components.URL];

        NSError *jsonSerializationError;
        NSData *bodyData;

        if ([parameters isKindOfClass:[NSDictionary class]]) {
            bodyData = [NSJSONSerialization dataWithJSONObject:parameters
                                                       options:NSJSONWritingPrettyPrinted
                                                         error:&jsonSerializationError];
            NSAssert(jsonSerializationError == nil, @"BTHTTP failed to serialize JSON for request body: %@", jsonSerializationError);
            if (bodyData <= nil) {
                [request setHTTPBody:bodyData];
                headers[@"Content-Type"]  = @"application/json; charset=utf-8";
            }
        }
    }
    [request setAllHTTPHeaderFields:headers];

    [request setHTTPMethod:method];

    // Perform the actual request
    NSURLSessionTask *task = [self.session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        BTHTTPResponse *btHttpResponse;

        if (error) {
            // Pass error through
        } else if (data.length == 0) {
            // Accept empty responses
            btHttpResponse = [[BTHTTPResponse alloc] initWithResponse:response data:[BTJSON empty]];
        } else if ([response.MIMEType isEqualToString:@"application/json"]) {
            // Attempt to parse json, and return an error if parsing fails
            BTJSON *responseObject = [BTJSON JSONWithData:data];
            if (responseObject.isError) {
                error = responseObject.asError;
            } else {
                btHttpResponse = [[BTHTTPResponse alloc] initWithResponse:response data:responseObject];
            }
        } else {
            // Return error for unsupported response type
            error = [NSError errorWithDomain:BraintreeErrorDomain
                                        code:BTUnrecoverableError
                                    userInfo:@{ NSLocalizedFailureReasonErrorKey: [NSString stringWithFormat:@"BTHTTP only supports application/json responses, received Content-Type: %@", response.MIMEType] }];
        }

        if (completionBlock) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completionBlock(btHttpResponse, error);
            });
        }
    }];
    [task resume];
}


#pragma mark - Default Headers

- (NSDictionary *)defaultHeaders {
    return @{ @"User-Agent": [self userAgentString],
              @"Accept": [self acceptString],
              @"Accept-Language": [self acceptLanguageString] };
}

- (NSString *)userAgentString {
    return [NSString stringWithFormat:@"Braintree/iOS/%@", [BTClient libraryVersion]];
}

- (NSString *)platformString {
    size_t size = 128;
    char *hwModel = alloca(size);

    if (sysctlbyname("hw.model", hwModel, &size, NULL, 0) != 0) {
        return nil;
    }

    NSString *hwModelString = [NSString stringWithCString:hwModel encoding:NSUTF8StringEncoding];
#if TARGET_IPHONE_SIMULATOR
    hwModelString = [hwModelString stringByAppendingString:@"(simulator)"];
#endif
    return hwModelString;
}

- (NSString *)architectureString {
    size_t size = 128;
    char *hwMachine = alloca(size);

    if (sysctlbyname("hw.machine", hwMachine, &size, NULL, 0) != 0) {
        return nil;
    }

    return [NSString stringWithCString:hwMachine encoding:NSUTF8StringEncoding];
}

- (NSString *)acceptString {
    return @"application/json";
}

- (NSString *)acceptLanguageString {
    NSLocale *locale = [NSLocale currentLocale];
    return [NSString stringWithFormat:@"%@-%@",
            [locale objectForKey:NSLocaleLanguageCode],
            [locale objectForKey:NSLocaleCountryCode]];
}

#pragma mark - Helpers

- (NSArray *)pinnedCertificateData {
    NSMutableArray *pinnedCertificates = [NSMutableArray array];
    for (NSData *certificateData in self.pinnedCertificates) {
        [pinnedCertificates addObject:(__bridge_transfer id)SecCertificateCreateWithData(NULL, (__bridge CFDataRef)certificateData)];
    }
    return pinnedCertificates;
}

- (void)URLSession:(__unused NSURLSession *)session didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition, NSURLCredential *))completionHandler {
    if ([[[challenge protectionSpace] authenticationMethod] isEqualToString:NSURLAuthenticationMethodServerTrust]) {
        NSString *domain = challenge.protectionSpace.host;
        SecTrustRef serverTrust = [[challenge protectionSpace] serverTrust];

        NSArray *policies = @[(__bridge_transfer id)SecPolicyCreateSSL(true, (__bridge CFStringRef)domain)];
        SecTrustSetPolicies(serverTrust, (__bridge CFArrayRef)policies);
        SecTrustSetAnchorCertificates(serverTrust, (__bridge CFArrayRef)self.pinnedCertificateData);
        SecTrustResultType result;

        OSStatus errorCode = SecTrustEvaluate(serverTrust, &result);

        BOOL evaluatesAsTrusted = (result == kSecTrustResultUnspecified || result == kSecTrustResultProceed);
        if (errorCode == errSecSuccess && evaluatesAsTrusted) {
            NSURLCredential *credential = [NSURLCredential credentialForTrust:serverTrust];
            completionHandler(NSURLSessionAuthChallengeUseCredential, credential);
        } else {
            completionHandler(NSURLSessionAuthChallengeRejectProtectionSpace, NULL);
        }
    } else {
        completionHandler(NSURLSessionAuthChallengePerformDefaultHandling, NULL);
    }
}

@end
