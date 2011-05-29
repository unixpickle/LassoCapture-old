//
//  SimpleScreenshotAppDelegate.m
//  SimpleScreenshot
//
//  Created by Alex Nichol on 12/1/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "SimpleScreenshotAppDelegate.h"

NSData * ImagePNGData (NSImage * img) {
	NSBitmapImageRep * bits = [[img representations] objectAtIndex:0];
	
	NSData * data;
	data = [bits representationUsingType:NSPNGFileType
							  properties:nil];
	
	return data;
}

@implementation SimpleScreenshotAppDelegate

@synthesize screenshotWindow;
@synthesize cropped;

#pragma mark Keyboard Shortcuts

- (void)makeShift5 {
	ANKeyEvent * evt = [[ANKeyEvent alloc] init];
	[evt setTarget:self];
	[evt setSelector:@selector(takeClipboardSnapshot:)];
	[evt setKey_code:23];
	[evt setKey_command:YES];
	[evt setKey_control:NO];
	[evt setKey_option:NO];
	[evt setKey_shift:YES];
	[evt registerEvent];
	[evt release];
}

- (void)makeShift6 {
	ANKeyEvent * evt = [[ANKeyEvent alloc] init];
	[evt setTarget:self];
	[evt setSelector:@selector(takeLassoSnapshot:)];
	[evt setKey_code:22];
	[evt setKey_command:YES];
	[evt setKey_control:NO];
	[evt setKey_option:NO];
	[evt setKey_shift:YES];
	[evt registerEvent];
	[evt release];
}

- (void)makeShift7 {
	ANKeyEvent * evt = [[ANKeyEvent alloc] init];
	[evt setTarget:self];
	[evt setSelector:@selector(takeImgbaySnapshot:)];
	[evt setKey_code:26];
	[evt setKey_command:YES];
	[evt setKey_control:NO];
	[evt setKey_option:NO];
	[evt setKey_shift:YES];
	[evt registerEvent];
	[evt release];
}

#pragma mark Loading and Settings

- (void)startLoading {
	if (loadingWindow) return;
	NSRect frm = [[NSScreen mainScreen] frame];
	NSRect cent = NSMakeRect(frm.size.width / 2 - 100, frm.size.height / 2 - 100,
							 200, 200);
	NSWindow * window = [[NSWindow alloc] initWithContentRect:cent styleMask:NSBorderlessWindowMask
													  backing:NSBackingStoreBuffered defer:NO];
	[window setOpaque:NO];
	[window setContentView:loadingView];
	[window setBackgroundColor:[NSColor clearColor]];
	[window setLevel:CGShieldingWindowLevel()];
	[window makeKeyAndOrderFront:self];
	loadingWindow = window;
}
- (void)stopLoading {
	[loadingWindow orderOut:self];
	[loadingWindow release];
	loadingWindow = nil;
}

- (IBAction)settingChanged:(id)sender {
	// set ALL of the settings, no jk
	if (sender == setting_inverse) {
		[[SettingsController sharedSettings] setValue:[NSNumber numberWithBool:[setting_inverse state]]
											   forKey:@"inverse"];
	} else if (sender == setting_clipboardstroke) {
		[[SettingsController sharedSettings] setValue:[NSNumber numberWithBool:[setting_clipboardstroke state]]
											   forKey:@"clipboardstroke"];
	} else if (sender == setting_lassoclipboard) {
		[[SettingsController sharedSettings] setValue:[NSNumber numberWithBool:[setting_lassoclipboard state]]
											   forKey:@"lassoclipboard"];
	} else if (sender == setting_lassofile) {
		[[SettingsController sharedSettings] setValue:[NSNumber numberWithBool:[setting_lassofile state]]
											   forKey:@"lassofile"];
	} else if (sender == setting_lassocolor) {
		[[SettingsController sharedSettings] setColor:[setting_lassocolor color]
											   forKey:@"lassocolor"];
	} else if (sender == setting_lassothickness) {
		NSNumber * floatSetting = [NSNumber numberWithDouble:[setting_lassothickness doubleValue]];
		[[SettingsController sharedSettings] setValue:floatSetting
											   forKey:@"lassothickness"];
	} else {
		NSLog(@"Unknown object: %@", sender);
	}
}
- (IBAction)closeSettings:(id)sender {
	[settingsWindow orderOut:self];
}
- (void)loadSettings {
	// load the settings, one by one
	SettingsController * controller = [SettingsController sharedSettings];
	NSNumber * lassothickness = [controller valueForKey:@"lassothickness"];
	NSColor * lassocolor = [controller colorForKey:@"lassocolor"];
	BOOL inverse = [[controller valueForKey:@"inverse"] boolValue];
	BOOL clipboardstroke = [[controller valueForKey:@"clipboardstroke"] boolValue];
	BOOL lassoclipboard = [[controller valueForKey:@"lassoclipboard"] boolValue];
	BOOL lassofile = [[controller valueForKey:@"lassofile"] boolValue];
	
	[setting_lassofile setState:lassofile];
	[setting_lassoclipboard setState:lassoclipboard];
	[setting_lassocolor setColor:lassocolor];
	[setting_lassothickness setDoubleValue:[lassothickness doubleValue]];
	[setting_clipboardstroke setState:clipboardstroke];
	[setting_inverse setState:inverse];
	 
}

