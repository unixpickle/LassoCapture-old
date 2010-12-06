//
//  SimpleScreenshotAppDelegate.h
//  SimpleScreenshot
//
//  Created by Alex Nichol on 12/1/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Quartz/Quartz.h>
#import "Screenshot.h"
#import "ANKeyEvent.h"
#import "ANImageBitmapRep.h"
#import "ScreenshotMaker.h"
#import "ANMultiScreenManager.h"

@interface SimpleScreenshotAppDelegate : NSObject <ScreenshotMakerDelegate> {
    NSWindow * screenshotWindow;
	IBOutlet NSView * loadingView;
	IBOutlet NSTextField * loadingText;
	NSImage * cropped;
	BOOL done;
	NSLock * threadLock;
}

- (void)setDone:(BOOL)d;
- (BOOL)done;
- (void)cropThread:(NSValue *)value;
@property (nonatomic, retain) NSImage * cropped;
@property (nonatomic, retain) NSWindow * screenshotWindow;

@end
