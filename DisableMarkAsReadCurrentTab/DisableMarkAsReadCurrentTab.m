//
//  DisableMarkAsReadCurrentTab.m
//  DisableMarkAsReadCurrentTab
//

#import <objc/runtime.h>
#import "EchofonProtocols.h"
#import "DisableMarkAsReadCurrentTab.h"

@implementation NSObject(DisableMarkAsReadCurrentTab)

- (void)__markAsReadCurrentTab
{
    NSInteger tabIndex = (NSInteger)[self performSelector:@selector(currentTabIndex)];
    if (tabIndex>2) {
        [self __markAsReadCurrentTab];
    }
}

- (void)__tabBar:(id)tabBar didClickedSelectedTabViewItem:(id)item
{
    BOOL bNeedNotify = NO;
    id<EchofonAccountsManager> accountsManager = [NSClassFromString(@"AccountsManager") performSelector:@selector(sharedAccountManager)];
    id<EchofonAccount> account = [accountsManager currentAccount];
    id<EchofonAppController> appController = (id<EchofonAppController>)[[NSApplication sharedApplication]delegate];
    id<EchofonTimelineController>timeline = [self performSelector:@selector(currentTimelineController)];
    id<EchofonFastTableView>table = [timeline table];
    NSArray *visibleCells = [table visibleCells];
    if (visibleCells && [visibleCells count]) {
        id<EchofonTweetCell> tweetCell = (id<EchofonTweetCell>)[visibleCells objectAtIndex:0];
        if (tweetCell) {
            NSUInteger statusId = [[tweetCell status]statusId];
            if (timeline == [appController friends] && statusId > [account lastFriendsId]) {
                [account setLastFriendsId:statusId];
                bNeedNotify = YES;
            } else if (timeline == [appController mentions] && statusId > [account lastMentionsId]) {
                [account setLastMentionsId:statusId];
                bNeedNotify = YES;
            } else if (timeline == [appController directMessages] && statusId > [account lastMessagesId]) {
                [account setLastMessagesId:statusId];
                bNeedNotify = YES;
            }
        }
    }
    if (bNeedNotify) {
        [[NSNotificationCenter defaultCenter]postNotificationName:@"AccountDidSyncNotification" object:account];
    } else {
        [self performSelector:@selector(scrollToFirstUnread)];
    }
}

- (void)__twitterClient:(id<EchofonTwitterClient>)client didPost:(id<EchofonStatus>)post inReplyTo:(id<EchofonStatus>)reply
{
    static BOOL bExchanged = NO;
    if (!bExchanged) {
        Class accountClass = objc_getClass("Account");
        Class rootClass = objc_getClass("NSObject");
        method_exchangeImplementations(class_getInstanceMethod(accountClass, @selector(setLastFriendsId:)), 
                                       class_getInstanceMethod(rootClass, @selector(__setLastFriendsIdDisableMarkAsReadCurrentTab:)));
        method_exchangeImplementations(class_getInstanceMethod(accountClass, @selector(setLastMentionsId:)), 
                                       class_getInstanceMethod(rootClass, @selector(__setLastMentionsIdDisableMarkAsReadCurrentTab:)));
        method_exchangeImplementations(class_getInstanceMethod(accountClass, @selector(setLastMessagesId:)),
                                       class_getInstanceMethod(rootClass, @selector(__setLastMessagesIdDisableMarkAsReadCurrentTab:)));
        bExchanged = YES;
    }
    static DisableMarkAsReadCurrentTab *plugin = nil;
    plugin = plugin ? plugin : [DisableMarkAsReadCurrentTab sharedInstance];
    
    plugin.disableAccountClassSetLastMethods = YES;
    [self __twitterClient:client didPost:post inReplyTo:reply];
    plugin.disableAccountClassSetLastMethods = NO;
}

- (void)__setLastFriendsIdDisableMarkAsReadCurrentTab:(NSUInteger)statusId
{
    static DisableMarkAsReadCurrentTab *plugin = nil;
    plugin = plugin ? plugin : [DisableMarkAsReadCurrentTab sharedInstance];
    if (!plugin.disableAccountClassSetLastMethods) {
        [self __setLastFriendsIdDisableMarkAsReadCurrentTab:statusId];
    }
}

- (void)__setLastMentionsIdDisableMarkAsReadCurrentTab:(NSUInteger)statusId
{
    static DisableMarkAsReadCurrentTab *plugin = nil;
    plugin = plugin ? plugin : [DisableMarkAsReadCurrentTab sharedInstance];
    if (!plugin.disableAccountClassSetLastMethods) {
        [self __setLastMentionsIdDisableMarkAsReadCurrentTab:statusId];
    }
}

- (void)__setLastMessagesIdDisableMarkAsReadCurrentTab:(NSUInteger)statusId
{
    static DisableMarkAsReadCurrentTab *plugin = nil;
    plugin = plugin ? plugin : [DisableMarkAsReadCurrentTab sharedInstance];
    if (!plugin.disableAccountClassSetLastMethods) {
        [self __setLastMessagesIdDisableMarkAsReadCurrentTab:statusId];
    }
}

@end

@implementation DisableMarkAsReadCurrentTab {
    BOOL _disableAccountClassSetLastMethods;
}

@synthesize disableAccountClassSetLastMethods=_disableAccountClassSetLastMethods;

/**
 * A special method called by SIMBL once the application has started and all classes are initialized.
 */
+ (void) load
{
    DisableMarkAsReadCurrentTab* plugin = [DisableMarkAsReadCurrentTab sharedInstance];
    // ... do whatever
    if (plugin) {
        Class mainWindowControllerClass = objc_getClass("MainWindowController");
        Class rootClass = objc_getClass("NSObject");
        method_exchangeImplementations(class_getInstanceMethod(mainWindowControllerClass, @selector(markAsReadCurrentTab)),
                                       class_getInstanceMethod(rootClass, @selector(__markAsReadCurrentTab)));
        method_exchangeImplementations(class_getInstanceMethod(mainWindowControllerClass, @selector(tabBar:didClickedSelectedTabViewItem:)),
                                       class_getInstanceMethod(rootClass, @selector(__tabBar:didClickedSelectedTabViewItem:)));
        Class appControllerClass = objc_getClass("AppController");
        method_exchangeImplementations(class_getInstanceMethod(appControllerClass, @selector(twitterClient:didPost:inReplyTo:)),
                                       class_getInstanceMethod(rootClass, @selector(__twitterClient:didPost:inReplyTo:)));
    }
}

/**
 * @return the single static instance of the plugin object
 */
+ (DisableMarkAsReadCurrentTab*) sharedInstance
{
    static DisableMarkAsReadCurrentTab* plugin = nil;
    
    if (plugin == nil)
        plugin = [[DisableMarkAsReadCurrentTab alloc] init];
    
    return plugin;
}

@end
