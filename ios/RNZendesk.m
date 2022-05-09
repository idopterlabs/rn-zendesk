
#import "RNZendesk.h"
#import <AnswerBotSDK/AnswerBotSDK.h>
#import <AnswerBotProvidersSDK/AnswerBotProvidersSDK.h>
#import <ChatSDK/ChatSDK.h>
#import <ChatProvidersSDK/ChatProvidersSDK.h>
#import <MessagingSDK/MessagingSDK.h>
#import <CommonUISDK/CommonUISDK.h>
#import <SupportSDK/SupportSDK.h>
#import <SupportProvidersSDK/SupportProvidersSDK.h>
#import <ZendeskCoreSDK/ZendeskCoreSDK.h>
#import <React/RCTBridgeModule.h>

NSString *TAG_LOG = @"RNZendesk";
bool isEnabledLoggable = false;
bool isEnabledJwtAuthenticator = false;
GetTokenCompletion latestJwtCompletion;

@implementation RNZendesk

RCT_EXPORT_MODULE()

RCT_EXPORT_METHOD(init:(NSDictionary *)options) {
    if (options[@"isEnabledLoggable"]) {
        [ZDKCoreLogger setEnabled:YES];
        [ZDKCoreLogger setLogLevel:ZDKLogLevelDebug];
        isEnabledLoggable = true;
    }
    
    [ZDKZendesk initializeWithAppId: options[@"appId"]
                           clientId: options[@"clientId"]
                         zendeskUrl: options[@"url"]];
    [ZDKSupport initializeWithZendesk: [ZDKZendesk instance]];
    [ZDKAnswerBot initializeWithZendesk: [ZDKZendesk instance]
                                support:[ZDKSupport instance]];
    [ZDKChat initializeWithAccountKey: options[@"key"]
                                appId: options[@"appId"]
                                queue: dispatch_get_main_queue()];
}

RCT_EXPORT_METHOD(setVisitorInfo:(NSDictionary *)options) {
    ZDKChatAPIConfiguration *config = [[ZDKChatAPIConfiguration alloc] init];
    if (options[@"department"]) {
        config.department = options[@"department"];
    }
    
    if (options[@"tags"]) {
        config.tags = options[@"tags"];
    }
    
    config.visitorInfo = [[ZDKVisitorInfo alloc] initWithName:options[@"name"]
                                                        email:options[@"email"]
                                                  phoneNumber:options[@"phone"]];
    ZDKChat.instance.configuration = config;
    
    if (isEnabledLoggable) {
        NSLog(@"%@: Setting visitor info: department: %@ tags: %@, email: %@, name: %@, phone: %@", TAG_LOG, config.department, config.tags, config.visitorInfo.email, config.visitorInfo.name, config.visitorInfo.phoneNumber);
    }
}

RCT_EXPORT_METHOD(resetUserIdentity) {
    [[ZDKChat instance] resetIdentity:^{
        if (isEnabledLoggable) {
            NSLog(@"%@: Reset user identity is done", TAG_LOG);
        }
        
        latestJwtCompletion = nil;
    }];
}

RCT_EXPORT_METHOD(updateUserToken: (NSString *) token) {
    if (isEnabledJwtAuthenticator) {
        if (token && token.length <= 0) {
            NSError *error = [NSError errorWithDomain:@"Not found token"
                                                 code: 100
                                             userInfo:@{
                NSLocalizedDescriptionKey:@"Not found token"
            }];
            latestJwtCompletion(nil, error);
        } else {
            latestJwtCompletion(token, nil);
        }
        
        latestJwtCompletion = nil;
        if (isEnabledLoggable) {
            NSLog(@"%@: Request new token is done", TAG_LOG);
        }
    }
}

RCT_EXPORT_METHOD(setUserIdentity: (NSDictionary *)options callback: (RCTResponseSenderBlock)callback) {
    if (options[@"isEnabledJwtAuthenticator"]) {
        isEnabledJwtAuthenticator = options[@"isEnabledJwtAuthenticator"];
        if (isEnabledJwtAuthenticator) {
            NSLog(@"%@: 111111", TAG_LOG);
            ZDKJWTAuth *authenticator = [ZDKJWTAuth new];
            NSLog(@"%@: 22222222", TAG_LOG);
            [authenticator setCallbackReactNative:callback];
            NSLog(@"%@: 33333333", TAG_LOG);
            [[ZDKChat instance] setIdentityWithAuthenticator:authenticator];
            NSLog(@"%@: 4444444", TAG_LOG);
        }
    }
    
    if (options[@"token"]) {
        id<ZDKObjCIdentity> userIdentity = [[ZDKObjCJwt alloc] initWithToken:options[@"token"]];
        [[ZDKZendesk instance] setIdentity:userIdentity];
    } else if (options[@"name"] && options[@"email"]) {
        id<ZDKObjCIdentity> userIdentity = [[ZDKObjCAnonymous alloc] initWithName:options[@"name"] // name is nullable
                                                                            email:options[@"email"]]; // email is nullable
        [[ZDKZendesk instance] setIdentity:userIdentity];
    }
}

