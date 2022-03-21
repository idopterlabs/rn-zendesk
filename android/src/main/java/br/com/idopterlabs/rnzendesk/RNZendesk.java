
package br.com.idopterlabs.rnzendesk;

import android.app.Activity;
import android.content.Context;
import android.util.Log;

import androidx.annotation.NonNull;

import com.facebook.react.bridge.Callback;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.bridge.ReadableMap;
import com.zendesk.logger.Logger;
import com.zendesk.service.ErrorResponse;
import com.zendesk.service.ZendeskCallback;

import zendesk.answerbot.AnswerBot;
import zendesk.answerbot.AnswerBotEngine;
import zendesk.chat.Account;
import zendesk.chat.AccountStatus;
import zendesk.chat.Chat;
import zendesk.chat.ChatConfiguration;
import zendesk.chat.ChatEngine;
import zendesk.chat.ChatProvider;
import zendesk.chat.ChatProvidersConfiguration;
import zendesk.chat.CompletionCallback;
import zendesk.chat.JwtAuthenticator;
import zendesk.chat.ProfileProvider;
import zendesk.chat.Providers;
import zendesk.chat.PushNotificationsProvider;
import zendesk.chat.VisitorInfo;
import zendesk.core.AnonymousIdentity;
import zendesk.core.Identity;
import zendesk.core.JwtIdentity;
import zendesk.core.Zendesk;
import zendesk.messaging.MessagingActivity;
import zendesk.messaging.MessagingConfiguration;
import zendesk.support.Support;
import zendesk.support.SupportEngine;
import zendesk.support.guide.HelpCenterActivity;
import zendesk.support.guide.HelpCenterConfiguration;
import zendesk.support.guide.ViewArticleActivity;
import zendesk.support.request.RequestActivity;
import zendesk.support.requestlist.RequestListActivity;

@SuppressWarnings({"ConstantConditions", "unused"})
public class RNZendesk extends ReactContextBaseJavaModule {

    @SuppressWarnings("FieldMayBeFinal")
    private ReactContext appContext;
    private static final String TAG_LOG = "RNZendesk";
    private boolean isEnabledLoggable = false;
    private boolean isEnabledJwtAuthenticator = false;
    private JwtAuthenticator.JwtCompletion latestJwtCompletion;

    public RNZendesk(ReactApplicationContext reactContext) {
        super(reactContext);
        appContext = reactContext;
    }

    @NonNull
    @Override
    public String getName() {
        return "RNZendesk";
    }

    @ReactMethod
    public void init(ReadableMap options) {
        if (options.hasKey("isEnabledLoggable") && options.getBoolean("isEnabledLoggable")) {
            Logger.setLoggable(true);
            isEnabledLoggable = true;
        }

        String appId = options.getString("appId");
        String clientId = options.getString("clientId");
        String url = options.getString("url");
        String key = options.getString("key");
        Context context = appContext;
        Zendesk.INSTANCE.init(context, url, appId, clientId);
        Support.INSTANCE.init(Zendesk.INSTANCE);
        AnswerBot.INSTANCE.init(Zendesk.INSTANCE, Support.INSTANCE);
        Chat.INSTANCE.init(context, key, appId);
    }

    @ReactMethod
    public void setVisitorInfo(ReadableMap options) {
        Providers providers = Chat.INSTANCE.providers();
        if (providers == null) {
            Log.d(TAG_LOG, "Can't set visitor info, provider is null");
            return;
        }

        ProfileProvider profileProvider = providers.profileProvider();
        if (profileProvider == null) {
            Log.d(TAG_LOG, "Profile provider is null");
            return;
        }

        ChatProvider chatProvider = providers.chatProvider();
        if (chatProvider == null) {
            Log.d(TAG_LOG, "Chat provider is null");
            return;
        }

        VisitorInfo.Builder builder = VisitorInfo.builder();
        if (options.hasKey("name")) {
            builder = builder.withName(options.getString("name"));
        }

        if (options.hasKey("email")) {
            builder = builder.withEmail(options.getString("email"));
        }

        if (options.hasKey("phone")) {
            builder = builder.withPhoneNumber(options.getString("phone"));
        }

        VisitorInfo visitorInfo = builder.build();
        profileProvider.setVisitorInfo(visitorInfo, null);

        ChatProvidersConfiguration.Builder chatProvidersBuilder = ChatProvidersConfiguration.builder();
        chatProvidersBuilder.withVisitorInfo(visitorInfo);

        if (options.hasKey("department")) {
            String departmentName = options.getString("department");
            chatProvider.setDepartment(departmentName, null);
            chatProvidersBuilder.withDepartment(departmentName);
        }

        ChatProvidersConfiguration chatProvidersConfiguration = chatProvidersBuilder.build();
        Chat.INSTANCE.setChatProvidersConfiguration(chatProvidersConfiguration);
    }

    @ReactMethod
    public void resetUserIdentity() {
        Chat.INSTANCE.resetIdentity(result -> {
            if (isEnabledLoggable) {
                Log.d(TAG_LOG, "Reset user identity is done");
            }

            latestJwtCompletion = null;
        });
    }

