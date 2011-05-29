//
//  SimpleScreenshotAppDelegate.h
//  SimpleScreenshot
//
//  Created by Alex Nichol on 12/1/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Quartz/Quartz.h>
#import <Carbon/Carbon.h>
#import "Screenshot.h"
#import "ANKeyEvent.h"
#import "ANImageBitmapRep.h"
#import "ScreenshotMaker.h"
#import "ANMultiScreenManager.h"
#import "SettingsController.h"
#import "KeyWindow.h"
#import "ANImgbay.h"

@interface SimpleScreenshotAppDelegate : NSObject <ScreenshotMakerDelegate> {
    NSWindow * screenshotWindow;
	IBOutlet NSView * loadingView;
	IBOutlet NSTextField * loadingText;
	NSImage * cropped;
	NSData * pngData;
	BOOL done;
	NSLock * threadLock;
	NSWindow * loadingWindow;
	
	// settings
	IBOutlet NSButton * setting_inverse;
	IBOutlet NSButton * setting_lassoclipboard;
	IBOutlet NSButton * setting_lassofile;
	IBOutlet NSButton * setting_clipboardstroke;
	IBOutlet NSColorWell * setting_lassocolor;
	IBOutlet NSSlider * setting_lassothickness;
	IBOutlet NSWindow * settingsWindow;
	NSStatusItem * _statusItem;
	ProcessSerialNumber lastProcess;
}

- (void)makeShift5;
- (void)makeShift6;
- (void)makeShift7;

- (void)startLoading;
- (void)stopLoading;

- (IBAction)settingChanged:(id)sender;
- (IBAction)closeSettings:(id)sender;
- (void)loadSettings;

- (void)takeLassoSnapshot:(id)sender;
- (void)takeClipboardSnapshot:(id)sender;
- (void)takeImgbaySnapshot:(id)sender;

- (void)setDone:(BOOL)d;
- (BOOL)done;
- (void)cropThread:(NSValue *)value;
@property (nonatomic, retain) NSImage * cropped;
@property (nonatomic, retain) NSWindow * screenshotWindow;

@end
