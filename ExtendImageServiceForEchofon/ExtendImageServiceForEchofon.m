//
//  ExtendImageServiceForEchofon.m
//  ExtendImageServiceForEchofon
//

#import <objc/runtime.h>
#import "EchofonProtocols.h"
#import "ExtendImageServiceForEchofon.h"

@implementation NSObject(ExtendImageServiceForEchofon)

- (BOOL)__isImageURL
{
    BOOL result = [self __isImageURL];
    if (!result) {
        NSURL *url = [NSURL URLWithString:(NSString*)self];
        NSString<EchofonNSString>* lastPathComponent = (NSString<EchofonNSString>*)url.lastPathComponent;
        if ([url.host hasSuffix:@"p.twipple.jp"] && [lastPathComponent isAlphaNumOnly]) {
            result = YES;
        } else if ([url.host hasSuffix:@"viddy.com"] && [url.path hasPrefix:@"/video/"]) {
            result = YES;
        }
    }
    return result;
}

- (BOOL)__isVideoURL
{
    BOOL result = [self __isVideoURL];
    if (!result) {
        NSURL *url = [NSURL URLWithString:(NSString*)self];
        if ([url.host hasSuffix:@"viddy.com"] && [url.path hasPrefix:@"/video/"]) {
            result = YES;
        }
    }
    return result;
}

- (NSString*)__getImageURL
{
    NSString* result = [self __getImageURL];
    if (!result) {
        NSURL *url = [NSURL URLWithString:(NSString*)self];
        NSString<EchofonNSString>* lastPathComponent = (NSString<EchofonNSString>*)url.lastPathComponent;
        if ([url.host hasSuffix:@"p.twipple.jp"] && [lastPathComponent isAlphaNumOnly]) {
            result = [NSString stringWithFormat:@"http://p.twipple.jp/show/large/%@", lastPathComponent];
        }
    }
    return result;
}

- (NSString*)__getThumbnailImageURL
{
    NSString* result = [self __getThumbnailImageURL];
    if (!result) {
        NSURL *url = [NSURL URLWithString:(NSString*)self];
        NSString<EchofonNSString>* lastPathComponent = (NSString<EchofonNSString>*)url.lastPathComponent;
        if ([url.host hasSuffix:@"p.twipple.jp"] && [lastPathComponent isAlphaNumOnly]) {
            result = [NSString stringWithFormat:@"http://p.twipple.jp/show/thumb/%@", lastPathComponent];
        } else if ([url.host hasSuffix:@"viddy.com"] && [url.path hasPrefix:@"/video/"]) {
            result = [NSString stringWithFormat:@"http://cdn.viddy.com/images/video/%@.jpg", lastPathComponent];
        }
    }
    return result;
}

@end

@implementation ExtendImageServiceForEchofon

/**
 * A special method called by SIMBL once the application has started and all classes are initialized.
 */
+ (void) load
{
    ExtendImageServiceForEchofon* plugin = [ExtendImageServiceForEchofon sharedInstance];
    // ... do whatever
    if (plugin) {
        Class from = objc_getClass("NSString");
        Class to = objc_getClass("NSObject");
        method_exchangeImplementations(class_getInstanceMethod(from, @selector(isImageURL)), 
                                       class_getInstanceMethod(to, @selector(__isImageURL)));
        method_exchangeImplementations(class_getInstanceMethod(from, @selector(isVideoURL)), 
                                       class_getInstanceMethod(to, @selector(__isVideoURL)));
        method_exchangeImplementations(class_getInstanceMethod(from, @selector(getImageURL)), 
                                       class_getInstanceMethod(to, @selector(__getImageURL)));
        method_exchangeImplementations(class_getInstanceMethod(from, @selector(getThumbnailImageURL)), 
                                       class_getInstanceMethod(to, @selector(__getThumbnailImageURL)));
    }
}

/**
 * @return the single static instance of the plugin object
 */
+ (ExtendImageServiceForEchofon*) sharedInstance
{
    static ExtendImageServiceForEchofon* plugin = nil;
    
    if (plugin == nil)
        plugin = [[ExtendImageServiceForEchofon alloc] init];
    
    return plugin;
}

@end
