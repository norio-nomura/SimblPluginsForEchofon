//
//  TweetMarkerForEchofon.m
//  TweetMarkerForEchofon
//

#import <objc/runtime.h>
#import <SystemConfiguration/SystemConfiguration.h>
#import "TweetMarkerForEchofon.h"
#import "TweetMarkerClient.h"

NSString * const kTweetMarker = @"TweetMarker";
NSString * const kTweetMarkerMenuTitle = @"set Tweet Marker";

@implementation NSObject(TweetMarkerForEchofon)

- (void)__setLastFriendsIdTweetMarkerForEchofon:(NSUInteger)statusId
{
    [self __setLastFriendsIdTweetMarkerForEchofon:statusId];
    TweetMarkerClient* tweetMarker = objc_getAssociatedObject(self, kTweetMarker);
    [tweetMarker postCollection:@"timeline" statusId:statusId];
}

- (void)__setLastMentionsIdTweetMarkerForEchofon:(NSUInteger)statusId
{
    [self __setLastMentionsIdTweetMarkerForEchofon:statusId];
    TweetMarkerClient* tweetMarker = objc_getAssociatedObject(self, kTweetMarker);
    [tweetMarker postCollection:@"mentions" statusId:statusId];
}

- (void)__setLastMessagesIdTweetMarkerForEchofon:(NSUInteger)statusId
{
    [self __setLastMessagesIdTweetMarkerForEchofon:statusId];
    TweetMarkerClient* tweetMarker = objc_getAssociatedObject(self, kTweetMarker);
    [tweetMarker postCollection:@"messages" statusId:statusId];
}

@end

@implementation NSControl(TweetMarkerForEchofon)

- (void)__addedSetMenu:(NSMenu*)aMenu
{
    id delegate;
    object_getInstanceVariable(self, "delegate", (void**)&delegate);

    [super setMenu:aMenu];
    
    NSMenuItem *item = [aMenu itemWithTitle:kTweetMarkerMenuTitle];
    if (!item) {
        item = [[[NSMenuItem alloc]initWithTitle:kTweetMarkerMenuTitle
                                          action:@selector(setTweetMarker:)
                                   keyEquivalent:@""]autorelease];
        item.target = [TweetMarkerForEchofon sharedInstance];
        [aMenu addItem:item];
    }
}

- (void)__exchangedSetMenu:(NSMenu*)aMenu
{
    id delegate;
    object_getInstanceVariable(self, "delegate", (void**)&delegate);
    
    [self __exchangedSetMenu:aMenu];
    
    NSMenuItem *item = [aMenu itemWithTitle:kTweetMarkerMenuTitle];
    if (!item) {
        item = [[[NSMenuItem alloc]initWithTitle:kTweetMarkerMenuTitle
                                          action:@selector(setTweetMarker:)
                                   keyEquivalent:@""]autorelease];
        item.target = [TweetMarkerForEchofon sharedInstance];
        [aMenu addItem:item];
    }
}

@end

NSString * const kTweetMarkerBecomeReachable = @"TweetMarkerBecomeReachable";

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
        Class accountClass = objc_getClass("Account");
        Class rootClass = objc_getClass("NSObject");
        method_exchangeImplementations(class_getInstanceMethod(accountClass, @selector(setLastFriendsId:)), 
                                       class_getInstanceMethod(rootClass, @selector(__setLastFriendsIdTweetMarkerForEchofon:)));
        method_exchangeImplementations(class_getInstanceMethod(accountClass, @selector(setLastMentionsId:)), 
                                       class_getInstanceMethod(rootClass, @selector(__setLastMentionsIdTweetMarkerForEchofon:)));
        method_exchangeImplementations(class_getInstanceMethod(accountClass, @selector(setLastMessagesId:)),
                                       class_getInstanceMethod(rootClass, @selector(__setLastMessagesIdTweetMarkerForEchofon:)));
        
        Class richTextViewClass = objc_getClass("RichTextView");
        Class nsControlClass = objc_getClass("NSControl");
        if (!class_addMethod(richTextViewClass,
                             @selector(setMenu:),
                             class_getMethodImplementation(nsControlClass, @selector(__addedSetMenu:)),
                             method_getTypeEncoding(class_getInstanceMethod(nsControlClass, @selector(__addedSetMenu:))))) {
            method_exchangeImplementations(class_getInstanceMethod(richTextViewClass, @selector(setMenu:)),
                                           class_getInstanceMethod(nsControlClass, @selector(__exchangedSetMenu:)));
        }
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

- (id)init
{
    if (self = [super init]) {
        [self installTweetMarkerClient];
        [self registerReachability];
        [self registerNotification];
        [self addMenuItem];
    }
    return self;
}

-(void)dealloc
{
    [self unregisterReachability];
    [super dealloc];
}

