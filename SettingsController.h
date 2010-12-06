//
//  SettingsController.h
//  SimpleScreenshot
//
//  Created by Alex Nichol on 12/6/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#define kDefaultSettingsFile @"default.plist"

@interface SettingsController : NSObject {
	NSUserDefaults * settings;
}
- (void)restoreToDefaults;
- (void)setValue:(id)value forKey:(NSString *)key;
- (id)valueForKey:(NSString *)key;
- (void)setColor:(NSColor *)color forKey:(NSString *)key;
- (NSColor *)colorForKey:(NSString *)key;
+ (SettingsController *)sharedSettings;
@end
