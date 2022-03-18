#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <React/RCTBridgeModule.h>
#import <ChatProvidersSDK/ChatProvidersSDK.h>

@interface RNZendesk : NSObject<RCTBridgeModule>

@end

@interface ZDKJWTAuth: NSObject<ZDKJWTAuthenticator>

{
    id Aaa;
}

- (void)setCallback:(void (^ _Nonnull)(NSString *_Nullable token))completion;
- (void)getToken:(void (^ _Nonnull)(NSString * _Nullable, NSError * _Nullable))completion;

@end
