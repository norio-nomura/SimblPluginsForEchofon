//
//  TweetMarkerClient.m
//  TweetMarkerForEchofon
//

#import <objc/message.h> 
#import "TweetMarkerClient.h"
#import "TweetMarkerAPI_KEY.h"

@interface TweetMarkerClient ()
@property (nonatomic,retain) NSObject<EchofonHTTPClient>* clientPost;
@property (nonatomic,retain) NSObject<EchofonHTTPClient>* clientGet;
@end

@implementation TweetMarkerClient {
    NSObject<EchofonHTTPClient>* clientPost;
    NSObject<EchofonHTTPClient>* clientGet;
    id<EchofonAccount> account;
    NSString* oauthConsumerKey;
    NSString* oauthConsumerSecret;
    NSString* oauthToken;
    NSString* oauthTokenSecret;
}

@synthesize clientPost, clientGet, account, oauthConsumerKey, oauthConsumerSecret, oauthToken,oauthTokenSecret;

-(void)dealloc {
    [clientPost release];
    [clientGet release];
    [oauthConsumerKey release];
    [oauthConsumerSecret release];
    [oauthToken release];
    [oauthTokenSecret release];
    [super dealloc];
}

-(void)HTTPClient:(id<EchofonHTTPClient>)client didFail:(id)error {
    NSLog(@"TweetMarkerClient %s",__func__);
}

