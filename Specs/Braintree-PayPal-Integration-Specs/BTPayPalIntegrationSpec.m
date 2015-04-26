SpecBegin(BTPayPal_Integration)

it(@"is untested", ^{
    XCTFail(@"write tests for BTPayPal");
});

describe(@"PayPal One Touch Core", ^{
    describe(@"future payments", ^{
        describe(@"performing app switches", ^{
            it(@"performs an app switch to PayPal when the PayPal app is installed", ^{
            });

            it(@"performs an app switch to Safari when the PayPal app is not installed", ^{
            });

            it(@"notifies the delegate when an app switch will take place", ^{
            });

            it(@"fails to switch if the returnUrlScheme is not valid, returning the error to the delegate", ^{
            });

            xdescribe(@"scopes", ^{
                it(@"includes email and future payments", ^{
                    NSString *clientTokenString = clientTokenStringFromNSDictionary(mutableClaims);
                    BTClient *client = [[BTClient alloc] initWithClientToken:clientTokenString];
                    
                    NSSet *scopes = [client btPayPal_scopes];
                    expect(scopes).to.contain(kPayPalOAuth2ScopeEmail);
                    expect(scopes).to.contain(kPayPalOAuth2ScopeFuturePayments);
                });
            });

            describe(@"analytics", ^{
                it(@"posts an analytics event for a successful app switch to the PayPal app", ^{
                });

                it(@"posts an analytics event for a successful app switch to the Browser", ^{
                });

                it(@"posts an analytics event for a failed app switch", ^{
                });

                it(@"posts analytics events when preflight checks fail", ^{
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

            describe(@"analytics", ^{
                it(@"post an analytics event to indicate a successful returns", ^{
                });

                it(@"post an analytics event to indicate a failure returns", ^{
                });

                it(@"post an analytics event to indicate a cancelation return", ^{
                });

                it(@"posts an anlaytics event to indicate tokenization success", ^{
                });

                it(@"posts an anlaytics event to indicate tokenization failure", ^{
                });
            });
        });

        describe(@"checking if app switch is available", ^{
        });
    });
});

SpecEnd
