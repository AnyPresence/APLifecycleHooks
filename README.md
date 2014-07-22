APLifecycleHooks
==================

Lifecycle Event Handling for use with the [AnyPresence](http://anypresence.com) iOS SDK

### Installation

##### Via CocoaPods
- Add `pod 'APLifecycleHooks', :git => 'https://github.com/AnyPresence/APLifecycleHooks.git'` to your podfile
- Run `pod install`
- Import header (`#import <APLifecycleHooks/APLifecycleHooks.h>`)
- Link pod against `APSDK.framework`
 
##### Manual Installation
- Add `APLifecycleHooks` folder to your project
- Import header (`#import "APLifecycleHooks.h"`)

##### Example Use
```objc
    [APLifecycleHooks asyncConnectionFinished:^BOOL(NSMutableData *downloadedData, NSError *error) {
        if (error) {
            if (error.code == 401) {
                // Handle 401 Unauthorized error on all SDK calls
                
                return false; // Stop callback from being executed
            }
        }
        
        return true;
    }];
```
###### Other Examples
```objc
    [APLifecycleHooks synchronousConnectionFinished:^(NSData *downloadedData, NSError *error) {
       // Handle all sync SDK calls
    }];
    
    [APLifecycleHooks asyncConnectionStarted:^(NSURLRequest *request, NSURLConnection *connection) {
        // Handle all async SDK calls starting
    }];
```

