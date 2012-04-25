//
//  ReadabilityClient.m
//  ReadabilityForEchofon
//

#import <objc/message.h> 
#import "ReadabilityClient.h"
#import "ReadabilityAPI_KEY.h"

#define USER_OAUTH_SIGNATURE_METHOD_PLAINTEXT 1

@interface ReadabilityClient ()
@property (nonatomic,retain) NSObject<EchofonHTTPClient> *clientPost;
@property (nonatomic,retain) NSObject<EchofonHTTPClient> *clientOAuth;
@property (nonatomic,retain) NSMutableArray *urls;
@end

@implementation ReadabilityClient {
    NSObject<EchofonHTTPClient> *_clientPost;
    NSObject<EchofonHTTPClient> *_clientOAuth;
    NSString *_oauthConsumerKey;
    NSString *_oauthConsumerSecret;
    NSString *_username;
    NSString *_oauthToken;
    NSString *_oauthTokenSecret;
    NSMutableArray *_urls;
    BOOL _authorized;
}

@synthesize clientPost=_clientPost, clientOAuth=_clientOAuth, oauthConsumerKey=_oauthConsumerKey, oauthConsumerSecret=_oauthConsumerSecret, username=_username, oauthToken=_oauthToken, oauthTokenSecret=_oauthTokenSecret, urls=_urls, authorized=_authorized;

-(void)dealloc
{
    [_clientPost release];
    [_clientOAuth release];
    [_oauthConsumerKey release];
    [_oauthConsumerSecret release];
    [_username release];
    [_oauthToken release];
    [_oauthTokenSecret release];
    [_urls release];
    [super dealloc];
}

-(id)initWithUserName:(NSString *)username
{
    if (self = [super init]) {
        self.oauthConsumerKey = kReadabilityAPI_KEY;
        self.oauthConsumerSecret = kReadabilityAPI_SECRET;
        self.username = username;
        
        Class<EchofonKeychain> Keychain = (Class<EchofonKeychain>)NSClassFromString(@"Keychain");
        id password = [Keychain findInternetPasswordWithName:[NSString stringWithFormat:@"OAuthReadability-%@", _username]
                                                         url:[NSURL URLWithString:@"http://Echofon/"]];
        if (password) {
            NSDictionary *params = [self parseParams:password];
            self.oauthToken = [params objectForKey:@"oauth_token"];
            self.oauthTokenSecret = [params objectForKey:@"oauth_token_secret"];
            if ([_oauthTokenSecret length]) {
                _authorized = YES;
            } else {
                _authorized = NO;
                self.oauthTokenSecret = @"";
                [self requestToken];
            }
        } else {
            _authorized = NO;
            self.oauthTokenSecret = @"";
            [self requestToken];
        }
    }
    return self;
}

-(NSDictionary*)parseParams:(NSString*)containParams
{
    if (![containParams length]) {
        return nil;
    }
    NSMutableDictionary *dic = [NSMutableDictionary dictionary];
    NSArray *containParamsComponent = [containParams componentsSeparatedByString:@"?"];
    NSString *params;
    if (1 == [containParamsComponent count]) {
        params = [containParamsComponent objectAtIndex:0];
    } else {
        params = [containParamsComponent objectAtIndex:1];
    }
    NSArray *paramsComponent = [params componentsSeparatedByString:@"&"];
    for (NSString *param in paramsComponent) {
        NSArray *paramComponent = [param componentsSeparatedByString:@"="];
        if (1 == [paramComponent count]) {
            [dic setObject:@""
                    forKey:[paramComponent objectAtIndex:0]];
        } else {
            [dic setObject:[(NSString<EchofonNSString>*)[paramComponent objectAtIndex:1]decodeURIComponent]
                    forKey:[paramComponent objectAtIndex:0]];
        }
    }
    return dic;
}

-(void)HTTPClient:(id<EchofonHTTPClient>)client didFail:(id)error
{
    NSLog(@"client:%@\nerror:%@",client,error);
}