RCT_EXPORT_METHOD(showHelpCenter:(NSDictionary *)options) {
    dispatch_sync(dispatch_get_main_queue(), ^{
        [self showHelpCenterFunction:options];
    });
}

RCT_EXPORT_METHOD(startChatOrTicket:(NSDictionary *)options) {
    dispatch_sync(dispatch_get_main_queue(), ^{
        [self startChatOrTicketFunction:options];
    });
}


RCT_EXPORT_METHOD(startChat:(NSDictionary *)options) {
    dispatch_sync(dispatch_get_main_queue(), ^{
        [self startChatFunction:options];
    });
}

RCT_EXPORT_METHOD(startTicket) {
    dispatch_sync(dispatch_get_main_queue(), ^{
        [self startTicketFunction];
    });
}

RCT_EXPORT_METHOD(showTicketList) {
    dispatch_sync(dispatch_get_main_queue(), ^{
        [self showTicketListFunction];
    });
}

RCT_EXPORT_METHOD(setNotificationToken:(NSData *)deviceToken) {
    dispatch_sync(dispatch_get_main_queue(), ^{
        [self registerForNotifications:deviceToken];
    });
}

RCT_EXPORT_METHOD(setPrimaryColor:(NSString *)color) {
    [ZDKCommonTheme currentTheme].primaryColor = [self colorFromHexString:color];
}

- (UIColor *)colorFromHexString:(NSString *)hexString {
    unsigned rgbValue = 0;
    NSScanner *scanner = [NSScanner scannerWithString:hexString];
    [scanner setScanLocation:1]; // bypass '#' character
    [scanner scanHexInt:&rgbValue];
    return [UIColor colorWithRed:((rgbValue & 0xFF0000) >> 16)/255.0 green:((rgbValue & 0xFF00) >> 8)/255.0 blue:(rgbValue & 0xFF)/255.0 alpha:1.0];
}

- (void) showHelpCenterFunction:(NSDictionary *)options {
    NSError *error = nil;
    NSArray *engines = @[];
    NSString *botName = @"ChatBot";
    if (options[@"botName"]) {
        botName = options[@"botName"];
    }
    
    if (options[@"withChat"]) {
        engines = @[(id <ZDKEngine>) [ZDKChatEngine engineAndReturnError:&error]];
    }
    
    ZDKHelpCenterUiConfiguration* helpCenterUiConfig = [ZDKHelpCenterUiConfiguration new];
    helpCenterUiConfig.objcEngines = engines;
    ZDKArticleUiConfiguration* articleUiConfig = [ZDKArticleUiConfiguration new];
    articleUiConfig.objcEngines = engines;
    if (options[@"disableTicketCreation"]) {
        helpCenterUiConfig.showContactOptions = NO;
        articleUiConfig.showContactOptions = NO;
    }
    
    UIViewController* controller = [ZDKHelpCenterUi buildHelpCenterOverviewUiWithConfigs: @[helpCenterUiConfig, articleUiConfig]];
    
    UIViewController *topController = [UIApplication sharedApplication].keyWindow.rootViewController;
    while (topController.presentedViewController) {
        topController = topController.presentedViewController;
    }
    
    UINavigationController *navControl = [[UINavigationController alloc] initWithRootViewController: controller];
    [topController presentViewController:navControl animated:YES completion:nil];
}

- (void) startChatOrTicketFunction:(NSDictionary *)options {
    [ZDKChat.accountProvider getAccount:^(ZDKChatAccount *account, NSError *error) {
        if (account) {
            switch (account.accountStatus) {
                case ZDKChatAccountStatusOnline:
                    [self startChatFunction:options];
                    break;
                default:
                    [self startTicketFunction];
                    break;
            }
        } else {
            if (isEnabledLoggable) {
                NSLog(@"%@: Error request getAccount: %@", TAG_LOG, error);
            }
            
            [self startTicketFunction];
        }
    }];
}

