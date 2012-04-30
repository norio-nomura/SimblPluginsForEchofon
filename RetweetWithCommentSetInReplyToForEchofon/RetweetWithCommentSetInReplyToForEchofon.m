//
//  RetweetWithCommentSetInReplyToForEchofon.m
//  RetweetWithCommentSetInReplyToForEchofon
//

#import <objc/runtime.h>
#import "RetweetWithCommentSetInReplyToForEchofon.h"

@implementation NSObject(RetweetWithCommentSetInReplyToForEchofon)

- (void)startRetweetWithCommentSetInReplyTo:(id)status
{
    [self startRetweetWithCommentSetInReplyTo:status];
    static Ivar ivar;
    if (!ivar) {
        ivar = class_getInstanceVariable([self class], "inReplyToStatus");
    }
    if (ivar) {
        [object_getIvar(self, ivar) release];
        object_setIvar(self, ivar, [status retain]);
        if ([self respondsToSelector:@selector(textDidChange:)] &&
            [self respondsToSelector:@selector(layoutViews:)]) {
            [self performSelector:@selector(textDidChange:) withObject:nil];
            [self performSelector:@selector(layoutViews:) withObject:nil];
        }
    }
}

@end

@implementation RetweetWithCommentSetInReplyToForEchofon

/**
 * A special method called by SIMBL once the application has started and all classes are initialized.
 */
+ (void) load
{
    RetweetWithCommentSetInReplyToForEchofon* plugin = [RetweetWithCommentSetInReplyToForEchofon sharedInstance];
    // ... do whatever
    if (plugin) {
        method_exchangeImplementations(class_getInstanceMethod(objc_getClass("MainWindowController"), @selector(startRetweetWithComment:)), 
                                       class_getInstanceMethod(objc_getClass("NSObject"), @selector(startRetweetWithCommentSetInReplyTo:)));
    }
}

/**
 * @return the single static instance of the plugin object
 */
+ (RetweetWithCommentSetInReplyToForEchofon*) sharedInstance
{
    static RetweetWithCommentSetInReplyToForEchofon* plugin = nil;
    
    if (plugin == nil)
        plugin = [[RetweetWithCommentSetInReplyToForEchofon alloc] init];
    
    return plugin;
}


@end
