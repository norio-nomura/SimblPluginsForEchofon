//
//  TweetMarkerForEchofon.m
//  TweetMarkerForEchofon
//

#import <objc/runtime.h>
#import "TweetMarkerForEchofon.h"
#import "TweetMarkerClient.h"

const NSString* kTweetMarker = @"TweetMarker";

@implementation NSObject(TweetMarkerForEchofon)

- (void)__setLastFriendsId:(NSUInteger)statusId {
    [self __setLastFriendsId:statusId];
    TweetMarkerClient* tweetMarker = objc_getAssociatedObject(self, kTweetMarker);
    [tweetMarker postCollections:[NSArray arrayWithObject:@"timeline"]
                       statusIds:[NSArray arrayWithObject:[NSString stringWithFormat:@"%lu",statusId]]];
}

- (void)__setLastMentionsId:(NSUInteger)statusId {
    [self __setLastMentionsId:statusId];
    TweetMarkerClient* tweetMarker = objc_getAssociatedObject(self, kTweetMarker);
    [tweetMarker postCollections:[NSArray arrayWithObject:@"mentions"]
                       statusIds:[NSArray arrayWithObject:[NSString stringWithFormat:@"%lu",statusId]]];
}

- (void)__setLastMessagesId:(NSUInteger)statusId {
    [self __setLastMessagesId:statusId];
    TweetMarkerClient* tweetMarker = objc_getAssociatedObject(self, kTweetMarker);
    [tweetMarker postCollections:[NSArray arrayWithObject:@"messages"]
                       statusIds:[NSArray arrayWithObject:[NSString stringWithFormat:@"%lu",statusId]]];
}

@end

@implementation TweetMarkerForEchofon

/**
 * A special method called by SIMBL once the application has started and all classes are initialized.
 */
+ (void) load
{
    TweetMarkerForEchofon* plugin = [TweetMarkerForEchofon sharedInstance];
    // ... do whatever
    if (plugin) {
        Class targetClass = objc_getClass("Account");
        Class newClass = objc_getClass("NSObject");
        method_exchangeImplementations(class_getInstanceMethod(targetClass, @selector(setLastFriendsId:)), 
                                       class_getInstanceMethod(newClass, @selector(__setLastFriendsId:)));
        method_exchangeImplementations(class_getInstanceMethod(targetClass, @selector(setLastMentionsId:)), 
                                       class_getInstanceMethod(newClass, @selector(__setLastMentionsId:)));
        method_exchangeImplementations(class_getInstanceMethod(targetClass, @selector(setLastMessagesId:)), 
                                       class_getInstanceMethod(newClass, @selector(__setLastMessagesId:)));
    }
}

/**
 * @return the single static instance of the plugin object
 */
+ (TweetMarkerForEchofon*) sharedInstance
{
    static TweetMarkerForEchofon* plugin = nil;
    
    if (plugin == nil)
        plugin = [[TweetMarkerForEchofon alloc] init];
    
    return plugin;
}

- (id)init {
    if (self = [super init]) {
        [self installTweetMarkerClient];
        [self registerNotification];
    }
    return self;
}

-(void)installTweetMarkerClient {
    id accountsManager = [NSClassFromString(@"AccountsManager") performSelector:@selector(sharedAccountManager)];
    if (accountsManager) {
        NSArray* accountControllers;
        object_getInstanceVariable(accountsManager, "controllers", (void**)&accountControllers);
        for (NSObject<EchofonAccountsController>* controller in accountControllers) {
            id<EchofonAccount> account = controller.account;
            NSObject<EchofonTwitterClient>* client;
            object_getInstanceVariable(controller, "client", (void**)&client);
            if (account && client) {
                TweetMarkerClient* tweetMarker = [TweetMarkerClient new];
                tweetMarker.account = account;
                tweetMarker.oauthConsumerKey = client.consumerToken;
                tweetMarker.oauthConsumerSecret = client.consumerSecret;
                tweetMarker.oauthToken = account.oauthToken;
                tweetMarker.oauthTokenSecret = account.oauthTokenSecret;
                objc_setAssociatedObject(account, kTweetMarker, tweetMarker, OBJC_ASSOCIATION_RETAIN);
                [tweetMarker release];
                [tweetMarker getAllCollections];
            }
        }
    }
}

- (void) shouldGet:(NSNotification*) note {
    id<EchofonAccountsManager> accountsManager = [NSClassFromString(@"AccountsManager") performSelector:@selector(sharedAccountManager)];
    if (accountsManager) {
        id<EchofonAccount> account = [accountsManager currentAccount];
        TweetMarkerClient* tweetMarker = objc_getAssociatedObject(account, kTweetMarker);
        [tweetMarker getAllCollections];
    }
}

-(void)registerNotification {
    NSNotificationCenter* wsnc = [[NSWorkspace sharedWorkspace] notificationCenter];
    SEL sel_get = @selector(shouldGet:);
    [wsnc addObserver:self selector:sel_get name:NSWorkspaceDidWakeNotification object:nil];
    [wsnc addObserver:self selector:sel_get name:NSWorkspaceScreensDidWakeNotification object:nil];
    [wsnc addObserver:self selector:sel_get name:NSWorkspaceSessionDidBecomeActiveNotification object:nil];
    NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self selector:sel_get name:NSApplicationWillBecomeActiveNotification object:nil];
    [nc addObserver:self selector:sel_get name:NSApplicationWillUnhideNotification object:nil];
    [nc addObserver:self selector:sel_get name:NSWindowDidDeminiaturizeNotification object:nil];
}

@end