#pragma mark Menu Bar

- (void)takeClipboardSnapshot:(id)sender {
	
	if (![[[SettingsController sharedSettings] valueForKey:@"clipboardstroke"] boolValue]) {
		return;
	}
	
	if ([[NSFileManager defaultManager] fileExistsAtPath:@"/var/tmp/test.png"]) {
		[[NSFileManager defaultManager] removeItemAtPath:@"/var/tmp/test.png"
												   error:nil];

	}
	
	system("screencapture -i /var/tmp/test.png");
	NSImage * myImage = [[NSImage alloc] initWithContentsOfFile:@"/var/tmp/test.png"];
	
	if ([[[SettingsController sharedSettings] valueForKey:@"inverse"] boolValue]) {
		ANImageBitmapRep * invert = [[ANImageBitmapRep alloc] initWithImage:(id)myImage];
		[invert invertColors];
		[myImage release];
		myImage = [[invert image] retain];
		[invert release];
	}
	
	NSPasteboard * pb = [NSPasteboard generalPasteboard];
    NSArray * types = [NSArray arrayWithObjects:NSTIFFPboardType, nil];
	if (myImage) {
		[pb declareTypes:types owner:self];
		[pb setData:[myImage TIFFRepresentation] forType:NSTIFFPboardType];
	}
	
	[[NSFileManager defaultManager] removeItemAtPath:@"/var/tmp/test.png"
											   error:nil];
	
	[myImage release];
	
}

- (void)takeImgbaySnapshot:(id)sender {
	if ([[NSFileManager defaultManager] fileExistsAtPath:@"/var/tmp/test.png"]) {
		[[NSFileManager defaultManager] removeItemAtPath:@"/var/tmp/test.png"
												   error:nil];
	}
	
	system("screencapture -i /var/tmp/test.png");
	NSImage * myImage = [[NSImage alloc] initWithContentsOfFile:@"/var/tmp/test.png"];
	
	if ([[[SettingsController sharedSettings] valueForKey:@"inverse"] boolValue]) {
		ANImageBitmapRep * invert = [[ANImageBitmapRep alloc] initWithImage:(id)myImage];
		[invert invertColors];
		[myImage release];
		myImage = [[invert image] retain];
		[invert release];
	}
	
	ANImgbay * imagePost = [[ANImgbay alloc] initWithImage:(CIImage *)myImage];
	[imagePost postInBackground];
	[imagePost autorelease];
	
	[myImage release];
}

- (void)takeLassoSnapshot:(id)sender {
	ANMultiScreenManager * man = [[ANMultiScreenManager alloc] init];
	NSRect screenFrame = [man totalScreenRect];
	[man release];
	ScreenshotMaker * ssmaker = [[ScreenshotMaker alloc] initWithFrame:screenFrame];
	[ssmaker setDelegate:self];
	KeyWindow * sswindow = [[KeyWindow alloc] initWithContentRect:screenFrame
													  styleMask:NSBorderlessWindowMask
														backing:NSBackingStoreBuffered defer:NO];
	[sswindow setContentView:ssmaker];
	[sswindow setLevel:CGShieldingWindowLevel()];
	[sswindow makeKeyAndOrderFront:self];
	self.screenshotWindow = [sswindow autorelease];
	[ssmaker release];
	
	[self.screenshotWindow makeFirstResponder:ssmaker];
	[ssmaker becomeFirstResponder];
	
	ProcessSerialNumber num;
	GetFrontProcess(&lastProcess);
	GetCurrentProcess(&num);
	SetFrontProcess(&num);
}

- (void)quitApp:(id)sender {
	exit(0);
}
- (IBAction)settings:(id)sender {
	[settingsWindow makeKeyAndOrderFront:self];
	[settingsWindow makeMainWindow];
	// focus the process windows
	ProcessSerialNumber num;
	GetCurrentProcess(&num);
	SetFrontProcess(&num);
}
- (void)lasso:(id)sender {
	[self takeLassoSnapshot:self];
}

