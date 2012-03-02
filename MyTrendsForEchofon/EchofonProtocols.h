//
//  EchofonProtocols.h
//  MyTrendsForEchofon
//

#import <Cocoa/Cocoa.h>

@protocol EchofonNSData

- (id)JSONValue;

@end

@protocol EchofonHTTPClient;

@protocol EchofonHTTPClientDelegate

-(void)HTTPClient:(id<EchofonHTTPClient>)client didFail:(id)error;
-(void)HTTPClient:(id<EchofonHTTPClient>)client didReceiveResponse:(NSHTTPURLResponse*)response data:(NSData<EchofonNSData>*)data;

@end

@protocol EchofonHTTPClient

@property (copy) NSString* userAgent;
@property (assign) id<EchofonHTTPClientDelegate> delegate;
@property (copy) NSString* oauthConsumerKey;
@property (copy) NSString* oauthConsumerSecret;
@property (copy) NSString* oauthToken;
@property (copy) NSString* oauthTokenSecret;

- (id<EchofonHTTPClient>)initWithDelegate:(id<EchofonHTTPClientDelegate>)delegate;
- (void)post:(NSString*)url body:(NSData*)body header:(NSDictionary*)header;
- (void)get:(NSString*)url;
- (void)get:(NSString*)url parameters:(NSDictionary*)params;

@end

@protocol EchofonTrendsConnection<EchofonHTTPClientDelegate>

@property (copy) NSString* consumerToken;
@property (copy) NSString* consumerSecret;
@property (copy) NSString* accessToken;
@property (copy) NSString* accessSecret;

- (NSString*)apiBase;
- (void)createConnection;

@end
