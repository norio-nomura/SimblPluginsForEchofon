//
//  TweetMarkerForEchofon.m
//  TweetMarkerForEchofon
//

#import <objc/runtime.h>
#import <SystemConfiguration/SystemConfiguration.h>
#import "TweetMarkerForEchofon.h"
#import "TweetMarkerClient.h"

const NSString* kTweetMarker = @"TweetMarker";

@implementation NSObject(TweetMarkerForEchofon)

- (void)__setLastFriendsId:(NSUInteger)statusId {
    [self __setLastFriendsId:statusId];
    TweetMarkerClient* tweetMarker = objc_getAssociatedObject(self, kTweetMarker);
    [tweetMarker postCollection:@"timeline" statusId:statusId];
}

- (void)__setLastMentionsId:(NSUInteger)statusId {
    [self __setLastMentionsId:statusId];
    TweetMarkerClient* tweetMarker = objc_getAssociatedObject(self, kTweetMarker);
    [tweetMarker postCollection:@"mentions" statusId:statusId];
}

- (void)__setLastMessagesId:(NSUInteger)statusId {
    [self __setLastMessagesId:statusId];
    TweetMarkerClient* tweetMarker = objc_getAssociatedObject(self, kTweetMarker);
    [tweetMarker postCollection:@"messages" statusId:statusId];
}

@end

NSString* kTweetMarkerBecomeReachable = @"TweetMarkerBecomeReachable";

static void TweetMarkerReachabilityCallback(SCNetworkReachabilityRef target, SCNetworkConnectionFlags flags, void* info) {
    if (flags & kSCNetworkReachabilityFlagsReachable) {
        [[NSNotificationCenter defaultCenter]postNotificationName:kTweetMarkerBecomeReachable object:nil];
    }
}

@implementation TweetMarkerForEchofon {
    SCNetworkReachabilityRef reachability;
}

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
        [self registerReachability];
        [self registerNotification];
    }
    return self;
}

-(void)dealloc {
    [self unregisterReachability];
    [super dealloc];
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

- (void)registerReachability {
    reachability = SCNetworkReachabilityCreateWithName(kCFAllocatorDefault,"api.tweetmarker.net");
    if (!(reachability &&
          SCNetworkReachabilitySetCallback(reachability, TweetMarkerReachabilityCallback, NULL) &&
          SCNetworkReachabilityScheduleWithRunLoop(reachability, [[NSRunLoop mainRunLoop]getCFRunLoop], kCFRunLoopDefaultMode))) {
        NSLog(@"SCNetworkReachabilitySetCallback is fail!");
    }
}

- (void)unregisterReachability {
    if (reachability) {
        SCNetworkReachabilityUnscheduleFromRunLoop(reachability, [[NSRunLoop mainRunLoop]getCFRunLoop], kCFRunLoopDefaultMode);
        CFRelease(reachability);
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
    [nc addObserver:self selector:sel_get name:kTweetMarkerBecomeReachable object:nil];
}

@end
