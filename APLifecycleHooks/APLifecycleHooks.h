//
//  APLifecycleHooks.h
//  LoyaltyRtr
//
//  Created by David Benko on 7/22/14.
//  Copyright (c) 2014 David Benko. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Swizzlean.h"

@interface APLifecycleHooks : NSObject
+(void)connectionFinished:(void (^)(NSMutableData *downloadedData, NSError *error))hook;
@end
