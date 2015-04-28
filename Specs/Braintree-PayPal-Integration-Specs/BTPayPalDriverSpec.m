#import "BTPayPalDriver.h"

#import "BTClient_Internal.h"
#import "PayPalOneTouchCore.h"
#import "PayPalOneTouchRequest.h"
#import "BTAppSwitchErrors.h"

@interface BTPayPalDriverSpecHelper : NSObject
@end

@implementation BTPayPalDriverSpecHelper

+ (void)setupSpec:(void (^)(NSString *returnURLScheme, id mockClient, id mockApplication))setupBlock {
    id clientToken = [OCMockObject mockForClass:[BTClientToken class]];
    [[[clientToken stub] andReturnValue:@YES] payPalEnabled];
    [[[clientToken stub] andReturn:[NSURL URLWithString:@"https://example.com/privacy"]] btPayPal_privacyPolicyURL];
    [[[clientToken stub] andReturn:[NSURL URLWithString:@"https://example.com/tos"]] btPayPal_merchantUserAgreementURL];
    [[[clientToken stub] andReturn:@"offline"] payPalEnvironment];
    [[[clientToken stub] andReturn:@"client-id"] payPalClientId];
    [[[clientToken stub] andReturn:@"client-token"] originalClientTokenString];

    id client = [OCMockObject mockForClass:[BTClient class]];
    [[[client stub] andReturn:client] copyWithMetadata:OCMOCK_ANY];
    [[[client stub] andReturn:clientToken] clientToken];

    NSString *returnURLScheme = @"com.braintreepayments.Braintree-Demo.payments";

    id bundle = [OCMockObject partialMockForObject:[NSBundle mainBundle]];
    [[[bundle stub] andReturn:@[@{ @"CFBundleURLSchemes": @[returnURLScheme] }]] objectForInfoDictionaryKey:@"CFBundleURLTypes"];

    id application = [OCMockObject partialMockForObject:[UIApplication sharedApplication]];
    [[[application stub] andReturnValue:@YES] canOpenURL:HC_hasProperty(@"scheme", returnURLScheme)];

    setupBlock(returnURLScheme, client, application);
}

@end

SpecBegin(BTPayPalDriver)

