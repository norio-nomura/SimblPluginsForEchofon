//
//  MyTrendsForEchofon.m
//  MyTrendsForEchofon
//

#import <objc/runtime.h>
#import "MyTrendsForEchofon.h"
#import "MyTrendsAccountSettings.h"

const NSString* kMyTrendsAccountSettings = @"MyTrendsAccountSettings";

@implementation NSObject(MyTrendsForEchofon)

- (void)__getTrends {
    id<EchofonTrendsConnection> trendsConnection = (id<EchofonTrendsConnection>)self;
    MyTrendsAccountSettings* settings = objc_getAssociatedObject(self, kMyTrendsAccountSettings);
    if (!settings) {
        settings = [[MyTrendsAccountSettings alloc]initWithTrendsConnection:trendsConnection];
        objc_setAssociatedObject(self, kMyTrendsAccountSettings, settings, OBJC_ASSOCIATION_RETAIN);
        [settings release];
    }
    [settings update];
}

@end

@implementation MyTrendsForEchofon

/**
 * A special method called by SIMBL once the application has started and all classes are initialized.
 */
+ (void) load
{
    MyTrendsForEchofon* plugin = [MyTrendsForEchofon sharedInstance];
    // ... do whatever
    if (plugin) {
        method_exchangeImplementations(class_getInstanceMethod(objc_getClass("TrendsConnection"), @selector(getTrends)), 
                                       class_getInstanceMethod(objc_getClass("NSObject"), @selector(__getTrends)));
    }
}

/**
 * @return the single static instance of the plugin object
 */
+ (MyTrendsForEchofon*) sharedInstance
{
    static MyTrendsForEchofon* plugin = nil;
    
    if (plugin == nil)
        plugin = [[MyTrendsForEchofon alloc] init];
    
    return plugin;
}

@end
