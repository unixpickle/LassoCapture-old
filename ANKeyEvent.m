//
//  ANKeyEvent.m
//  KeyShot
//
//  Created by Alex Nichol on 3/30/10.
//  Copyright 2010 Apple Inc. All rights reserved.
//

#ifndef _curkeyid
static int _curkeyid;
#endif

#import "ANKeyEvent.h"

static OSStatus myHotKeyHandler(EventHandlerCallRef nextHandler, EventRef anEvent, void *userData) {
	EventHotKeyID hkRef;
    GetEventParameter(anEvent,kEventParamDirectObject,typeEventHotKeyID,NULL,sizeof(hkRef),NULL,&hkRef);
	[[NSNotificationCenter defaultCenter] postNotificationName:[NSString stringWithFormat:@"key:%d", hkRef.id] object:nil];
	return noErr;
}

@implementation ANKeyEvent

@synthesize key_option;
@synthesize key_control;
@synthesize key_command;
@synthesize key_shift;
@synthesize key_code;
@synthesize selector, target;
@synthesize isRegistered;

+ (NSMutableArray *)keyEvents {
	static NSMutableArray * events = nil;
	if (!events) events = [[NSMutableArray alloc] init];
	return events;
}

+ (int)keyCodeForString:(NSString *)str {
	NSDictionary * keys = [[NSDictionary alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"keys" ofType:@"plist"]];
	NSArray * foo = [keys allKeysForObject:str];
	if ([foo count] > 0) return [[foo lastObject] intValue];
	return 0;
}

+ (void)configureKeyboard {
	EventTypeSpec eventType;
	eventType.eventClass = kEventClassKeyboard;
	eventType.eventKind = kEventHotKeyPressed;
	InstallApplicationEventHandler(&myHotKeyHandler, 1, &eventType, NULL, NULL);
	_curkeyid = 1;
}

- (NSString *)keyTitle {
	NSDictionary * keys = [[NSDictionary alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"keys" ofType:@"plist"]];
	return (NSString *)[keys objectForKey:[NSString stringWithFormat:@"%d", key_code]];
}

- (id)init {
	if (self = [super init]) {
		myHotKeyID.signature = 'mnky'; // sign ANKeyEvent
		myHotKeyID.id = _curkeyid;
		_curkeyid++;
		self.isRegistered = NO;
		[[ANKeyEvent keyEvents] addObject:self];
	}
	return self;
}
- (void)registerEvent {
	if (self.isRegistered) return;
	self.isRegistered = YES;
	int modifiers = 0;
	if (self.key_command) modifiers += cmdKey;
	if (self.key_option) modifiers += optionKey;
	if (self.key_control) modifiers += controlKey;
	if (self.key_shift) modifiers += shiftKey;
	RegisterEventHotKey(key_code, modifiers, myHotKeyID, GetApplicationEventTarget(), 0, &myHotKeyRef);
	[[NSNotificationCenter defaultCenter] addObserver:target selector:selector name:[NSString stringWithFormat:@"key:%d", myHotKeyID.id] object:nil];
}
- (void)unregisterEvent {
	self.isRegistered = NO;
	[[NSNotificationCenter defaultCenter] removeObserver:target name:[NSString stringWithFormat:@"key:%d", myHotKeyID.id] object:nil];
	UnregisterEventHotKey(myHotKeyRef);
}
- (void)dealloc {
	[self unregisterEvent];
	[[ANKeyEvent keyEvents] removeObject:self];
	[super edalloc];
}
@end