-(void)HTTPClient:(id<EchofonHTTPClient>)client didReceiveResponse:(NSHTTPURLResponse*)response data:(NSData<EchofonNSData>*)data
{
    NSLog(@"%@:%@", [NSHTTPURLResponse localizedStringForStatusCode:[response statusCode]], [response allHeaderFields]);
    if (data && 200 == [response statusCode]) {
        BOOL needAuthorize = ![self.oauthTokenSecret length];
        NSString *receivedOAuthToken, *receivedOAuthTokenSecret;
        
        NSString *body = [[[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding]autorelease];
        NSDictionary *params = [self parseParams:body];
        receivedOAuthToken = [params objectForKey:@"oauth_token"];
        receivedOAuthTokenSecret = [params objectForKey:@"oauth_token_secret"];
        
        if ([receivedOAuthToken length] && [receivedOAuthTokenSecret length]) {
            self.oauthToken = receivedOAuthToken;
            self.oauthTokenSecret = receivedOAuthTokenSecret;
            if (needAuthorize) {
                [(NSObject*)NSClassFromString(@"URLOpener") performSelector:@selector(openURLAndActivate:)
                                                                 withObject:[NSString stringWithFormat:@"%@api/rest/v1/oauth/authorize/?oauth_token=%@", kReadabilityBASE, _oauthToken]];
            } else {
                _authorized = YES;
                Class<EchofonKeychain> Keychain = (Class<EchofonKeychain>)NSClassFromString(@"Keychain");
                [Keychain setInternetPassword:body
                                         name:[NSString stringWithFormat:@"OAuthReadability-%@", _username]
                                          url:[NSURL URLWithString:@"http://Echofon/"]];
                @synchronized(self) {
                    if ([_urls count]) {
                        NSString *url = [_urls objectAtIndex:0];
                        [self postBookmark:url];
                        [_urls removeObjectAtIndex:0];
                    }
                }
            }
        }
    } else if (202 == [response statusCode]) {
        @synchronized(self) {
            if ([_urls count]) {
                NSString *url = [_urls objectAtIndex:0];
                [self postBookmark:url];
                [_urls removeObjectAtIndex:0];
            }
        }
    }
}

-(NSMutableDictionary*)addOAuthParameters:(NSDictionary*)params url:(id<EchofonNSString>)url verb:(id<EchofonNSString>)verb
{
    CFAbsoluteTime timestamp = CFAbsoluteTimeGetCurrent() + kCFAbsoluteTimeIntervalSince1970;
    
    NSMutableDictionary* dic = params ? [[params mutableCopy]autorelease] : [NSMutableDictionary dictionary];
    [dic setObject:_oauthConsumerKey forKey:@"oauth_consumer_key"];
    if (_oauthToken) {
        [dic setObject:_oauthToken forKey:@"oauth_token"];
    }
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
    return [(NSString<EchofonNSString>*)[array componentsJoinedByString:@"&"]encodeURIComponent];
}

-(void)postBookmark:(NSString*)url
{
    [_clientPost cancel];
    self.clientPost = [[[NSClassFromString(@"HTTPClient") alloc]initWithDelegate:self]autorelease];
    _clientPost.userAgent = [NSClassFromString(@"Preferences") userAgent];
    NSString *urlString = [NSString stringWithFormat:@"%@api/rest/v1/bookmarks", kReadabilityBASE];
    NSMutableDictionary *oauthParams = [self addOAuthParameters:nil
                                                     url:(id<EchofonNSString>)urlString
                                                    verb:(id<EchofonNSString>)@"POST"];
#ifdef USER_OAUTH_SIGNATURE_METHOD_PLAINTEXT
    [oauthParams setObject:@"PLAINTEXT" forKey:@"oauth_signature_method"];
    [oauthParams setObject:[NSString stringWithFormat:@"%@&%@", _oauthConsumerSecret, _oauthTokenSecret]
                    forKey:@"oauth_signature"];
#endif
    NSMutableString *oauthHeader = nil;
    for (NSString *key in oauthParams) {
        if (!oauthHeader) {
            oauthHeader = [NSMutableString stringWithFormat:@"OAuth realm=\"\", %@=\"%@\"", key, [[oauthParams objectForKey:key] encodeURIComponent]];
        } else {
            [oauthHeader appendFormat:@", %@=\"%@\"", key, [[oauthParams objectForKey:key] encodeURIComponent]];
        }
    }
    [_clientPost post:urlString
                body:[[NSString stringWithFormat:@"url=%@",[(NSString<EchofonNSString>*)url encodeURIComponent]]dataUsingEncoding:NSUTF8StringEncoding]
              header:[NSDictionary dictionaryWithObjectsAndKeys:oauthHeader, @"Authorization", nil]];
}

-(void)requestToken
{
    [_clientOAuth cancel];
    self.clientOAuth = [[[NSClassFromString(@"HTTPClient") alloc]initWithDelegate:self]autorelease];
    _clientOAuth.userAgent = [NSClassFromString(@"Preferences") userAgent];
    NSString *urlString = [NSString stringWithFormat:@"%@api/rest/v1/oauth/request_token/", kReadabilityBASE];
    NSDictionary *oauthParams = [self addOAuthParameters:[NSDictionary dictionaryWithObjectsAndKeys:
                                                          kReadabilityAPI_CALLBACK_URL, @"oauth_callback", nil]
                                                     url:(id<EchofonNSString>)urlString
                                                    verb:(id<EchofonNSString>)@"POST"];
    NSMutableString *oauthHeader = nil;    for (NSString *key in oauthParams) {

        if (!oauthHeader) {
            oauthHeader = [NSMutableString stringWithFormat:@"OAuth realm=\"\", %@=\"%@\"", key, [[oauthParams objectForKey:key] encodeURIComponent]];
        } else {
            [oauthHeader appendFormat:@", %@=\"%@\"", key, [[oauthParams objectForKey:key] encodeURIComponent]];
        }
    }
    [_clientOAuth post:urlString
                  body:nil
                header:[NSDictionary dictionaryWithObjectsAndKeys:oauthHeader, @"Authorization", nil]];
}

-(void)accessToken:(NSString*)url
{
    NSDictionary *params = [self parseParams:url];
    NSString *oauthVerifier = [params objectForKey:@"oauth_verifier"];
    self.oauthToken = [params objectForKey:@"oauth_token"];
    if ([oauthVerifier length]) {
        self.clientOAuth = [[[NSClassFromString(@"HTTPClient") alloc]initWithDelegate:self]autorelease];
        _clientOAuth.userAgent = [NSClassFromString(@"Preferences") userAgent];
        NSString *urlString = [NSString stringWithFormat:@"%@api/rest/v1/oauth/access_token/", kReadabilityBASE];
        NSDictionary *oauthParams = [self addOAuthParameters:[NSDictionary dictionaryWithObjectsAndKeys:oauthVerifier, @"oauth_verifier", nil]
                                                         url:(id<EchofonNSString>)urlString
                                                        verb:(id<EchofonNSString>)@"POST"];
        NSMutableString *oauthHeader = nil;        for (NSString *key in oauthParams) {

            if (!oauthHeader) {
                oauthHeader = [NSMutableString stringWithFormat:@"OAuth realm=\"\", %@=\"%@\"", key, [[oauthParams objectForKey:key] encodeURIComponent]];
            } else {
                [oauthHeader appendFormat:@", %@=\"%@\"", key, [[oauthParams objectForKey:key] encodeURIComponent]];
            }
        }
        [_clientOAuth post:urlString
                      body:nil
                    header:[NSDictionary dictionaryWithObjectsAndKeys:oauthHeader, @"Authorization", nil]];
    }
}

-(void)addBookmark:(NSString*)url
{
    if (!_urls) {
        self.urls = [NSMutableArray arrayWithObject:url];
    } else {
        [_urls addObject:url];
    }
    if (_authorized) {
        @synchronized(self) {
            if ([_urls count]) {
                NSString *url = [_urls objectAtIndex:0];
                [self postBookmark:url];
                [_urls removeObjectAtIndex:0];
            }
        }
    }
}

@end
