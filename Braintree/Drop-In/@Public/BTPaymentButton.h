@import UIKit;

#import "BTUIThemedView.h"

@class BTClient, BTPaymentMethod;
@protocol BTPaymentMethodCreationDelegate;

@interface BTPaymentButton : BTUIThemedView

- (instancetype)initWithClient:(BTClient *)client;
- (instancetype)initWithPaymentProviderTypes:(NSOrderedSet *)paymentAuthorizationTypes;
- (id)initWithFrame:(CGRect)frame;
- (id)initWithCoder:(NSCoder *)aDecoder;

@property (nonatomic, strong) NSOrderedSet *enabledPaymentProviderTypes;

@property (nonatomic, strong) BTClient *client;
@property (nonatomic, weak) id<BTPaymentMethodCreationDelegate> delegate;

@property (nonatomic, readonly) BOOL hasAvailablePaymentMethod;

@end
