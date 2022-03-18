
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

@implementation RNZendesk

bool isEnabledLoggable = false;
bool isEnabledJwtAuthenticator = false;

RCT_EXPORT_MODULE()

RCT_EXPORT_METHOD(init:(NSDictionary *)options) {
    if (options[@"isEnabledLoggable"]) {
        [ZDKCoreLogger setEnabled:YES];
        [ZDKCoreLogger setLogLevel:ZDKLogLevelDebug];
        isEnabledLoggable = true;
    }
    
    [ZDKZendesk initializeWithAppId:options[@"appId"]
                           clientId: options[@"clientId"]
                         zendeskUrl: options[@"url"]];
    [ZDKSupport initializeWithZendesk: [ZDKZendesk instance]];
    [ZDKAnswerBot initializeWithZendesk:[ZDKZendesk instance] support:[ZDKSupport instance]];
    [ZDKChat initializeWithAccountKey:options[@"key"] appId:options[@"appId"] queue:dispatch_get_main_queue()];
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
        NSLog(@"Setting visitor info: department: %@ tags: %@, email: %@, name: %@, phone: %@", config.department, config.tags, config.visitorInfo.email, config.visitorInfo.name, config.visitorInfo.phoneNumber);
    }
}

RCT_EXPORT_METHOD(resetUserIdentity) {
    [[ZDKChat instance] resetIdentity:^{
        if (isEnabledLoggable) {
            NSLog(@"Reset user identity is done");
        }
        
        // latestJwtCompletion = null;
    }];
}

RCT_EXPORT_METHOD(updateUserToken: (NSString *) token) {
    // if (latestJwtCompletion && isEnabledJwtAuthenticator) {
    if (isEnabledJwtAuthenticator) {
        if (token && token.length <= 0) {
            // TODO ??
        } else {
            // TODO ??
        }
    }
}

// TODO: resetUserIdentity

// TODO: updateUserToken

RCT_EXPORT_METHOD(setUserIdentity: (NSDictionary *)options) {
    if (options[@"isEnabledJwtAuthenticator"]) {
        isEnabledJwtAuthenticator = options[@"isEnabledJwtAuthenticator"];
        if (isEnabledJwtAuthenticator) {
            ZDKJWTAuth *authenticator = [ZDKJWTAuth new];
            [[ZDKChat instance] setIdentityWithAuthenticator:authenticator];
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
    [self setVisitorInfo:options];
    dispatch_sync(dispatch_get_main_queue(), ^{
        [self showHelpCenterFunction:options];
    });
}

// TODO: startChatOrTicket

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
    ZDKChatEngine *chatEngine = [ZDKChatEngine engineAndReturnError:&error];
    ZDKSupportEngine *supportEngine = [ZDKSupportEngine engineAndReturnError:&error];
    NSArray *engines = @[];
    ZDKMessagingConfiguration *messagingConfiguration = [ZDKMessagingConfiguration new];
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
    if (options[@"chatOnly"]) {
        engines = @[
            (id <ZDKEngine>) [ZDKChatEngine engineAndReturnError:&error]
        ];
    } else {
        engines = @[
            (id <ZDKEngine>) [ZDKAnswerBotEngine engineAndReturnError:&error],
            (id <ZDKEngine>) [ZDKChatEngine engineAndReturnError:&error],
            (id <ZDKEngine>) [ZDKSupportEngine engineAndReturnError:&error],
        ];
    }

    ZDKChatConfiguration *chatConfiguration = [[ZDKChatConfiguration alloc] init];
    chatConfiguration.isPreChatFormEnabled = YES;
    chatConfiguration.isAgentAvailabilityEnabled = YES;
    
    UIViewController *chatController =[ZDKMessaging.instance buildUIWithEngines:engines
                                                                        configs:@[messagingConfiguration, chatConfiguration]
                                                                          error:&error];
    if (error && isEnabledLoggable) {
        NSLog(@"Error occured %@", error);
    }
    chatController.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle: @"Close"
                                                                                       style: UIBarButtonItemStylePlain
                                                                                      target: self
                                                                                      action: @selector(chatClosedClicked)];
    
    
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

- (void)setCallback:(void (^)(NSString * _Nullable))completion {
    Aaa = completion;
}

- (void)getToken:(void (^ _Nonnull)(NSString * _Nullable, NSError * _Nullable))completion {
    NSString *token = [Aaa self]; // TODO
    completion(token, NULL);
}

@end
