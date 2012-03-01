//
//  TweetMarkerClient.h
//  TweetMarkerForEchofon
//

#import <Cocoa/Cocoa.h>
#import "EchofonProtocols.h"


@interface TweetMarkerClient : NSObject<EchofonHTTPClientDelegate>

@property (nonatomic,assign) id<EchofonAccount> account;
@property (nonatomic,copy) NSString* oauthConsumerKey;
@property (nonatomic,copy) NSString* oauthConsumerSecret;
@property (nonatomic,copy) NSString* oauthToken;
@property (nonatomic,copy) NSString* oauthTokenSecret;

-(void)postCollections:(NSArray*)collections statusIds:(NSArray*)statusIds;
-(void)getAllCollections;

@end
