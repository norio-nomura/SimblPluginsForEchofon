//
//  ReadabilityForEchofon.h
//  ReadabilityForEchofon
//

#import <Cocoa/Cocoa.h>

@class ReadabilityClient;

@interface ReadabilityForEchofon : NSObject

+ (ReadabilityForEchofon*) sharedInstance;
@property (nonatomic, retain) ReadabilityClient *client;

@end
