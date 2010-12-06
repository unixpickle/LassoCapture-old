//
//  SettingsController.m
//  SimpleScreenshot
//
//  Created by Alex Nichol on 12/6/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "SettingsController.h"


@implementation SettingsController
- (id)init {
	if (self = [super init]) {
		settings = [[NSUserDefaults standardUserDefaults] retain];
		if (![settings objectForKey:@"_FIRSTLAUNCH_"]) {
			// read the settings from the default file
			[settings setObject:@"NO" forKey:@"_FIRSTLAUNCH_"];
			NSString * resourcePath = [[[NSBundle mainBundle] resourcePath] 
									   stringByAppendingPathComponent:kDefaultSettingsFile];
			NSDictionary * defaults = [[NSDictionary alloc] initWithContentsOfFile:resourcePath];
			for (id key in defaults) {
				[self setValue:[defaults objectForKey:key] forKey:key];
			}
			[defaults release];
		}
	}
	return self;
}
- (void)restoreToDefaults {
	// read the settings from the default file
	@synchronized (settings) {
		[settings setObject:@"NO" forKey:@"_FIRSTLAUNCH_"];
		NSString * resourcePath = [[[NSBundle mainBundle] resourcePath] 
								   stringByAppendingPathComponent:kDefaultSettingsFile];
		NSDictionary * defaults = [[NSDictionary alloc] initWithContentsOfFile:resourcePath];
		for (id key in defaults) {
			[self setValue:[defaults objectForKey:key] forKey:key];
		}
		[defaults release];
	}
}
- (void)setValue:(id)value forKey:(NSString *)key {
	@synchronized (settings) {
		[settings setObject:value forKey:key];
		[settings synchronize];
	}
}
- (id)valueForKey:(NSString *)key {
	id obj = nil;
	@synchronized (settings) {
		obj = [settings objectForKey:key];
	}
	return obj;
}
- (void)setColor:(NSColor *)color forKey:(NSString *)key {
	NSString * formatString = [NSString stringWithFormat:@"%f %f %f %f", 
							   [color redComponent], [color greenComponent], 
							   [color blueComponent], [color alphaComponent]];
	@synchronized (settings) {
		[settings setObject:formatString forKey:key];
		[settings synchronize];
	}
}
- (NSColor *)colorForKey:(NSString *)key {
	NSString * formatString = nil;
	@synchronized (settings) {
		formatString = [settings objectForKey:key];
	}
	NSArray * components = [formatString componentsSeparatedByString:@" "];
	if ([components count] == 4) {
		float c_components[4];
		for (int i = 0; i < 4; i++) {
			NSString * text = [components objectAtIndex:i];
			c_components[i] = [text floatValue];
		}
		return [NSColor colorWithDeviceRed:c_components[0]
									 green:c_components[1]
									  blue:c_components[2] alpha:c_components[3]];
	} else return nil;
}
+ (SettingsController *)sharedSettings {
	static SettingsController * controller = nil;
	if (!controller) {
		controller = [[SettingsController alloc] init];
	}
	return controller;
}
- (void)dealloc {
	[settings release];
	[super dealloc];
}
@end
