/**
 * PushWoosh
 *
 * Created by Douglas Alves
 */

#import "TiPushwooshModule.h"
#import "TiBase.h"
#import "TiHost.h"
#import "TiUtils.h"
#import "TiApp.h"
#import <PushwooshFramework/PushwooshFramework.h>

@implementation TiPushwooshModule

#pragma mark Internal

// This is generated for your module, please do not change it
- (id)moduleGUID
{
    return @"c00775ea-2a94-46db-ab9e-5adfc1bcf1bd";
}

// This is generated for your module, please do not change it
- (NSString *)moduleId
{
    return @"ti.pushwoosh";
}

NSDictionary *_pushPayloadToSave = nil;

#pragma mark Lifecycle

- (id)_initWithPageContext:(id<TiEvaluator>)context
{
    NSLog(@"PushWoosh module init");
    
    if (self = [super _initWithPageContext:context]) {
        [Pushwoosh sharedInstance].delegate = self;
        NSLog(@"[DEBUG] %@ loaded", self);
    }
    
    return self;
}

- (void)_configure
{
  [super _configure];
  [[TiApp app] registerApplicationDelegate:self];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    NSLog(@"[PushWoosh] didFinishLaunchingWithOptions");
    
    [[Pushwoosh sharedInstance] setDelegate:self];
    [[Pushwoosh sharedInstance] handlePushReceived:launchOptions];

    NSDictionary *pushPayload = [launchOptions objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey];
    if (pushPayload) {
        NSLog(@"[PushWoosh] App launched from push: %@", pushPayload);
        _pushPayloadToSave = pushPayload;
    }

    return YES;
}

#pragma mark Public APIs

NSString * const ON_REGISTER_SUCCESS = @"onRegisterSuccess";
NSString * const ON_REGISTER_ERROR = @"onRegisterError";
NSString * const ON_MESSAGE_RECEIVED = @"onMessageReceived";
NSString * const ON_MESSAGE_OPENED = @"onMessageOpened";
NSString * const ON_SET_TAG_SUCCESS = @"onSetTagSuccess";
NSString * const ON_SET_TAG_ERROR = @"onSetTagError";

MAKE_SYSTEM_STR(ON_REGISTER_SUCCESS, ON_REGISTER_SUCCESS);
MAKE_SYSTEM_STR(ON_REGISTER_ERROR, ON_REGISTER_ERROR);
MAKE_SYSTEM_STR(ON_MESSAGE_RECEIVED, ON_MESSAGE_RECEIVED);
MAKE_SYSTEM_STR(ON_MESSAGE_OPENED, ON_MESSAGE_OPENED);
MAKE_SYSTEM_STR(ON_SET_TAG_SUCCESS, ON_SET_TAG_SUCCESS);
MAKE_SYSTEM_STR(ON_SET_TAG_ERROR, ON_SET_TAG_ERROR);

- (void)registerForPushNotifications:(id)args
{
    //register for push notifications!
    [[Pushwoosh sharedInstance] registerForPushNotifications];
}

- (void)processPendingPushMessage:(id)unused
{
    NSLog(@"[PushWoosh] processPendingPushMessage");
    if (_pushPayloadToSave){
        NSLog(@"[PushWoosh] processPendingPushMessage has valid _pushPayloadToSave");
        if ([self _hasListeners:ON_MESSAGE_OPENED]) {
            [self fireEvent:ON_MESSAGE_OPENED withObject:@{ @"payload": NULL_IF_NIL(_pushPayloadToSave) }];
            _pushPayloadToSave = nil;
        }
    }
}

- (void)setTags:(id)args
{
    ENSURE_SINGLE_ARG(args, NSDictionary);
    
    NSDictionary *tags = (NSDictionary *)args;
    
    NSLog(@"[DEBUG] Tags: %@", tags);
    
    NSMutableDictionary *formattedTags = [NSMutableDictionary dictionary];
    
    for (NSString *key in tags) {
        id value = [tags objectForKey:key];
        
        if ([value isKindOfClass:[NSString class]] ||
            [value isKindOfClass:[NSNumber class]]) {
            [formattedTags setObject:value forKey:key];
        } else if ([value isKindOfClass:[NSArray class]]) {
            NSMutableArray *stringArray = [NSMutableArray array];
            for (id item in (NSArray *)value) {
                if ([item isKindOfClass:[NSString class]]) {
                    [stringArray addObject:item];
                }
            }
            if (stringArray.count > 0) {
                [formattedTags setObject:stringArray forKey:key];
            }
        }
    }
    
    if (formattedTags.count > 0) {
        [[Pushwoosh sharedInstance] setTags:formattedTags completion:^(NSError * _Nullable error) {
            if (!error) {
                if ([self _hasListeners:ON_SET_TAG_SUCCESS]) {
                    [self fireEvent:ON_SET_TAG_SUCCESS withObject:nil];
                }
            } else {
                if ([self _hasListeners:ON_SET_TAG_ERROR]) {
                    [self fireEvent:ON_SET_TAG_ERROR withObject:@{ @"error": NULL_IF_NIL(error.localizedDescription) }];
                }
            }
        }];
    } else {
        NSLog(@"[DEBUG] No valid tag to set.");
    }
}

