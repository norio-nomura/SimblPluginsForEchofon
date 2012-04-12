//
//  MyTrendsAccountSettings.m
//  MyTrendsForEchofon
//

#import <objc/runtime.h>
#import "MyTrendsAccountSettings.h"

@implementation MyTrendsAccountSettings {
    id<EchofonTrendsConnection> trendsConnection;
    id<EchofonHTTPClient> client;
    NSDictionary* settings;
}

@synthesize trendsConnection, client, settings;

-(id)initWithTrendsConnection:(id<EchofonTrendsConnection>)trends {
    if (self = [super init]) {
        self.trendsConnection = trends;
    }
    return self;
}

-(void)update {
    self.client = [(id<EchofonHTTPClient>)[NSClassFromString(@"HTTPClient") alloc]initWithDelegate:self];
    client.userAgent = [NSClassFromString(@"Preferences") userAgent];
    [client setOauthConsumerKey:[trendsConnection consumerToken]];
    [client setOauthConsumerSecret:[trendsConnection consumerSecret]];
    [client setOauthToken:[trendsConnection accessToken]];
    [client setOauthTokenSecret:[trendsConnection accessSecret]];
    [client get:@"https://api.twitter.com/1/account/settings.json"];
}

-(void)HTTPClient:(id<EchofonHTTPClient>)client didFail:(id)error {
}

-(void)HTTPClient:(id<EchofonHTTPClient>)client didReceiveResponse:(NSHTTPURLResponse*)response data:(NSData<EchofonNSData>*)data {
    if (response.statusCode == 200 && data) {
        self.settings = [data JSONValue];
        NSString* woeid = @"1";
        if ([settings isKindOfClass:[NSDictionary class]]) {
            NSArray* trendLocations = [settings objectForKey:@"trend_location"];
            if ([trendLocations isKindOfClass:[NSArray class]]) {
                NSDictionary* trendLocation = [trendLocations objectAtIndex:0];
                if ([trendLocation isKindOfClass:[NSDictionary class]] && [trendLocation objectForKey:@"woeid"]) {
                    woeid = [trendLocation objectForKey:@"woeid"];
                }
            }
        }
        NSString* url = [NSString stringWithFormat:@"%@/trends/%@.json", [trendsConnection apiBase], woeid];
        [trendsConnection createConnection];
        id<EchofonHTTPClient> conn;
        object_getInstanceVariable(trendsConnection, "conn", (void**)&conn);
        if (conn) {
            [conn get:url parameters:[NSDictionary dictionary]];
        }
    }
}


@end
