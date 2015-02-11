//
//  APLifecycleHooks.h
//  LoyaltyRtr
//
//  Created by David Benko on 7/22/14.
//  Copyright (c) 2014 David Benko. All rights reserved.
//

#import <Foundation/Foundation.h>

#define __VERBOSE

@interface APLifecycleHooks : NSObject

+ (void)connectionWillStart:(NSURLRequest * (^)(NSURLRequest * req))connectionWillStartCallback didStart:(void (^)(NSURLRequest * req, NSURLConnection *conn))connectionDidStartCallback;
+ (void)connectionReceievedResponse:(void (^)(NSURLConnection *connection, NSURLResponse *response))connectionReceievedResponseCallback;
+ (void)checkConnectionResponse:(BOOL (^)(NSURLResponse *response, NSError **error))checkConnectionResponseCallback;
+ (void)connectionFinished:(BOOL (^)(NSURLResponse *response, NSMutableData *downloadedData, NSError *error))connectionDidFinishCallback;
@end
