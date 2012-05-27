//
//  EchofonProtocols.h
//  TweetMarkerForEchofon
//

#import <Cocoa/Cocoa.h>

@protocol EchofonKeychain
+ (void)addInternetPassword:(NSString*)password name:(NSString*)name url:(NSURL*)url;
+ (void)deleteInternetPasswordWithName:(NSString*)name url:(NSURL*)url;
+ (NSString*)findInternetPasswordWithName:(NSString*)name url:(NSURL*)url;
+ (NSString*)findInternetPasswordWithName:(NSString*)name url:(NSURL*)url status:(id)status;
+ (void)setInternetPassword:(NSString*)password name:(NSString*)name url:(NSURL*)url;
+ (void)testInternetPasswordWithName:(NSString*)name url:(NSURL*)url;
@end

@protocol EchofonNSData

- (NSDictionary*)JSONValue;

@end

@protocol EchofonNSString

+ (NSString<EchofonNSString>*)HMAC_SHA1SignatureForText:(NSString<EchofonNSString>*)text usingSecret:(NSString<EchofonNSString>*)secret;
- (NSString<EchofonNSString>*)decodeURIComponent;
- (NSString<EchofonNSString>*)encodeURIComponent;

@end

@protocol EchofonAccount

@property (copy) NSString* username;
@property (assign) NSUInteger userId;
@property (copy) NSString* oauthToken;
@property (copy) NSString* oauthTokenSecret;
@property (assign) NSUInteger lastFriendsId;
@property (assign) NSUInteger lastMentionsId;
@property (assign) NSUInteger lastMessagesId;

- (void)__setLastFriendsId:(NSUInteger)status;
- (void)__setLastMentionsId:(NSUInteger)status;
- (void)__setLastMessagesId:(NSUInteger)status;

@end

@protocol EchofonAccountsManager

- (id<EchofonAccount>)currentAccount;

@end

@protocol EchofonAccountsController

@property (retain) id<EchofonAccount> account;

@end

@protocol EchofonTimelineController

- (void)scrollToUnread;

@end

@protocol EchofonMenuController

- (NSMenu*)urlMenu;
- (NSString<EchofonNSString>*)selectedUrl;

@end

@protocol EchofonAppController

- (id<EchofonMenuController>)menu;
- (void)handleURLEvent:(NSAppleEventDescriptor *)event withReplyEvent: (NSAppleEventDescriptor *)replyEvent;
- (id<EchofonTimelineController>)friends;
- (id<EchofonTimelineController>)mentions;
- (id<EchofonTimelineController>)directMessages;

@end

@protocol EchofonTwitterClient

@property (copy) NSString* consumerToken;
@property (copy) NSString* consumerSecret;

@end

@protocol EchofonHTTPClient;

@protocol EchofonHTTPClientDelegate

- (void)HTTPClient:(id<EchofonHTTPClient>)client didFail:(id)error;
- (void)HTTPClient:(id<EchofonHTTPClient>)client didReceiveResponse:(NSHTTPURLResponse*)response data:(NSData<EchofonNSData>*)data;

@end

@protocol EchofonHTTPClient

@property (copy) NSString* userAgent;
@property (assign) id<EchofonHTTPClientDelegate> delegate;
@property (copy) NSString* oauthConsumerKey;
@property (copy) NSString* oauthConsumerSecret;
@property (copy) NSString* oauthToken;
@property (copy) NSString* oauthTokenSecret;

- (id<EchofonHTTPClient>)initWithDelegate:(id<EchofonHTTPClientDelegate>)delegate;
- (void)cancel;
- (void)post:(NSString*)url body:(NSData*)body header:(NSDictionary*)header;
- (void)get:(NSString*)url;
- (void)get:(NSString*)url parameters:(NSDictionary*)params;
- (void)get:(NSString*)url parameters:(NSDictionary*)params header:(NSDictionary*)header;

@end

@protocol EchofonTrendsConnection<EchofonHTTPClientDelegate>

@property (copy) NSString* consumerToken;
@property (copy) NSString* consumerSecret;
@property (copy) NSString* accessToken;
@property (copy) NSString* accessSecret;

- (NSString*)apiBase;
- (void)createConnection;

@end