- (NSMenu *)createMenu {
    NSZone * menuZone = [NSMenu menuZone];
    NSMenu * menu = [[NSMenu allocWithZone:menuZone] init];
    NSMenuItem * menuItem;
	
    // Add To Items
    menuItem = [menu addItemWithTitle:@"Take Lasso Screenshot"
                               action:@selector(lasso:)
                        keyEquivalent:@""];
	[menuItem setTarget:self];
	menuItem = [menu addItemWithTitle:@"Settings"
                               action:@selector(settings:)
                        keyEquivalent:@""];
    [menuItem setTarget:self];
	menuItem = [menu addItemWithTitle:@"Quit"
                               action:@selector(quitApp:)
                        keyEquivalent:@""];
    [menuItem setTarget:self];
	
    return [menu autorelease];
}

#pragma mark Lifecycle

- (void)addToLoginItems:(NSString *)path hide:(BOOL)hide {
	NSString	 *loginwindow = @"loginwindow";
	NSUserDefaults	*u;
	NSMutableDictionary	*d;
	NSDictionary	*e;
	NSMutableArray	*a;
	/* get data from user defaults
	 (~/Library/Preferences/loginwindow.plist) */
	u = [[NSUserDefaults alloc] init];
	if(!(d = [[u persistentDomainForName:loginwindow] mutableCopyWithZone:NULL]))
		d = [[NSMutableDictionary alloc] initWithCapacity:1];
	if(!(a = [[d objectForKey:@"AutoLaunchedApplicationDictionary"] mutableCopyWithZone:NULL]))
		a = [[NSMutableArray alloc] initWithCapacity:1];
	/* build entry */
	e = [[NSDictionary alloc] initWithObjectsAndKeys:
		 [NSNumber numberWithBool:hide], @"Hide",
		 path, @"Path",
		 nil];
	/* add entry */
	if (e) {
		[a insertObject:e atIndex:0];
		[d setObject:a forKey:@"AutoLaunchedApplicationDictionary"];
	}
	/* update user defaults */
	[u removePersistentDomainForName:loginwindow];
	[u setPersistentDomain:d forName:loginwindow];
	[u synchronize];
	/* clean up */
	[e release];
	[a release];
	[d release];
	[u release];
}

- (void)awakeFromNib {
	// Insert code here to initialize your application 
	
	NSString * path = [[NSBundle mainBundle] executablePath];
	NSRange r = [path rangeOfString:@".app"];
	if (r.location != NSNotFound) {
		path = [path substringToIndex:r.location+r.length];
		[self addToLoginItems:path hide:NO];
	}
	
	
	NSRect screenFrame = [[NSScreen mainScreen] frame];
	// we have the frame.
	NSRect windowFrame = [settingsWindow frame];
	windowFrame.origin.x = screenFrame.size.width / 2 - windowFrame.size.width / 2;
	windowFrame.origin.y = screenFrame.size.height / 2 - windowFrame.size.height / 2;
	[settingsWindow setFrameOrigin:windowFrame.origin];
	
	[ANKeyEvent configureKeyboard];
	[self makeShift5];
	[self makeShift6];
	[self makeShift7];
	
	[loadingText setFont:[NSFont systemFontOfSize:24.0]];
	NSRect loadingTextFrame = [loadingText frame];
	loadingTextFrame.size.height = 50;
	[loadingText setFrame:loadingTextFrame];

	NSMenu * menu = [self createMenu];
    _statusItem = [[[NSStatusBar systemStatusBar]
                                   statusItemWithLength:NSSquareStatusItemLength] retain];
    [_statusItem setMenu:menu];
    [_statusItem setHighlightMode:YES];
    [_statusItem setToolTip:@"Screenie"];
    [_statusItem setImage:[NSImage imageNamed:@"smallicon.png"]];
	
	[self loadSettings];
}

- (void)setDone:(BOOL)d {
	[threadLock lock];
	done = d;
	[threadLock unlock];
}
- (BOOL)done {
	BOOL b;
	[threadLock lock];
	b = done;
	[threadLock unlock];
	return b;
}

#pragma mark Screenshot Maker

