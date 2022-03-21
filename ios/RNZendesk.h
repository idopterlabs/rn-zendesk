#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <React/RCTBridgeModule.h>
#import <React/RCTViewManager.h>
#import <ChatProvidersSDK/ChatProvidersSDK.h>
#import <React/RCTConvert.h>

typedef void (^GetTokenCompletion)(NSString * _Nullable, NSError * _Nullable);

@interface RNZendesk : NSObject<RCTBridgeModule>

@end

@interface ZDKJWTAuth: NSObject<ZDKJWTAuthenticator>

{
    RCTResponseSenderBlock onRequestNewTokenCallback;
}

- (void)setCallbackReactNative: (RCTResponseSenderBlock)callbackReactNative;
- (void)getToken: (GetTokenCompletion)completion;

@end

