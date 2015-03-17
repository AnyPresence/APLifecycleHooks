//
//  APLifecycleHooks.m
//  LoyaltyRtr
//
//  Created by David Benko on 7/22/14.
//  Copyright (c) 2014 David Benko. All rights reserved.
//

#import "APLifecycleHooks.h"
#import "Swizzlean.h"
#import <objc/objc-runtime.h>
#import <APSDK/APRequest.h>

@interface NSString (Inflections)
- (NSString *)titleize;
@end

@interface APRequest (APLifecycleHooks)
@property (nonatomic, strong) NSString * verb;
@property (nonatomic, strong) NSData * data;
@property (nonatomic, strong) NSString * contentType;
@property (nonatomic, strong) NSURLConnection * connection;
@property (nonatomic, strong) APRequestCallback callback;
@property (nonatomic, strong) NSError * error;
@property (nonatomic, strong) NSMutableData * downloadedData;
@property (nonatomic, strong) NSURLResponse *response;


- (void)reset;
- (NSURLRequest *)request;
- (void)checkResponse:(NSURLResponse *)response error:(NSError **)error;
@end

#pragma clang diagnostic ignored "-Wincomplete-implementation"
@implementation APRequest (APLifecycleHooks)
@dynamic connection,
contentType,
data,
error,
callback,
URL,
verb,
downloadedData;

- (NSURLResponse *)response {
    return objc_getAssociatedObject(self, @selector(response));
}

- (void)setResponse:(NSURLResponse *)response {
    objc_setAssociatedObject(self, @selector(response), response, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}


@end

@implementation APLifecycleHooks

+ (void)initialize {
    if (self == [APLifecycleHooks class]) {
        [self connectionReceievedResponse:nil];
    }
}

+ (void)connectionWillStart:(NSURLRequest * (^)(NSURLRequest * req))connectionWillStartCallback didStart:(void (^)(NSURLRequest * req, NSURLConnection *conn))connectionDidStartCallback{
    Swizzlean *swizzle = [[Swizzlean alloc] initWithClassToSwizzle:[APRequest class]];
    swizzle.resetWhenDeallocated = NO;
    [swizzle swizzleInstanceMethod:@selector(loadAsync:) withReplacementImplementation:^(APRequest *_self, APRequestCallback callback){

        if (_self.connection) {
            @throw [NSException exceptionWithName:kAPRequestConcurrentRequestException
                                           reason:@"Concurrent asynchronous requests not supported"
                                         userInfo:nil];
        }

        NSURLRequest * request = [_self request];


        // Hijack Request Here
        if (connectionWillStartCallback) {
            request = connectionWillStartCallback(request);
        }

        [_self reset];

        _self.connection = [[NSURLConnection alloc] initWithRequest:request
                                                          delegate:_self
                                                  startImmediately:NO];

        _self.downloadedData = [NSMutableData new];
        _self.callback = callback;


#ifdef __VERBOSE
        NSLog(@"\n%@ %@\n%@\n%@", [request HTTPMethod], [[request URL] absoluteString], [request allHTTPHeaderFields], [[NSString alloc] initWithData:_self.data encoding:NSUTF8StringEncoding]);
#endif

        [_self.connection start];

        if (connectionDidStartCallback) {
            connectionDidStartCallback(request,_self.connection);
        }

    }];
}

+ (void)connectionReceievedResponse:(void (^)(NSURLConnection *connection, NSURLResponse *response))connectionReceievedResponseCallback{
    Swizzlean *swizzle = [[Swizzlean alloc] initWithClassToSwizzle:[APRequest class]];
    swizzle.resetWhenDeallocated = NO;
    [swizzle swizzleInstanceMethod:@selector(connection:didReceiveResponse:) withReplacementImplementation:^(APRequest *_self, NSURLConnection *connection, NSURLResponse *response){
        assert(connection = _self.connection);

        [_self setResponse: response];

#ifdef __VERBOSE
        if ([response isKindOfClass:[NSHTTPURLResponse class]])
            NSLog(@"%ld", (long)((NSHTTPURLResponse *)response).statusCode);
#endif

        NSError * error = nil;
        [_self checkResponse:response error:&error];

        if (error) {
            _self.error = error;
            [[NSNotificationCenter defaultCenter] postNotificationName:kAPRequestErrorNotification
                                                                object:_self
                                                              userInfo:@{ kAPRequestErrorNotificationErrorKey: error }];
        }

        if (connectionReceievedResponseCallback) {
            connectionReceievedResponseCallback(connection,response);
        }

    }];
}

+ (void)checkConnectionResponse:(BOOL (^)(NSURLResponse *response, NSError **error))checkConnectionResponseCallback{
    Swizzlean *swizzle = [[Swizzlean alloc] initWithClassToSwizzle:[APRequest class]];
    swizzle.resetWhenDeallocated = NO;
    [swizzle swizzleInstanceMethod:@selector(checkResponse:error:) withReplacementImplementation:^(APRequest *_self, NSURLResponse *response, NSError **error){

        BOOL useDefaultChecks = YES;

        if (checkConnectionResponseCallback) {
            useDefaultChecks = checkConnectionResponseCallback(response, error);
        }

        if (useDefaultChecks){
            NSHTTPURLResponse * httpResponse = (NSHTTPURLResponse *)response;

            if ([httpResponse isKindOfClass:[NSHTTPURLResponse class]]) {
                if (httpResponse.statusCode < 200 || httpResponse.statusCode >= 300) {
                    *error = [NSError errorWithDomain:kAPRequestErrorDomain
                                                 code:kAPRequestErrorServerError
                                             userInfo:@{ kAPRequestErrorURLResponseKey: response, kAPRequestErrorStatusCodeKey: @(httpResponse.statusCode), NSLocalizedDescriptionKey: [[NSHTTPURLResponse localizedStringForStatusCode:httpResponse.statusCode] titleize] }];
                }
            }
            else if (*error) {
                if ([*error code] == NSURLErrorUserCancelledAuthentication) {
                    *error = [NSError errorWithDomain:kAPRequestErrorDomain
                                                 code:kAPRequestErrorServerError
                                             userInfo:@{ kAPRequestErrorStatusCodeKey: [NSNumber numberWithInt:401], NSLocalizedDescriptionKey: [[NSHTTPURLResponse localizedStringForStatusCode:401] titleize], NSUnderlyingErrorKey: *error }];
                }
            }
        }

    }];
}

+ (void)connectionFinished:(BOOL (^)(NSURLResponse *response, NSMutableData *downloadedData, NSError *error))connectionDidFinishCallback{
    Swizzlean *swizzle = [[Swizzlean alloc] initWithClassToSwizzle:[APRequest class]];
    swizzle.resetWhenDeallocated = NO;
    [swizzle swizzleInstanceMethod:@selector(connectionDidFinishLoading:) withReplacementImplementation:^(APRequest *_self, NSURLConnection *connection) {
        assert(connection == _self.connection);

#ifdef __VERBOSE
        NSLog(@"%@", [[NSString alloc] initWithData:_self.downloadedData encoding:NSUTF8StringEncoding]);
#endif

        BOOL shouldContinue = true;
        if (connectionDidFinishCallback){
            shouldContinue = connectionDidFinishCallback(_self.response, _self.downloadedData, _self.error);
        }

        if (shouldContinue) {
            _self.callback(_self.downloadedData, _self.error);
        }

        [_self reset];
    }];
}
@end
