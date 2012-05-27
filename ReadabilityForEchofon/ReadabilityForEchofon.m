//
//  ReadabilityForEchofon.m
//  ReadabilityForEchofon
//

#import <objc/runtime.h>
#import "EchofonProtocols.h"
#import "ReadabilityForEchofon.h"
#import "ReadabilityClient.h"
#import "ReadabilityAPI_KEY.h"

@implementation NSObject(ReadabilityForEchofon)

- (void)__handleURLEvent:(NSAppleEventDescriptor *)event withReplyEvent: (NSAppleEventDescriptor *)replyEvent
{
    NSString *url = [[event paramDescriptorForKeyword:keyDirectObject] stringValue];
    if ([url hasPrefix:[NSString stringWithFormat:@"echofon:%@", kReadabilityAPI_CALLBACK_URL]]) {
        [[[ReadabilityForEchofon sharedInstance]client]accessToken:url];
    } else {
        [self performSelector:@selector(handleURLEvent:withReplyEvent:) withObject:event withObject:replyEvent];
    }
}

@end

@implementation ReadabilityForEchofon {
    ReadabilityClient *_client;
}

@synthesize client=_client;

/**
 * A special method called by SIMBL once the application has started and all classes are initialized.
 */
+ (void) load
{
    ReadabilityForEchofon* plugin = [ReadabilityForEchofon sharedInstance];
    // ... do whatever
    if (plugin) {
    }
}

/**
 * @return the single static instance of the plugin object
 */
+ (ReadabilityForEchofon*) sharedInstance
{
    static ReadabilityForEchofon* plugin = nil;
    
    if (plugin == nil)
        plugin = [[ReadabilityForEchofon alloc] init];
    
    return plugin;
}

- (id)init
{
    if (self = [super init]) {
        id<EchofonAppController> appController = (id<EchofonAppController>)[[NSApplication sharedApplication]delegate];
        id<EchofonMenuController> menuController = [appController menu];
        NSMenu *urlMenu = [menuController urlMenu];
        if (urlMenu) {
            NSMenuItem *item = [[[NSMenuItem alloc]initWithTitle:@"Read Later with Readability"
                                                         action:@selector(sendReadLaterWithReadability:)
                                                  keyEquivalent:@""]autorelease];
            item.target = self;
            [urlMenu addItem:item];
        }
        NSAppleEventManager *manager = [NSAppleEventManager sharedAppleEventManager];
        [manager setEventHandler:appController
                     andSelector:@selector(__handleURLEvent:withReplyEvent:)
                   forEventClass:kInternetEventClass
                      andEventID:kAEGetURL];
    }
    return self;
}

-(void)dealloc {
    [_client release];
    [super dealloc];
}

- (IBAction)sendReadLaterWithReadability:(id)sender
{
    id<EchofonAppController> appController = (id<EchofonAppController>)[[NSApplication sharedApplication]delegate];
    id<EchofonMenuController> menuController = [appController menu];
    
    id<EchofonAccountsManager> accountsManager = [NSClassFromString(@"AccountsManager")
                                                  performSelector:@selector(sharedAccountManager)];
    NSString *username = [[accountsManager currentAccount]username];
    
    if (!_client || ![_client.username isEqualToString:username] || !_client.authorized) {
        self.client = [[[ReadabilityClient alloc]initWithUserName:username]autorelease];
    }
    [_client addBookmark:[menuController selectedUrl]];
}

@end
