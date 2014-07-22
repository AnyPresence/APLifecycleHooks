//
//  APLifecycleHooks.m
//  LoyaltyRtr
//
//  Created by David Benko on 7/22/14.
//  Copyright (c) 2014 David Benko. All rights reserved.
//

#import "APLifecycleHooks.h"
#import "Swizzlean.h"
#import <APSDK/APRequest.h>

@interface APRequest (APLifecycleHooks)
@property (nonatomic, strong) NSString * verb;
@property (nonatomic, strong) NSURL * URL;
@property (nonatomic, strong) NSData * data;
@property (nonatomic, strong) NSString * contentType;
@property (nonatomic, strong) NSURLConnection * connection;
@property (nonatomic, strong) APRequestCallback callback;
@property (nonatomic, strong) NSError * error;
@property (nonatomic, strong) NSMutableData * downloadedData;
-(void)reset;
- (NSURLRequest *)request:(NSString *)verb to:(NSURL *)URL body:(NSData *)body contentType:(NSString *)type;
- (void)checkResponse:(NSURLResponse *)response error:(NSError **)error;
@end

@implementation APLifecycleHooks

static bool sdkShouldLog;

+ (void)initialize
{
    static BOOL initialized = NO;
    if(!initialized)
    {
        initialized = YES;
        sdkShouldLog = true;
    }
}

+(void)setSDKLogging:(BOOL)shouldLog{
    sdkShouldLog = shouldLog;
}

+(void)synchronousConnectionFinished:(void (^)(NSData *downloadedData, NSError *error))hook{
    Swizzlean *swizzle = [[Swizzlean alloc] initWithClassToSwizzle:[APRequest class]];
    swizzle.resetWhenDeallocated = NO;
    [swizzle swizzleInstanceMethod:@selector(load:) withReplacementImplementation:^NSData* (APRequest *_self, NSError ** error){
        NSURLRequest * request = [_self request:_self.verb to:_self.URL body:_self.data contentType:_self.contentType];
        
        if (sdkShouldLog){
            NSLog(@"\n%@ %@\n%@", _self.verb, [_self.URL absoluteString], [[NSString alloc] initWithData:_self.data encoding:NSUTF8StringEncoding]);
        }
        
        NSHTTPURLResponse * response;
        NSData * data = [NSURLConnection sendSynchronousRequest:request
                                              returningResponse:&response
                                                          error:error];
        
        if (sdkShouldLog) {
            NSLog(@"%@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
        }
        
        [_self checkResponse:response error:error];
        if (error && *error) {
            [[NSNotificationCenter defaultCenter] postNotificationName:kAPRequestErrorNotification
                                                                object:@{ kAPRequestErrorNotificationErrorKey: *error }];
        }
        if (hook) {
            hook(data, *error);
        }
        return data;
    }];
}

+(void)asyncConnectionStarted:(void (^)(NSURLRequest * req, NSURLConnection *conn))hook{
    Swizzlean *swizzle = [[Swizzlean alloc] initWithClassToSwizzle:[APRequest class]];
    swizzle.resetWhenDeallocated = NO;
    [swizzle swizzleInstanceMethod:@selector(loadAsync:) withReplacementImplementation:^(APRequest *_self, APRequestCallback callback){
        if (_self.connection) {
            @throw [NSException exceptionWithName:kAPRequestConcurrentRequestException
                                           reason:@"Concurrent asynchronous requests not supported"
                                         userInfo:nil];
        }
        
        NSURLRequest * request = [_self request:_self.verb to:_self.URL body:_self.data contentType:_self.contentType];
        
        [_self reset];
        _self.connection = [[NSURLConnection alloc] initWithRequest:request
                                                          delegate:_self
                                                  startImmediately:NO];
        _self.downloadedData = [NSMutableData new];
        _self.callback = callback;
        
        if (sdkShouldLog) {
            NSLog(@"\n%@ %@\n%@", _self.verb, [_self.URL absoluteString], [[NSString alloc] initWithData:_self.data encoding:NSUTF8StringEncoding]);
        }
        
        [_self.connection start];
        
        if (hook){
            hook(request,_self.connection);
        }
        
    }];
}

+(void)asyncConnectionFinished:(BOOL (^)(NSMutableData *downloadedData, NSError *error))hook{
    Swizzlean *swizzle = [[Swizzlean alloc] initWithClassToSwizzle:[APRequest class]];
    swizzle.resetWhenDeallocated = NO;
    [swizzle swizzleInstanceMethod:@selector(connectionDidFinishLoading:) withReplacementImplementation:^(APRequest *_self, NSURLConnection *connection) {
        assert(connection == _self.connection);
        
        if (sdkShouldLog) {
            NSLog(@"%@", [[NSString alloc] initWithData:_self.downloadedData encoding:NSUTF8StringEncoding]);
        }
        
        BOOL shouldContinue = true;
        if (hook){
           shouldContinue = hook(_self.downloadedData, _self.error);
        }
        
        if (shouldContinue) {
            _self.callback(_self.downloadedData, _self.error);
        }
        
        [_self reset];
    }];
}
@end