- (void) startChatFunction:(NSDictionary *)options {
    ZDKMessagingConfiguration *messagingConfiguration = [ZDKMessagingConfiguration new];
    NSString *botName = @"ChatBot";
    if (options[@"botName"]) {
        botName = options[@"botName"];
    }
    
    messagingConfiguration.name = botName;
    
    if (options[@"botImage"]) {
        messagingConfiguration.botAvatar = options[@"botImage"];
    }
    
    NSError *error = nil;
    NSMutableArray *engines = [[NSMutableArray alloc] init];
    
    [engines addObject:(id <ZDKEngine>) [ZDKChatEngine engineAndReturnError:&error]];
    [engines addObject:(id <ZDKEngine>) [ZDKSupportEngine engineAndReturnError:&error]];
    
    if (!options[@"chatOnly"]) {
        [engines addObject:(id <ZDKEngine>) [ZDKAnswerBotEngine engineAndReturnError:&error]];
    }
    
    ZDKChatConfiguration *chatConfiguration = [[ZDKChatConfiguration alloc] init];
    chatConfiguration.isPreChatFormEnabled = YES;
    chatConfiguration.isAgentAvailabilityEnabled = YES;
    
    UIViewController *chatController = [ZDKMessaging.instance buildUIWithEngines: engines
                                                                        configs: @[messagingConfiguration, chatConfiguration]
                                                                          error: &error];
    if (error && isEnabledLoggable) {
        NSLog(@"%@: Error occured %@", TAG_LOG, error);
    }
    
    if (@available(iOS 13.0, *)) {
        chatController.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem: UIBarButtonSystemItemClose
                                                                                                        target: self
                                                                                                        action: @selector(chatClosedClicked)];
    } else {
        chatController.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem: UIBarButtonSystemItemCancel
                                                                                                        target: self
                                                                                                        action: @selector(chatClosedClicked)];
    }

    UIViewController *topController = [UIApplication sharedApplication].keyWindow.rootViewController;
    while (topController.presentedViewController) {
        topController = topController.presentedViewController;
    }
    
    UINavigationController *navControl = [[UINavigationController alloc] initWithRootViewController: chatController];
    [topController presentViewController:navControl animated:YES completion:nil];
}

- (void) startTicketFunction {
    UIViewController* controller = [ZDKRequestUi buildRequestUi];
    
    UIViewController *topController = [UIApplication sharedApplication].keyWindow.rootViewController;
    while (topController.presentedViewController) {
        topController = topController.presentedViewController;
    }
    
    UINavigationController *navControl = [[UINavigationController alloc] initWithRootViewController: controller];
    
    [topController presentViewController:navControl animated:YES completion:nil];
}

- (void) showTicketListFunction {
    UIViewController* controller = [ZDKRequestUi buildRequestList];
    
    
    UIViewController *topController = [UIApplication sharedApplication].keyWindow.rootViewController;
    while (topController.presentedViewController) {
        topController = topController.presentedViewController;
    }
    
    UINavigationController *navControl = [[UINavigationController alloc] initWithRootViewController: controller];
    [topController presentViewController:navControl animated:YES completion:nil];
}

- (void) chatClosedClicked {
    UIViewController *topController = [UIApplication sharedApplication].keyWindow.rootViewController;
    while (topController.presentedViewController) {
        topController = topController.presentedViewController;
    }
    [topController dismissViewControllerAnimated:TRUE completion:NULL];
}

- (void) registerForNotifications:(NSData *)deviceToken {
    [ZDKChat registerPushToken:deviceToken];
}

@end

@implementation ZDKJWTAuth

- (void)setCallbackReactNative: (RCTResponseSenderBlock)callbackReactNative {
    NSLog(@"%@: ----------------- setCallbackReactNative", TAG_LOG);
    onRequestNewTokenCallback = callbackReactNative;
}

- (void)getToken: (GetTokenCompletion)completion {
    NSLog(@"%@: ----------------- getToken", TAG_LOG);
    if (isEnabledLoggable) {
        NSLog(@"%@: %@", TAG_LOG, @"Request new token is start");
    }
    
    NSLog(@"%@: ----------------- latestJwtCompletion", TAG_LOG);
    latestJwtCompletion = completion;
    if (onRequestNewTokenCallback != nil) {
        NSLog(@"%@: ----------------- onRequestNewTokenCallback", TAG_LOG);
        onRequestNewTokenCallback(@[]);
    }
}

@end

