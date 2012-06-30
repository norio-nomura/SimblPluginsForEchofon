//
//  DisableMarkAsReadCurrentTab.h
//  DisableMarkAsReadCurrentTab
//

#import <Cocoa/Cocoa.h>

@interface DisableMarkAsReadCurrentTab : NSObject

+ (DisableMarkAsReadCurrentTab*) sharedInstance;
@property (atomic,assign) BOOL disableAccountClassSetLastMethods;

@end
