//
//  TweetMarkerClient.m
//  TweetMarkerForEchofon
//

#import <objc/message.h> 
#import "TweetMarkerClient.h"
#import "TweetMarkerAPI_KEY.h"

@interface TweetMarkerClient ()
@property (nonatomic,retain) NSObject<EchofonHTTPClient> *clientPost;
@property (nonatomic,retain) NSObject<EchofonHTTPClient> *clientGet;
@end

@implementation TweetMarkerClient {
    NSObject<EchofonHTTPClient> *_clientPost;
    NSObject<EchofonHTTPClient> *_clientGet;
    id<EchofonAccount> _account;
    NSString *_oauthConsumerKey;
    NSString *_oauthConsumerSecret;
    NSString *_oauthToken;
    NSString *_oauthTokenSecret;
}

@synthesize clientPost=_clientPost, clientGet=_clientGet, account=_account, oauthConsumerKey=_oauthConsumerKey, oauthConsumerSecret=_oauthConsumerSecret, oauthToken=_oauthToken, oauthTokenSecret=_oauthTokenSecret;

-(void)dealloc
{
    [_clientPost release];
    [_clientGet release];
    [_oauthConsumerKey release];
    [_oauthConsumerSecret release];
    [_oauthToken release];
    [_oauthTokenSecret release];
    [super dealloc];
}

-(void)HTTPClient:(id<EchofonHTTPClient>)client didFail:(id)error
{
}

-(void)HTTPClient:(id<EchofonHTTPClient>)client didReceiveResponse:(NSHTTPURLResponse*)response data:(NSData<EchofonNSData>*)data
{
    if (data && 200 == [response statusCode]) {
        NSDictionary *json = [data JSONValue];
        if (json && [json isKindOfClass:[NSDictionary class]]) {
            BOOL changed = NO;
            id<EchofonAppController> appController = (id<EchofonAppController>)[[NSApplication sharedApplication]delegate];
            id<EchofonTimelineController> friends = [appController friends];
            id<EchofonTimelineController> mentions = [appController mentions];
            id<EchofonTimelineController> directMessages = [appController directMessages];
            NSUInteger statusId = 0;
            statusId = [[[json objectForKey:@"timeline"] objectForKey:@"id"]integerValue];
            if (_account.lastFriendsId < statusId) {
                [_account __setLastFriendsId:statusId];
                [friends scrollToUnread];
                changed = YES;
            }
            statusId = [[[json objectForKey:@"mentions"] objectForKey:@"id"]integerValue];
            if (_account.lastMentionsId < statusId) {
                [_account __setLastMentionsId:statusId];
                [mentions scrollToUnread];
                changed = YES;
            }
            statusId = [[[json objectForKey:@"messages"] objectForKey:@"id"]integerValue];
            if (_account.lastMessagesId < statusId) {
                [_account __setLastMessagesId:statusId];
                [directMessages scrollToUnread];
                changed = YES;
            }
            if (changed) {
                [[NSNotificationCenter defaultCenter]postNotificationName:@"AccountDidSyncNotification" object:_account];
            }
        }
    }
}

-(NSDictionary*)addOAuthParameters:(id)params url:(id<EchofonNSString>)url verb:(id<EchofonNSString>)verb
{
    CFAbsoluteTime timestamp = CFAbsoluteTimeGetCurrent() + kCFAbsoluteTimeIntervalSince1970;
    
    NSMutableDictionary* dic = params ? [[params mutableCopy]autorelease] : [NSMutableDictionary dictionary];
    [dic setObject:_oauthConsumerKey forKey:@"oauth_consumer_key"];
    [dic setObject:_oauthToken forKey:@"oauth_token"];
    [dic setObject:[NSString stringWithFormat:@"%0.0f",timestamp] forKey:@"oauth_timestamp"];
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
                                _oauthConsumerSecret,
                                _oauthTokenSecret]]
            forKey:@"oauth_signature"];
    return dic;
}

-(NSString*)formatSortedParameters:(NSDictionary*)params
{
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

-(void)postCollection:(NSString*)collection statusId:(NSUInteger)statusId
{
    [_clientPost cancel];
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
    _clientPost.userAgent = [NSClassFromString(@"Preferences") userAgent];
    if (kTweetMarkerAPI_KEY) {
        NSString* urlString = [NSString stringWithFormat:@"https://api.tweetmarker.net/v2/lastread?api_key=%@&username=%@",
                               kTweetMarkerAPI_KEY, _account.username];
        [_clientPost post:urlString
                    body:[[NSString stringWithFormat:@"{\"%@\":{\"id\":%lu}}",collection,statusId]dataUsingEncoding:NSUTF8StringEncoding]
                  header:headers];
    }
}

-(void)getAllCollections
{
    [_clientGet cancel];
    self.clientGet = [[[NSClassFromString(@"HTTPClient") alloc]initWithDelegate:self]autorelease];
    _clientGet.userAgent = [NSClassFromString(@"Preferences") userAgent];
    NSString* urlString = [NSString stringWithFormat:@"https://api.tweetmarker.net/v2/lastread?api_key=%@&username=%@&collection=timeline&collection=mentions&collection=messages", kTweetMarkerAPI_KEY, _account.username];
    [_clientGet get:urlString];
}

@end
