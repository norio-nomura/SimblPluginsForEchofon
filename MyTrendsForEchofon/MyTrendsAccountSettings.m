//
//  MyTrendsAccountSettings.m
//  MyTrendsForEchofon
//

#import <objc/runtime.h>
#import "MyTrendsAccountSettings.h"

@implementation MyTrendsAccountSettings {
    id<EchofonTrendsConnection> _trendsConnection;
    id<EchofonHTTPClient> _client;
    NSDictionary* _settings;
}

@synthesize trendsConnection=_trendsConnection, client=_client, settings=_settings;

-(id)initWithTrendsConnection:(id<EchofonTrendsConnection>)trends
{
    if (self = [super init]) {
        self.trendsConnection = trends;
    }
    return self;
}

-(void)update
{
    self.client = [[(NSObject<EchofonHTTPClient>*)[NSClassFromString(@"HTTPClient") alloc]initWithDelegate:self]autorelease];
    _client.userAgent = [NSClassFromString(@"Preferences") userAgent];
    [_client setOauthConsumerKey:[_trendsConnection consumerToken]];
    [_client setOauthConsumerSecret:[_trendsConnection consumerSecret]];
    [_client setOauthToken:[_trendsConnection accessToken]];
    [_client setOauthTokenSecret:[_trendsConnection accessSecret]];
    [_client get:@"https://api.twitter.com/1.1/account/settings.json"];
}

-(void)HTTPClient:(id<EchofonHTTPClient>)client didFail:(id)error
{
}

-(void)HTTPClient:(id<EchofonHTTPClient>)client didReceiveResponse:(NSHTTPURLResponse*)response data:(NSData<EchofonNSData>*)data
{
    if (response.statusCode == 200 && data) {
        self.settings = [data JSONValue];
        NSString* woeid = @"1";
        if ([_settings isKindOfClass:[NSDictionary class]]) {
            NSArray* trendLocations = [_settings objectForKey:@"trend_location"];
            if ([trendLocations isKindOfClass:[NSArray class]]) {
                NSDictionary* trendLocation = [trendLocations objectAtIndex:0];
                if ([trendLocation isKindOfClass:[NSDictionary class]] && [trendLocation objectForKey:@"woeid"]) {
                    woeid = [trendLocation objectForKey:@"woeid"];
                }
            }
        }
        NSString* url = [NSString stringWithFormat:@"%@/trends/place.json", [_trendsConnection apiBase]];
        [_trendsConnection createConnection];
        id<EchofonHTTPClient> conn;
        object_getInstanceVariable(_trendsConnection, "conn", (void**)&conn);
        if (conn) {
            [conn get:url parameters:[NSDictionary dictionaryWithObject:[NSString stringWithFormat:@"%@", woeid] forKey:@"id"]];
        }
    }
}


@end
