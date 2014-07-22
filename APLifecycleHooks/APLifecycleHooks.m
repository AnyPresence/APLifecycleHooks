//
//  APLifecycleHooks.m
//  LoyaltyRtr
//
//  Created by David Benko on 7/22/14.
//  Copyright (c) 2014 David Benko. All rights reserved.
//

#import "APLifecycleHooks.h"
#import <APSDK/APRequest.h>

@interface APRequest (privateStuff)
@property (nonatomic, strong) NSURLConnection * connection;
@property (nonatomic, strong) APRequestCallback callback;
@property (nonatomic, strong) NSError * error;
@property (nonatomic, strong) NSMutableData * downloadedData;
-(void)reset;
@end

@implementation APLifecycleHooks
+(void)connectionFinished:(void (^)(NSMutableData *downloadedData, NSError *error))hook{
    Swizzlean *swizzle = [[Swizzlean alloc] initWithClassToSwizzle:[APRequest class]];
    swizzle.resetWhenDeallocated = NO;
    [swizzle swizzleInstanceMethod:@selector(connectionDidFinishLoading:) withReplacementImplementation:^(APRequest *_self, NSURLConnection *connection) {
        assert(connection == _self.connection);
#ifdef __VERBOSE
        NSLog(@"%@", [[NSString alloc] initWithData:self.downloadedData encoding:NSUTF8StringEncoding]);
#endif
        hook(_self.downloadedData, _self.error);
        _self.callback(_self.downloadedData, _self.error);
        [_self reset];
    }];
}
@end