- (void)screenshotMaker:(id)sender 
		 cropPointsPath:(PointArray *)p 
			  fromImage:(NSImage *)bmp {
	// crop the image and save it
	// we need to start a loading bar
	void ** ptr = (void **)malloc(sizeof(void *) * 3);
	ptr[0] = p;
	ptr[1] = bmp;
	ptr[2] = NULL;
	
	[self.screenshotWindow orderOut:self];
	
	
	[self startLoading];
	
	threadLock = [[NSLock alloc] init];
	[self setDone:NO];
	[self performSelectorInBackground:@selector(cropThread:) 
						   withObject:[NSValue valueWithPointer:ptr]];
	while (true) {
		if ([self done]) {
			break;
		} else {
			NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
			NSDate * ndate = [NSDate dateWithTimeIntervalSinceNow:0.5];
			[[NSRunLoop mainRunLoop] runUntilDate:ndate];
			[pool drain];
		}
	}
	
	free(ptr);
	[threadLock release];
	threadLock = nil;
	
	
	NSData * png = pngData;
	if ([[[SettingsController sharedSettings] valueForKey:@"lassofile"] boolValue]) {
		NSString * name = [NSString stringWithFormat:@"Screenshot %@.png", [NSDate date]];
		[png writeToFile:[NSHomeDirectory() stringByAppendingFormat:@"/Desktop/%@", name] 
			  atomically:YES];	
	}
	if ([[[SettingsController sharedSettings] valueForKey:@"lassoclipboard"] boolValue]) {
		NSPasteboard * pb = [NSPasteboard generalPasteboard];
		NSArray * types = [NSArray arrayWithObjects:NSTIFFPboardType, nil];
		if (cropped) {
			[pb declareTypes:types owner:self];
			[pb setData:[cropped TIFFRepresentation] forType:NSTIFFPboardType];
		}
	}
	
	[cropped release];
	
	[self stopLoading];
	
	[pngData release];
	pngData = nil;
	
	// enable to restore process
	// SetFrontProcess(&lastProcess);
}
- (void)screenshotMakerDoneCrop:(id)sender {
	[self.screenshotWindow orderOut:self];
	self.screenshotWindow = nil;
}

- (void)cropThread:(NSValue *)value {
	NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
	
	void ** ptr = [value pointerValue];
	PointArray * arr = ptr[0];
	NSImage * image = ptr[1];
	image = [[[NSImage alloc] initWithData:[image TIFFRepresentation]] autorelease];
	
	// fix the warning that is all apple's fault!!!
	ANImageBitmapRep * irep = [[ANImageBitmapRep alloc] initWithImage:(CIImage *)image];
	CGSize sz = [irep size];
	NSSize mSize = *(NSSize *)&(sz);
	ANImageBitmapRep * irep2 = [[ANImageBitmapRep alloc] initWithSize:mSize];
	
	CGContextRef ctx = [irep2 graphicsContext];
	CGContextSaveGState(ctx);
	// here we will select the frame
	for	(int i = 0; i < arr->points_c; i++) {
		CGPoint p = arr->points_b[i];
		if (i == 0) {
			CGContextMoveToPoint(ctx, p.x, p.y);
		} else {
			CGContextAddLineToPoint(ctx, p.x, p.y);
		}
	}
	CGPoint p = arr->points_b[0];
	CGContextAddLineToPoint(ctx, p.x, p.y);
	
	CGContextClosePath(ctx);
	CGContextClip(ctx);
	CGImageRef mCGImage = [irep CGImage];
	CGContextDrawImage(ctx, CGRectMake(0, 0, [irep size].width, [irep size].height), mCGImage);
	CGImageRelease(mCGImage);
	CGContextRestoreGState(ctx);
	
	[irep2 setChanged];
	
	if ([[[SettingsController sharedSettings] valueForKey:@"inverse"] boolValue]) {
		[irep2 invertColors];
	}
	
	// find max and min
	CGPoint min = CGPointMake(100000, 100000);
	CGPoint max = CGPointMake(0, 0);
	
	for	(int i = 0; i < arr->points_c; i++) {
		CGPoint p = arr->points_b[i];
		if (p.x < min.x) min.x = p.x;
		if (p.y < min.y) min.y = p.y;
		if (p.x > max.x) max.x = p.x;
		if (p.y > max.y) max.y = p.y;
	}
	
	CGRect frm = CGRectMake(min.x, min.y, max.x - min.x, max.y - min.y);
	// crop it
	ANImageBitmapRep * irep3 = [irep2 cropWithFrame:frm];
	
	// now we loop through and inverse the alpha, making a mask
	
	cropped = [[irep3 image] retain];
	
	NSImage * anotherImage = [[NSImage alloc] initWithData:[cropped TIFFRepresentation]];
	pngData = [ImagePNGData(anotherImage) retain];
	[anotherImage release];
	
	[self setDone:YES];
	
	[irep2 release];
	[irep release];
	
	[pool drain];
}

@end
