//
//  APLifecycleHooks.h
//  LoyaltyRtr
//
//  Created by David Benko on 7/22/14.
//  Copyright (c) 2014 David Benko. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface APLifecycleHooks : NSObject
+(void)setSDKLogging:(BOOL)shouldLog;
+(void)synchronousConnectionFinished:(void (^)(NSData *downloadedData, NSError *error))hook;
+(void)asyncConnectionStarted:(void (^)(NSURLRequest * req, NSURLConnection *conn))hook;
+(void)asyncConnectionFinished:(BOOL (^)(NSMutableData *downloadedData, NSError *error))hook;
@end
