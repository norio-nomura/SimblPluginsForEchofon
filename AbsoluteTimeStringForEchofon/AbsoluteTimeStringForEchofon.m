//
//  AbsoluteTimeStringForEchofon.m
//  AbsoluteTimeStringForEchofon
//

#import <objc/runtime.h>
#import "AbsoluteTimeStringForEchofon.h"

@implementation AbsoluteTimeStringForEchofon

/**
 * A special method called by SIMBL once the application has started and all classes are initialized.
 */
+ (void) load
{
    AbsoluteTimeStringForEchofon* plugin = [AbsoluteTimeStringForEchofon sharedInstance];
    // ... do whatever
    if (plugin) {
        method_exchangeImplementations(class_getInstanceMethod(objc_getClass("Status"), @selector(timeString)), 
                                       class_getInstanceMethod(objc_getClass("Status"), @selector(absoluteTimeString)));
    }
}

/**
 * @return the single static instance of the plugin object
 */
+ (AbsoluteTimeStringForEchofon*) sharedInstance
{
    static AbsoluteTimeStringForEchofon* plugin = nil;
    
    if (plugin == nil)
        plugin = [[AbsoluteTimeStringForEchofon alloc] init];
    
    return plugin;
}

@end
