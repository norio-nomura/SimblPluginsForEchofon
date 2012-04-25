//
//  ReadabilityClient.h
//  ReadabilityForEchofon
//

#import <Cocoa/Cocoa.h>
#import "EchofonProtocols.h"


@interface ReadabilityClient : NSObject<EchofonHTTPClientDelegate>

@property (nonatomic,copy) NSString *oauthConsumerKey;
@property (nonatomic,copy) NSString *oauthConsumerSecret;
@property (nonatomic,copy) NSString *username;
@property (nonatomic,copy) NSString *oauthToken;
@property (nonatomic,copy) NSString *oauthTokenSecret;
@property (nonatomic,assign) BOOL authorized;


-(id)initWithUserName:(NSString*)username;
-(void)requestToken;
-(void)accessToken:(NSString*)url;
-(void)addBookmark:(NSString*)url;

@end
