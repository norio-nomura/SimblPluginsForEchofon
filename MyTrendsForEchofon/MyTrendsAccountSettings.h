//
//  MyTrendsAccountSettings.h
//  MyTrendsForEchofon
//

#import <Cocoa/Cocoa.h>
#import "EchofonProtocols.h"

@interface MyTrendsAccountSettings : NSObject<EchofonHTTPClientDelegate>

@property (assign) id<EchofonTrendsConnection> trendsConnection;
@property (retain) id<EchofonHTTPClient> client;
@property (retain) NSObject* settings;

-(id)initWithTrendsConnection:(id<EchofonTrendsConnection>)trends;
-(void)update;

@end
