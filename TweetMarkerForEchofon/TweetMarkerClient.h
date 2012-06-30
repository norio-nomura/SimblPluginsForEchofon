//
//  TweetMarkerClient.h
//  TweetMarkerForEchofon
//

#import <Cocoa/Cocoa.h>
#import "EchofonProtocols.h"

@protocol EchofonAccountExtended<EchofonAccount>

- (void)__setLastFriendsIdTweetMarkerForEchofon:(NSUInteger)status;
- (void)__setLastMentionsIdTweetMarkerForEchofon:(NSUInteger)status;
- (void)__setLastMessagesIdTweetMarkerForEchofon:(NSUInteger)status;

@end

@interface TweetMarkerClient : NSObject<EchofonHTTPClientDelegate>

@property (nonatomic,assign) id<EchofonAccount> account;
@property (nonatomic,copy) NSString *oauthConsumerKey;
@property (nonatomic,copy) NSString *oauthConsumerSecret;
@property (nonatomic,copy) NSString *oauthToken;
@property (nonatomic,copy) NSString *oauthTokenSecret;

-(void)postCollection:(NSString*)collection statusId:(NSUInteger)statusId;
-(void)getAllCollections;

@end