    @ReactMethod
    public void updateUserToken(String token) {
        if (latestJwtCompletion != null && isEnabledJwtAuthenticator) {
            if (token.length() <= 0) {
                latestJwtCompletion.onError();
            } else {
                latestJwtCompletion.onTokenLoaded(token);
            }

            latestJwtCompletion = null;
            if (isEnabledLoggable) {
                Log.d(TAG_LOG, "Request new token is done");
            }
        }
    }

    @ReactMethod
    public void setUserIdentity(ReadableMap options, Callback callbackNeedUpdateIdentity) {
        if (options.hasKey("isEnabledJwtAuthenticator")) {
            isEnabledJwtAuthenticator = options.getBoolean("isEnabledJwtAuthenticator");
            if (isEnabledJwtAuthenticator) {
                JwtAuthenticator jwtAuthenticator = jwtCompletion -> {
                    if (isEnabledLoggable) {
                        Log.d(TAG_LOG, "Request new token is start");
                    }

                    latestJwtCompletion = jwtCompletion;
                    callbackNeedUpdateIdentity.invoke();
                };
                Chat.INSTANCE.setIdentity(jwtAuthenticator);
            } else {
                latestJwtCompletion = null;
            }
        }

        if (options.hasKey("token")) {
            String token = options.getString("token");
            Identity identity = new JwtIdentity(token);
            Zendesk.INSTANCE.setIdentity(identity);
        } else if (options.hasKey("name") && options.hasKey("email")) {
            String name = options.getString("name");
            String email = options.getString("email");
            Identity identity = new AnonymousIdentity.Builder()
                    .withNameIdentifier(name).withEmailIdentifier(email).build();
            Zendesk.INSTANCE.setIdentity(identity);
        }
    }

    @ReactMethod
    public void showHelpCenter(ReadableMap options) {
        String botName = options.hasKey("botName") ? options.getString("botName") : "Chat Bot";
        Activity activity = getCurrentActivity();
        HelpCenterConfiguration.Builder helpCenterBuilder = HelpCenterActivity.builder();

        if (options.hasKey("withChat") && options.getBoolean("withChat")) {
            helpCenterBuilder.withEngines(ChatEngine.engine());
        }

        if (options.hasKey("disableTicketCreation") && options.getBoolean("disableTicketCreation")) {
            helpCenterBuilder.withContactUsButtonVisible(false);
            helpCenterBuilder.withShowConversationsMenuButton(false)
                    .show(activity, ViewArticleActivity.builder()
                            .withContactUsButtonVisible(false)
                            .config());
        } else {
            helpCenterBuilder.show(activity);
        }
    }

    @ReactMethod
    public void startChatOrTicket(ReadableMap options) {
        Providers providers = Chat.INSTANCE.providers();
        providers.accountProvider().getAccount(new ZendeskCallback<Account>() {
            @Override
            public void onSuccess(Account account) {
                if (account.getStatus() == AccountStatus.ONLINE) {
                    startChat(options);
                } else {
                    startTicket();
                }
            }

            @Override
            public void onError(ErrorResponse errorResponse) {
                if (isEnabledLoggable) {
                    Log.d(TAG_LOG, "Error request getAccount (" + errorResponse.getStatus() + "): " + errorResponse.getResponseBody());
                }

                startTicket();
            }
        });
    }

    @ReactMethod
    public void startChat(ReadableMap options) {
        Activity activity = getCurrentActivity();
        String botName = options.getString("botName");

        ChatConfiguration chatConfiguration = ChatConfiguration.builder()
                .withAgentAvailabilityEnabled(true)
                .withOfflineFormEnabled(true)
                .build();

        MessagingConfiguration.Builder messagingBuilder = MessagingActivity.builder();
        messagingBuilder.withBotLabelString(botName);

        if (options.hasKey("chatOnly") && options.getBoolean("chatOnly")) {
            messagingBuilder.withEngines(ChatEngine.engine(), SupportEngine.engine());
        } else {
            messagingBuilder.withEngines(AnswerBotEngine.engine(), ChatEngine.engine(), SupportEngine.engine());
        }

        messagingBuilder.show(activity, chatConfiguration);
    }

    @ReactMethod
    public void startTicket() {
        Activity activity = getCurrentActivity();
        RequestActivity.builder()
                .show(activity);
    }

    @ReactMethod
    public void showTicketList() {
        Activity activity = getCurrentActivity();
        RequestListActivity.builder()
                .show(activity);
    }

    @ReactMethod
    public void setNotificationToken(String token) {
        Providers providers = Chat.INSTANCE.providers();

        if (providers == null) {
            if (isEnabledLoggable) {
                Log.d(TAG_LOG, "Providers is null");
            }
            return;
        }

        PushNotificationsProvider pushProvider = providers.pushNotificationsProvider();
        if (pushProvider == null) {
            if (isEnabledLoggable) {
                Log.d(TAG_LOG, "Push Provider is null");
            }
            return;
        }

        pushProvider.registerPushToken(token);
    }

    @ReactMethod
    public void setPrimaryColor(String token) {
        if (isEnabledLoggable) {
            Log.d(TAG_LOG, "Not support in Android Version");
        }
    }

}