describe(@"PayPal One Touch Core", ^{
    describe(@"future payments", ^{
        describe(@"performing app switches", ^{
            it(@"performs an app switch to PayPal when the PayPal app is installed", ^{
                [BTPayPalDriverSpecHelper setupSpec:^(NSString *returnURLScheme, id mockClient, id mockApplication){
                    [[mockClient stub] postAnalyticsEvent:OCMOCK_ANY];

                    XCTestExpectation *appSwitchExpectation = [self expectationWithDescription:@"Perform App Switch"];
                    [[[mockApplication stub] andReturnValue:@YES] canOpenURL:HC_hasProperty(@"scheme", HC_startsWith(@"com.paypal"))];
                    [[[[mockApplication expect] andReturnValue:@YES] andDo:^(__unused NSInvocation *invocation) {
                        [appSwitchExpectation fulfill];
                    }] openURL:HC_hasProperty(@"scheme", HC_startsWith(@"com.paypal"))];

                    BTPayPalDriver *payPalDriver = [[BTPayPalDriver alloc] initWithClient:mockClient returnURLScheme:returnURLScheme];

                    [payPalDriver startAuthorizationWithCompletion:nil];
                    [self waitForExpectationsWithTimeout:10 handler:nil];

                    [mockApplication verify];
                }];
            });

            it(@"performs an app switch to Safari when the PayPal app is not installed", ^{
                [BTPayPalDriverSpecHelper setupSpec:^(NSString *returnURLScheme, id mockClient, id mockApplication){
                    [[mockClient stub] postAnalyticsEvent:OCMOCK_ANY];
                    XCTestExpectation *appSwitchExpectation = [self expectationWithDescription:@"Perform App Switch"];

                    [[[mockApplication stub] andReturnValue:@NO] canOpenURL:HC_hasProperty(@"scheme", HC_startsWith(@"com.paypal"))];

                    [[[mockApplication stub] andReturnValue:@YES] canOpenURL:HC_hasProperty(@"scheme", @"https")];
                    [[[[mockApplication expect] andReturnValue:@YES] andDo:^(NSInvocation *invocation) {
                        [appSwitchExpectation fulfill];
                    }] openURL:HC_hasProperty(@"scheme", @"https")];

                    BTPayPalDriver *payPalDriver = [[BTPayPalDriver alloc] initWithClient:mockClient returnURLScheme:returnURLScheme];

                    [payPalDriver startAuthorizationWithCompletion:nil];
                    [self waitForExpectationsWithTimeout:10 handler:nil];

                    [mockApplication verify];
                }];
            });

            it(@"fails to initialize if the returnURLScheme is not valid", ^{
                [BTPayPalDriverSpecHelper setupSpec:^(NSString *returnURLScheme, id mockClient, id mockApplication){
                    [[mockClient stub] postAnalyticsEvent:OCMOCK_ANY];

                    BTPayPalDriver *payPalDriver = [[BTPayPalDriver alloc] initWithClient:mockClient returnURLScheme:@"invalid-return-url-scheme"];

                    expect(payPalDriver).to.beNil();
                }];
            });
        });

        describe(@"handling app switch returns", ^{
            it(@"receives a payment method on app switch return success", ^{
                [BTPayPalDriverSpecHelper setupSpec:^(NSString *returnURLScheme, id mockClient, id mockApplication){
                    [[mockClient stub] postAnalyticsEvent:OCMOCK_ANY];

                    BTPaymentMethod *fakePaymentMethod = [OCMockObject mockForClass:[BTPaymentMethod class]];
                    NSURL *fakeReturnURL = [OCMockObject mockForClass:[NSURL class]];

                    [[[mockClient expect] andDo:^(NSInvocation *invocation) {
                        void (^successBlock)(BTPaymentMethod *paymentMethod);
                        [invocation getArgument:&successBlock atIndex:4];
                        successBlock(fakePaymentMethod);
                    }] savePaypalAccount:OCMOCK_ANY applicationCorrelationID:OCMOCK_ANY success:OCMOCK_ANY failure:OCMOCK_ANY];

                    [[[mockApplication stub] andReturnValue:@YES] canOpenURL:OCMOCK_ANY];
                    [[[mockApplication stub] andReturnValue:@YES] openURL:OCMOCK_ANY];

                    id mockOTC = [OCMockObject mockForClass:[PayPalOneTouchCore class]];
                    [[[[mockOTC expect] classMethod] andDo:^(NSInvocation *invocation) {
                        void (^stubOTCCompletionBlock)(PayPalOneTouchCoreResult *result);
                        [invocation getArgument:&stubOTCCompletionBlock atIndex:3];
                        id result = [OCMockObject mockForClass:[PayPalOneTouchCoreResult class]];
                        [(PayPalOneTouchCoreResult *)[[result stub] andReturnValue:OCMOCK_VALUE(PayPalOneTouchResultTypeSuccess)] type];
                        [(PayPalOneTouchCoreResult *)[result stub] target];
                        [(PayPalOneTouchCoreResult *)[result stub] response];
                        stubOTCCompletionBlock(result);
                    }] parseResponseURL:fakeReturnURL completionBlock:[OCMArg isNotNil]];

                    BTPayPalDriver *payPalDriver = [[BTPayPalDriver alloc] initWithClient:mockClient returnURLScheme:returnURLScheme];

                    XCTestExpectation *completionExpectation = [self expectationWithDescription:@"Received call to completion block"];
                    [payPalDriver startAuthorizationWithCompletion:^void(BTPayPalPaymentMethod *paymentMethod, NSError *error) {
                        expect(paymentMethod).to.equal(fakePaymentMethod);
                        expect(error).to.beNil();
                        [completionExpectation fulfill];
                    }];

                    [BTPayPalDriver handleAppSwitchReturnURL:fakeReturnURL];
                    [self waitForExpectationsWithTimeout:10 handler:nil];

                    [mockClient verify];
                    [mockOTC verify];
                }];
            });

            it(@"receives the error passed through directly on failure", ^{
                [BTPayPalDriverSpecHelper setupSpec:^(NSString *returnURLScheme, id mockClient, id mockApplication){
                    [[mockClient stub] postAnalyticsEvent:OCMOCK_ANY];

                    NSError *fakeError = [OCMockObject mockForClass:[NSError class]];
                    NSURL *fakeReturnURL = [OCMockObject mockForClass:[NSURL class]];

                    [[[mockApplication stub] andReturnValue:@YES] canOpenURL:OCMOCK_ANY];
                    [[[mockApplication stub] andReturnValue:@YES] openURL:OCMOCK_ANY];

                    id mockOTC = [OCMockObject mockForClass:[PayPalOneTouchCore class]];
                    [[[[mockOTC expect] classMethod] andDo:^(NSInvocation *invocation) {
                        void (^stubOTCCompletionBlock)(PayPalOneTouchCoreResult *result);
                        [invocation getArgument:&stubOTCCompletionBlock atIndex:3];
                        id result = [OCMockObject mockForClass:[PayPalOneTouchCoreResult class]];
                        [(PayPalOneTouchCoreResult *)[[result stub] andReturnValue:OCMOCK_VALUE(PayPalOneTouchResultTypeError)] type];
                        [(PayPalOneTouchCoreResult *)[result stub] target];
                        [(PayPalOneTouchCoreResult *)[[result stub] andReturn:fakeError] error];
                        stubOTCCompletionBlock(result);
                    }] parseResponseURL:fakeReturnURL completionBlock:[OCMArg isNotNil]];

                    BTPayPalDriver *payPalDriver = [[BTPayPalDriver alloc] initWithClient:mockClient returnURLScheme:returnURLScheme];

                    XCTestExpectation *completionExpectation = [self expectationWithDescription:@"Received call to completion block"];
                    [payPalDriver startAuthorizationWithCompletion:^void(BTPayPalPaymentMethod *paymentMethod, NSError *error) {
                        expect(paymentMethod).to.beNil();
                        expect(error).to.equal(fakeError);
                        [completionExpectation fulfill];
                    }];

                    [BTPayPalDriver handleAppSwitchReturnURL:fakeReturnURL];
                    [self waitForExpectationsWithTimeout:10 handler:nil];

                    [mockClient verify];
                    [mockOTC verify];
                }];
            });

            it(@"receives neither a payment method nor an error on cancelation", ^{
                [BTPayPalDriverSpecHelper setupSpec:^(NSString *returnURLScheme, id mockClient, id mockApplication){
                    [[mockClient stub] postAnalyticsEvent:OCMOCK_ANY];

                    NSURL *fakeReturnURL = [OCMockObject mockForClass:[NSURL class]];

                    [[[mockApplication stub] andReturnValue:@YES] canOpenURL:OCMOCK_ANY];
                    [[[mockApplication stub] andReturnValue:@YES] openURL:OCMOCK_ANY];

                    id mockOTC = [OCMockObject mockForClass:[PayPalOneTouchCore class]];
                    [[[[mockOTC expect] classMethod] andDo:^(NSInvocation *invocation) {
                        void (^stubOTCCompletionBlock)(PayPalOneTouchCoreResult *result);
                        [invocation getArgument:&stubOTCCompletionBlock atIndex:3];
                        id result = [OCMockObject mockForClass:[PayPalOneTouchCoreResult class]];
                        [(PayPalOneTouchCoreResult *)[[result stub] andReturnValue:OCMOCK_VALUE(PayPalOneTouchResultTypeCancel)] type];
                        [(PayPalOneTouchCoreResult *)[result stub] target];
                        [(PayPalOneTouchCoreResult *)[result stub] error];
                        stubOTCCompletionBlock(result);
                    }] parseResponseURL:fakeReturnURL completionBlock:[OCMArg isNotNil]];

                    BTPayPalDriver *payPalDriver = [[BTPayPalDriver alloc] initWithClient:mockClient returnURLScheme:returnURLScheme];

                    XCTestExpectation *completionExpectation = [self expectationWithDescription:@"Received call to completion block"];
                    [payPalDriver startAuthorizationWithCompletion:^void(BTPayPalPaymentMethod *paymentMethod, NSError *error) {
                        expect(paymentMethod).to.beNil();
                        expect(error).to.beNil();
                        [completionExpectation fulfill];
                    }];

                    [BTPayPalDriver handleAppSwitchReturnURL:fakeReturnURL];
                    [self waitForExpectationsWithTimeout:10 handler:nil];

                    [mockClient verify];
                    [mockOTC verify];
                }];
            });
        });

        describe(@"scopes", ^{
            it(@"includes email and future payments", ^{
                [BTPayPalDriverSpecHelper setupSpec:^(NSString *returnURLScheme, id mockClient, id mockApplication){
                    [[mockClient stub] postAnalyticsEvent:OCMOCK_ANY];

                    XCTestExpectation *appSwitchExpectation = [self expectationWithDescription:@"opened URL"];
                    [[[[mockApplication expect] andReturnValue:@YES] andDo:^(NSInvocation *invocation) {
                        [appSwitchExpectation fulfill];
                    }] openURL:HC_hasProperty(@"scheme", @"https")];

                    id otcStub = [OCMockObject mockForClass:[PayPalOneTouchAuthorizationRequest class]];
                    [[[[otcStub expect] classMethod] andForwardToRealObject] requestWithScopeValues:HC_containsInAnyOrder(@"email", @"https://uri.paypal.com/services/payments/futurepayments", nil)
                                                                                         privacyURL:OCMOCK_ANY
                                                                                       agreementURL:OCMOCK_ANY
                                                                                           clientID:OCMOCK_ANY
                                                                                        environment:OCMOCK_ANY
                                                                                  callbackURLScheme:OCMOCK_ANY];

                    BTPayPalDriver *payPalDriver = [[BTPayPalDriver alloc] initWithClient:mockClient returnURLScheme:returnURLScheme];
                    [payPalDriver startAuthorizationWithCompletion:nil];

                    [self waitForExpectationsWithTimeout:10 handler:nil];

                    [otcStub verify];
                }];
            });
        });

        describe(@"analytics", ^{
            it(@"posts an analytics event for a successful app switch to the PayPal app", ^{
                [BTPayPalDriverSpecHelper setupSpec:^(NSString *returnURLScheme, id mockClient, id mockApplication){
                    XCTestExpectation *appSwitchExpectation = [self expectationWithDescription:@"Perform App Switch"];
                    [[[mockApplication stub] andReturnValue:@YES] canOpenURL:HC_hasProperty(@"scheme", HC_startsWith(@"com.paypal"))];
                    [[[[mockApplication expect] andReturnValue:@YES] andDo:^(__unused NSInvocation *invocation) {
                        [appSwitchExpectation fulfill];
                    }] openURL:HC_hasProperty(@"scheme", HC_startsWith(@"com.paypal"))];

                    BTPayPalDriver *payPalDriver = [[BTPayPalDriver alloc] initWithClient:mockClient returnURLScheme:returnURLScheme];

                    [[mockClient expect] postAnalyticsEvent:@"ios.paypal-otc.appswitch.initiate.started"];

                    [payPalDriver startAuthorizationWithCompletion:nil];
                    [self waitForExpectationsWithTimeout:10 handler:nil];

                    [mockClient verify];
                }];
            });

            it(@"posts an analytics event for a successful app switch to the Browser", ^{
                [BTPayPalDriverSpecHelper setupSpec:^(NSString *returnURLScheme, id mockClient, id mockApplication){
                    XCTestExpectation *appSwitchExpectation = [self expectationWithDescription:@"Perform App Switch"];
                    [[[mockApplication stub] andReturnValue:@NO] canOpenURL:HC_hasProperty(@"scheme", HC_startsWith(@"com.paypal"))];
                    [[[mockApplication stub] andReturnValue:@YES] canOpenURL:HC_hasProperty(@"scheme", @"https")];
                    [[[[mockApplication expect] andReturnValue:@YES] andDo:^(__unused NSInvocation *invocation) {
                        [appSwitchExpectation fulfill];
                    }] openURL:HC_hasProperty(@"scheme", @"https")];

                    BTPayPalDriver *payPalDriver = [[BTPayPalDriver alloc] initWithClient:mockClient returnURLScheme:returnURLScheme];

                    [[mockClient expect] postAnalyticsEvent:@"ios.paypal-otc.webswitch.initiate.started"];

                    [payPalDriver startAuthorizationWithCompletion:nil];
                    [self waitForExpectationsWithTimeout:10 handler:nil];

                    [mockClient verify];
                }];
            });

            it(@"posts an analytics event for a failed app switch", ^{
                [BTPayPalDriverSpecHelper setupSpec:^(NSString *returnURLScheme, id mockClient, id mockApplication){
                    XCTestExpectation *appSwitchExpectation = [self expectationWithDescription:@"Perform App Switch"];
                    [[[mockApplication stub] andReturnValue:@NO] canOpenURL:HC_hasProperty(@"scheme", HC_startsWith(@"com.paypal"))];
                    [[[mockApplication stub] andReturnValue:@YES] canOpenURL:HC_hasProperty(@"scheme", @"https")];
                    [[[[mockApplication expect] andReturnValue:@YES] andDo:^(__unused NSInvocation *invocation) {
                        [appSwitchExpectation fulfill];
                    }] openURL:HC_hasProperty(@"scheme", @"https")];

                    BTPayPalDriver *payPalDriver = [[BTPayPalDriver alloc] initWithClient:mockClient returnURLScheme:returnURLScheme];

                    [[mockClient expect] postAnalyticsEvent:@"ios.paypal-otc.webswitch.initiate.started"];

                    [payPalDriver startAuthorizationWithCompletion:nil];
                    [self waitForExpectationsWithTimeout:10 handler:nil];

                    [mockClient verify];
                }];
            });

            it(@"posts analytics events when preflight checks fail", ^{
                [BTPayPalDriverSpecHelper setupSpec:^(NSString *returnURLScheme, id mockClient, id mockApplication){
                    [[mockClient expect] postAnalyticsEvent:@"ios.paypal-otc.preflight.invalid-return-url-scheme"];

                    BTPayPalDriver *payPalDriver = [[BTPayPalDriver alloc] initWithClient:mockClient returnURLScheme:@"invalid-return-url-scheme"];
                    expect(payPalDriver).to.beNil();

                    [mockClient verify];
                }];
            });

            it(@"post an analytics event to indicate handling the one touch core response ", ^{
                [BTPayPalDriverSpecHelper setupSpec:^(NSString *returnURLScheme, id mockClient, id mockApplication){
                    NSURL *fakeReturnURL = [OCMockObject mockForClass:[NSURL class]];

                    [[[mockApplication stub] andReturnValue:@YES] canOpenURL:OCMOCK_ANY];
                    [[[mockApplication stub] andReturnValue:@YES] openURL:OCMOCK_ANY];

                    id mockOTC = [OCMockObject mockForClass:[PayPalOneTouchCore class]];
                    [[[[mockOTC stub] classMethod] andDo:^(NSInvocation *invocation) {
                        void (^stubOTCCompletionBlock)(PayPalOneTouchCoreResult *result);
                        [invocation getArgument:&stubOTCCompletionBlock atIndex:3];
                        id result = [OCMockObject mockForClass:[PayPalOneTouchCoreResult class]];
                        [(PayPalOneTouchCoreResult *)[[result stub] andReturnValue:OCMOCK_VALUE(PayPalOneTouchResultTypeCancel)] type];
                        [(PayPalOneTouchCoreResult *)[result stub] target];
                        [(PayPalOneTouchCoreResult *)[result stub] error];
                        stubOTCCompletionBlock(result);
                    }] parseResponseURL:fakeReturnURL completionBlock:[OCMArg isNotNil]];

                    BTPayPalDriver *payPalDriver = [[BTPayPalDriver alloc] initWithClient:mockClient returnURLScheme:returnURLScheme];

                    [[mockClient expect] postAnalyticsEvent:@"ios.paypal-otc.unknown.canceled"];
                    [[mockClient stub] postAnalyticsEvent:OCMOCK_ANY];

                    XCTestExpectation *completionExpectation = [self expectationWithDescription:@"Received call to completion block"];
                    [payPalDriver startAuthorizationWithCompletion:^void(BTPayPalPaymentMethod *paymentMethod, NSError *error) {
                        [completionExpectation fulfill];
                    }];

                    [BTPayPalDriver handleAppSwitchReturnURL:fakeReturnURL];
                    [self waitForExpectationsWithTimeout:10 handler:nil];

                    [mockClient verify];
                }];
            });

            it(@"posts an anlaytics event to indicate tokenization success", ^{
                [BTPayPalDriverSpecHelper setupSpec:^(NSString *returnURLScheme, id mockClient, id mockApplication){
                    NSURL *fakeReturnURL = [OCMockObject mockForClass:[NSURL class]];

                    [[[mockClient stub] andDo:^(NSInvocation *invocation) {
                        void (^successBlock)(BTPaymentMethod *paymentMethod);
                        [invocation getArgument:&successBlock atIndex:4];
                        successBlock(nil);
                    }] savePaypalAccount:OCMOCK_ANY applicationCorrelationID:OCMOCK_ANY success:OCMOCK_ANY failure:OCMOCK_ANY];

                    [[[mockApplication stub] andReturnValue:@YES] canOpenURL:OCMOCK_ANY];
                    [[[mockApplication stub] andReturnValue:@YES] openURL:OCMOCK_ANY];

                    id mockOTC = [OCMockObject mockForClass:[PayPalOneTouchCore class]];
                    [[[[mockOTC stub] classMethod] andDo:^(NSInvocation *invocation) {
                        void (^stubOTCCompletionBlock)(PayPalOneTouchCoreResult *result);
                        [invocation getArgument:&stubOTCCompletionBlock atIndex:3];
                        id result = [OCMockObject mockForClass:[PayPalOneTouchCoreResult class]];
                        [(PayPalOneTouchCoreResult *)[[result stub] andReturnValue:OCMOCK_VALUE(PayPalOneTouchResultTypeSuccess)] type];
                        [(PayPalOneTouchCoreResult *)[result stub] target];
                        [(PayPalOneTouchCoreResult *)[result stub] response];
                        stubOTCCompletionBlock(result);
                    }] parseResponseURL:fakeReturnURL completionBlock:[OCMArg isNotNil]];

                    BTPayPalDriver *payPalDriver = [[BTPayPalDriver alloc] initWithClient:mockClient returnURLScheme:returnURLScheme];

                    [[mockClient expect] postAnalyticsEvent:@"ios.paypal-otc.tokenize.succeeded"];
                    [[mockClient stub] postAnalyticsEvent:OCMOCK_ANY];

                    XCTestExpectation *completionExpectation = [self expectationWithDescription:@"Received call to completion block"];
                    [payPalDriver startAuthorizationWithCompletion:^void(BTPayPalPaymentMethod *paymentMethod, NSError *error) {
                        [completionExpectation fulfill];
                    }];

                    [BTPayPalDriver handleAppSwitchReturnURL:fakeReturnURL];
                    [self waitForExpectationsWithTimeout:10 handler:nil];

                    [mockClient verify];
                }];
            });

            it(@"posts an anlaytics event to indicate tokenization failure", ^{
                [BTPayPalDriverSpecHelper setupSpec:^(NSString *returnURLScheme, id mockClient, id mockApplication){
                    NSURL *fakeReturnURL = [OCMockObject mockForClass:[NSURL class]];

                    [[[mockClient stub] andDo:^(NSInvocation *invocation) {
                        void (^failureBlock)(BTPaymentMethod *paymentMethod);
                        [invocation getArgument:&failureBlock atIndex:5];
                        failureBlock(nil);
                    }] savePaypalAccount:OCMOCK_ANY applicationCorrelationID:OCMOCK_ANY success:OCMOCK_ANY failure:OCMOCK_ANY];

                    [[[mockApplication stub] andReturnValue:@YES] canOpenURL:OCMOCK_ANY];
                    [[[mockApplication stub] andReturnValue:@YES] openURL:OCMOCK_ANY];

                    id mockOTC = [OCMockObject mockForClass:[PayPalOneTouchCore class]];
                    [[[[mockOTC stub] classMethod] andDo:^(NSInvocation *invocation) {
                        void (^stubOTCCompletionBlock)(PayPalOneTouchCoreResult *result);
                        [invocation getArgument:&stubOTCCompletionBlock atIndex:3];
                        id result = [OCMockObject mockForClass:[PayPalOneTouchCoreResult class]];
                        [(PayPalOneTouchCoreResult *)[[result stub] andReturnValue:OCMOCK_VALUE(PayPalOneTouchResultTypeSuccess)] type];
                        [(PayPalOneTouchCoreResult *)[result stub] target];
                        [(PayPalOneTouchCoreResult *)[result stub] response];
                        stubOTCCompletionBlock(result);
                    }] parseResponseURL:fakeReturnURL completionBlock:[OCMArg isNotNil]];

                    BTPayPalDriver *payPalDriver = [[BTPayPalDriver alloc] initWithClient:mockClient returnURLScheme:returnURLScheme];

                    [[mockClient expect] postAnalyticsEvent:@"ios.paypal-otc.tokenize.failed"];
                    [[mockClient stub] postAnalyticsEvent:OCMOCK_ANY];

                    XCTestExpectation *completionExpectation = [self expectationWithDescription:@"Received call to completion block"];
                    [payPalDriver startAuthorizationWithCompletion:^void(BTPayPalPaymentMethod *paymentMethod, NSError *error) {
                        [completionExpectation fulfill];
                    }];

                    [BTPayPalDriver handleAppSwitchReturnURL:fakeReturnURL];
                    [self waitForExpectationsWithTimeout:10 handler:nil];

                    [mockClient verify];
                }];
            });
        });

        describe(@"delegate notifications", ^{
        });

        describe(@"isAvailable", ^{
            it(@"returns YES when PayPal is enabled in configuration and One Touch Core is ready", ^{
            });

            it(@"returns NO when PayPal is not enabled in configuration", ^{
            });

            it(@"returns NO when the URL scheme has not been setup", ^{
            });

            it(@"returns NO when the return URL scheme has not been registered", ^{
            });
        });

    });

    describe(@"classifying app switch returns", ^{
        it(@"accepts return URLs from the browser", ^{
        });

        it(@"accepts return URLs from the app", ^{
        });

        it(@"rejects other return URLs", ^{
        });

        it(@"rejects other malformed URLs", ^{
        });

        it(@"rejects returns when there is no app switch in progress", ^{
        });

        it(@"rejects URLs when no app switch has taken place", ^{
        });

        it(@"ignores the case of the URL Scheme to account for Safari's habit of downcasing URL schemes", ^{
        });
    });

    describe(@"handling app switch returns", ^{
        it(@"ignores an irrelevant or malformed URL", ^{
        });

        it(@"accepts a success app switch return", ^{
        });

        it(@"accepts a failure app switch return", ^{
        });

        it(@"accepts a cancelation app switch return", ^{
        });

        it(@"tokenizes a success response, returning the payment method nonce to the developer", ^{
        });

        it(@"returns tokenization failures to the developer", ^{
        });

        it(@"returns a failure to the developer", ^{
        });

        it(@"returns a cancelation to the developer", ^{
        });
        
        it(@"rejects returns when there is no app switch in progress", ^{
        });
    });
});

SpecEnd