-(void)installTweetMarkerClient
{
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

- (void)registerReachability
{
    reachability = SCNetworkReachabilityCreateWithName(kCFAllocatorDefault,"api.tweetmarker.net");
    if (!(reachability &&
          SCNetworkReachabilitySetCallback(reachability, TweetMarkerReachabilityCallback, NULL) &&
          SCNetworkReachabilityScheduleWithRunLoop(reachability, [[NSRunLoop mainRunLoop]getCFRunLoop], kCFRunLoopDefaultMode))) {
        NSLog(@"SCNetworkReachabilitySetCallback is fail!");
    }
}

- (void)unregisterReachability
{
    if (reachability) {
        SCNetworkReachabilityUnscheduleFromRunLoop(reachability, [[NSRunLoop mainRunLoop]getCFRunLoop], kCFRunLoopDefaultMode);
        CFRelease(reachability);
    }
}

- (void) shouldGet:(NSNotification*) note
{
    id<EchofonAccountsManager> accountsManager = [NSClassFromString(@"AccountsManager") performSelector:@selector(sharedAccountManager)];
    if (accountsManager) {
        id<EchofonAccount> account = [accountsManager currentAccount];
        TweetMarkerClient* tweetMarker = objc_getAssociatedObject(account, kTweetMarker);
        [tweetMarker getAllCollections];
    }
}

-(void)registerNotification
{
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

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem
{
    BOOL result = NO;
    id<EchofonAccountsManager> accountsManager = [NSClassFromString(@"AccountsManager") performSelector:@selector(sharedAccountManager)];
    if (accountsManager) {
        id<EchofonAppController> appController = (id<EchofonAppController>)[[NSApplication sharedApplication]delegate];
        id<EchofonMenuController> menuController = [appController menu];
        BOOL bIsContextMenu = [[menuItem menu]supermenu] == nil;
        id<EchofonTweetCell> tweetCell = bIsContextMenu ? [menuController currentTweetCell] : [menuController selectedTweetCell];
        if (tweetCell) {
            id timeline = [tweetCell delegate];
            id<EchofonAccount> account = [accountsManager currentAccount];
            if (timeline == [appController friends] && [[tweetCell status]statusId] > [account lastFriendsId]) {
                result = YES;
            } else if (timeline == [appController mentions] && [[tweetCell status]statusId] > [account lastMentionsId]) {
                result = YES;
            } else if (timeline == [appController directMessages] && [[tweetCell status]statusId] > [account lastMessagesId]) {
                result = YES;
            }
        }
    }
    return result;
}

- (IBAction)setTweetMarker:(id)sender
{
    id<EchofonAccountsManager> accountsManager = [NSClassFromString(@"AccountsManager") performSelector:@selector(sharedAccountManager)];
    if (accountsManager) {
        id<EchofonAppController> appController = (id<EchofonAppController>)[[NSApplication sharedApplication]delegate];
        BOOL bIsContextMenu = [[(NSMenuItem*)sender menu]supermenu] == nil;
        id<EchofonMenuController> menuController = [appController menu];
        id<EchofonTweetCell> tweetCell = bIsContextMenu ? [menuController currentTweetCell] : [menuController selectedTweetCell];
        if (tweetCell) {
            BOOL bNeedNotify = NO;
            id timeline = [tweetCell delegate];
            id<EchofonAccount> account = [accountsManager currentAccount];
            if (timeline == [appController friends]) {
                [account setLastFriendsId:[[tweetCell status]statusId]];
                bNeedNotify = YES;
            } else if (timeline == [appController mentions]) {
                [account setLastMentionsId:[[tweetCell status]statusId]];
                bNeedNotify = YES;
            } else if (timeline == [appController directMessages]) {
                [account setLastMessagesId:[[tweetCell status]statusId]];
                bNeedNotify = YES;
            }
            if (bNeedNotify) {
                [[NSNotificationCenter defaultCenter]postNotificationName:@"AccountDidSyncNotification" object:account];
            }
        }
    }
}

- (void)addMenuItem
{
    NSMenu *mainMenu = [[NSApplication sharedApplication]mainMenu];
    if (mainMenu) {
        for (NSMenuItem *item in [mainMenu itemArray]) {
            NSInteger index = -1;
            for (NSMenuItem *subItem in [[item submenu]itemArray]) {
                if (NSOrderedSame == [subItem.keyEquivalent caseInsensitiveCompare:@"L"]) {
                    index = [[item submenu]indexOfItem:subItem];
                    break;
                }
            }
            if (index != -1) {
                NSMenuItem *newItem = [[[NSMenuItem alloc]initWithTitle:kTweetMarkerMenuTitle
                                                  action:@selector(setTweetMarker:)
                                           keyEquivalent:@"M"]autorelease];
                newItem.keyEquivalentModifierMask = NSCommandKeyMask;
                newItem.target = self;
                [[item submenu] insertItem:newItem atIndex:index+1];
                break;
            }
        }
    }
}

@end
