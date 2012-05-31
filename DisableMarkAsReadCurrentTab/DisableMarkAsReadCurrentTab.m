//
//  DisableMarkAsReadCurrentTab.m
//  DisableMarkAsReadCurrentTab
//

#import <objc/runtime.h>
#import "DisableMarkAsReadCurrentTab.h"

@implementation NSObject(TweetMarkerForEchofon)

- (void)__markAsReadCurrentTab
{
    NSInteger tabIndex = (NSInteger)[self performSelector:@selector(currentTabIndex)];
    if (tabIndex>2) {
        [self __markAsReadCurrentTab];
    }
}

@end

@implementation DisableMarkAsReadCurrentTab

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