-(void)HTTPClient:(id<EchofonHTTPClient>)client didReceiveResponse:(NSHTTPURLResponse*)response data:(NSData*)data {
    if (data && 200 == [response statusCode]) {
        NSString* statusIdsStrings = [[[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding]autorelease];
        if ([statusIdsStrings length]) {
            NSArray* statusIdStrings = [statusIdsStrings componentsSeparatedByString:@","];
            NSUInteger statusId = [[statusIdStrings objectAtIndex:0]longLongValue];
            if (statusId) {
                id<EchofonMainWindowController> mainWindowController = (id<EchofonMainWindowController>)[[[NSApplication sharedApplication]mainWindow]delegate];
                id<EchofonTimelineController> friends,mentions,directMessages;
                object_getInstanceVariable(mainWindowController, "friends", (void**)&friends);
                object_getInstanceVariable(mainWindowController, "mentions", (void**)&mentions);
                object_getInstanceVariable(mainWindowController, "directMessages", (void**)&directMessages);
                if (account.lastFriendsId < statusId) {
                    [account __setLastFriendsId:statusId];
                    [friends scrollToUnread];
                }
                if ([statusIdStrings count]>1) {
                    statusId = [[statusIdStrings objectAtIndex:1]longLongValue];
                    if (account.lastMentionsId < statusId) {
                        [account __setLastMentionsId:statusId];
                        [mentions scrollToUnread];
                    }
                    if ([statusIdStrings count]>2) {
                        statusId = [[statusIdStrings objectAtIndex:2]longLongValue];
                        if (account.lastMessagesId < statusId) {
                            [account __setLastMessagesId:statusId];
                            [directMessages scrollToUnread];
                        }
                    }
                }
            }
        }
    }
}

-(NSDictionary*)addOAuthParameters:(id)params url:(id<EchofonNSString>)url verb:(id<EchofonNSString>)verb {
    CFAbsoluteTime timestamp = CFAbsoluteTimeGetCurrent() + kCFAbsoluteTimeIntervalSince1970;
    
    NSMutableDictionary* dic = params ? [[params mutableCopy]autorelease] : [NSMutableDictionary dictionary];
    [dic setObject:oauthConsumerKey forKey:@"oauth_consumer_key"];
    [dic setObject:oauthToken forKey:@"oauth_token"];
    [dic setObject:[NSString stringWithFormat:@"%qi",timestamp] forKey:@"oauth_timestamp"];
    [dic setObject:@"HMAC-SHA1" forKey:@"oauth_signature_method"];
    [dic setObject:@"1.0" forKey:@"oauth_version"];
    CFUUIDRef uuid = CFUUIDCreate(kCFAllocatorDefault);
    CFStringRef uuidString = CFUUIDCreateString(kCFAllocatorDefault, uuid);
    [dic setObject:(NSString*)uuidString forKey:@"oauth_nonce"];
    CFRelease(uuidString);
    CFRelease(uuid);
    [dic setObject:[[NSString class] 
                    HMAC_SHA1SignatureForText:[NSString stringWithFormat:@"%@&%@&%@",
                                [verb encodeURIComponent],
                                [url encodeURIComponent],
                                [self formatSortedParameters:dic]]
                    usingSecret:[NSString stringWithFormat:@"%@&%@",
                                oauthConsumerSecret,
                                oauthTokenSecret]]
            forKey:@"oauth_signature"];
    return dic;
}

-(NSString*)formatSortedParameters:(NSDictionary*)params{
    if (!params) {
        return @"";
    };
    NSMutableArray* array = [NSMutableArray array];
    NSArray* keys = [[params allKeys]sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
    for (NSString* key in keys) {
        NSString<EchofonNSString>* value = [params objectForKey:key];
        [array addObject:[NSString stringWithFormat:@"%@=%@", key, [value encodeURIComponent]]];
    }
    return [array componentsJoinedByString:@"'&'"];
}

-(void)postCollections:(NSArray *)collections statusIds:(NSArray *)statusIds{
    [clientPost cancel];
    NSDictionary* oauthParams = [self addOAuthParameters:nil
                                                     url:(id<EchofonNSString>)@"https://api.twitter.com/1/account/verify_credentials.json"
                                                    verb:(id<EchofonNSString>)@"POST"];
    NSMutableString* credentials = [NSMutableString stringWithFormat:@"OAuth real=\"%@\"",@"http://api.twitter.com/"];
    for (NSString* key in oauthParams) {
        [credentials appendFormat:@",%@=\"%@\"", key, [[oauthParams objectForKey:key] encodeURIComponent]];
    }
    NSMutableDictionary* headers = [NSMutableDictionary dictionary];
    [headers setObject:@"https://api.twitter.com/1/account/verify_credentials.json" forKey:@"X-Auth-Service-Provider"];
    [headers setObject:credentials forKey:@"X-Verify-Credentials-Authorization"];
    
    self.clientPost = [[[NSClassFromString(@"HTTPClient") alloc]initWithDelegate:self]autorelease];
    clientPost.userAgent = [NSClassFromString(@"Preferences") userAgent];
    if (kTweetMarkerAPI_KEY) {
        NSString* collection = [collections componentsJoinedByString:@","];
        NSString* url = [NSString stringWithFormat:@"https://api.tweetmarker.net/v1/lastread?collection=%@&username=%@&user_id=%lu&api_key=%@",
                         collection,
                         account.username,
                         account.userId,
                         kTweetMarkerAPI_KEY];
        [clientPost post:url
                    body:[[statusIds componentsJoinedByString:@","]dataUsingEncoding:NSUTF8StringEncoding]
                  header:headers];
    }
}

-(void)getAllCollections {
    [clientGet cancel];
    self.clientGet = [[[NSClassFromString(@"HTTPClient") alloc]initWithDelegate:self]autorelease];
    clientGet.userAgent = [NSClassFromString(@"Preferences") userAgent];
    NSString* collection = [[NSArray arrayWithObjects:@"timeline", @"mentions", @"messages", nil] componentsJoinedByString:@","];
    NSDictionary* params = [NSDictionary dictionaryWithObjectsAndKeys:
                            collection, @"collection",
                            account.username, @"username",
                            [NSString stringWithFormat:@"%lu", account.userId], @"user_id",
                            kTweetMarkerAPI_KEY, @"api_key",
                            nil];
    [clientGet get:@"https://api.tweetmarker.net/v1/lastread" parameters:params];
}

@end