- (void)getTagValue:(id)args {
    ENSURE_ARG_COUNT(args, 2);
    
    NSString *tagName = [TiUtils stringValue:[args objectAtIndex:0]];
    KrollCallback *callback = [args objectAtIndex:1];
    
    if (tagName == nil || [tagName length] == 0) {
        if (callback != nil) {
            NSDictionary *errorResponse = @{
                @"success": @NO,
                @"error": @"Tag name can't be empty."
            };
            [callback call:@[errorResponse] thisObject:nil];
        }
        return;
    }
    
    [[Pushwoosh sharedInstance] getTags:^(NSDictionary * _Nullable tags) {
        NSMutableDictionary *response = [NSMutableDictionary dictionary];
        
        id tagValue = [tags objectForKey:tagName];
        
        id safeValue = tagValue ?: [NSNull null];
        
        response[@"success"] = @YES;
        response[@"value"] = safeValue;
        
        if (callback != nil) {
            [callback call:@[response] thisObject:nil];
        }
        
    } onFailure:^(NSError * _Nullable error) {
        NSMutableDictionary *response = [NSMutableDictionary dictionary];
        
        response[@"success"] = @NO;
        response[@"error"] = error.localizedDescription ?: @"Erro desconhecido ao obter a tag.";
        
        if (callback != nil) {
            [callback call:@[response] thisObject:nil];
        }
    }];
}


#pragma mark Pushwoosh Delegates

//handle token received from APNS
- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    NSLog(@"ON_REGISTER_SUCCESS: %@", deviceToken);
    
    if ([self _hasListeners:ON_REGISTER_SUCCESS]) {
        NSString *tokenString = [self hexStringFromDeviceToken:deviceToken];
        [self fireEvent:ON_REGISTER_SUCCESS withObject:@{ @"token": tokenString }];
    }
    
    [[Pushwoosh sharedInstance] handlePushRegistration:deviceToken];
}

//handle token receiving error
- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
    NSLog(@"ON_REGISTER_ERROR: %@", error);
    
    if ([self _hasListeners:ON_REGISTER_ERROR]) {
        [self fireEvent:ON_REGISTER_ERROR withObject:@{ @"error": error.localizedDescription }];
    }
    
    [[Pushwoosh sharedInstance] handlePushRegistrationFailure:error];
}

//for silent push notifications
- (void)application:(UIApplication *)application
didReceiveRemoteNotification:(NSDictionary *)userInfo
fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler {
    [[Pushwoosh sharedInstance] handlePushReceived:userInfo];
    completionHandler(UIBackgroundFetchResultNoData);
}

//this event is fired when the push gets received
- (void)pushwoosh:(Pushwoosh *)pushwoosh onMessageReceived:(PWMessage *)message {
    NSLog(@"onMessageReceived: %@", message.payload);
    if ([self _hasListeners:ON_MESSAGE_RECEIVED]) {
        [self fireEvent:ON_MESSAGE_RECEIVED withObject:@{ @"payload": NULL_IF_NIL(message.payload) }];
    }
}

//this event is fired when user taps the notification
- (void)pushwoosh:(Pushwoosh *)pushwoosh onMessageOpened:(PWMessage *)message {
    NSLog(@"onMessageOpened: %@", message.payload);
    if ([self _hasListeners:ON_MESSAGE_OPENED]) {
        [self fireEvent:ON_MESSAGE_OPENED withObject:@{ @"payload": NULL_IF_NIL(message.payload) }];
    }
}

# pragma mark Utils

- (NSString *)hexStringFromDeviceToken:(NSData *)deviceToken {
    const unsigned char *dataBuffer = (const unsigned char *)[deviceToken bytes];

    if (!dataBuffer) return [NSString string];

    NSMutableString *hexString = [NSMutableString stringWithCapacity:(deviceToken.length * 2)];
    for (int i = 0; i < deviceToken.length; ++i) {
        [hexString appendFormat:@"%02x", dataBuffer[i]];
    }

    return [hexString copy];
}

@end
