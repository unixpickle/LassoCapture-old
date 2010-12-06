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

- (void)takeSnapshot:(id)sender {
	system("screencapture -i /var/tmp/test.png");
	NSImage * myImage = [[NSImage alloc] initWithContentsOfFile:@"/var/tmp/test.png"];
	
	NSPasteboard * pb = [NSPasteboard generalPasteboard];
    NSArray * types = [NSArray arrayWithObjects:NSTIFFPboardType, nil];
	//NSString * str = [pb stringForType:NSTIFFPboardType];
	if (myImage) {
		[pb declareTypes:types owner:self];
		[pb setData:[myImage TIFFRepresentation] forType:NSTIFFPboardType];
	}
	
	[myImage autorelease];
	
}

- (void)takeSnapshot2:(id)sender {
	NSScreen * screen = [NSScreen mainScreen];
	ANMultiScreenManager * man = [[ANMultiScreenManager alloc] init];
	NSRect screenFrame = [man totalScreenRect];
	[man release];
	ScreenshotMaker * ssmaker = [[ScreenshotMaker alloc] initWithFrame:screenFrame];
	[ssmaker setDelegate:self];
	NSWindow * sswindow = [[NSWindow alloc] initWithContentRect:screenFrame
													  styleMask:NSBorderlessWindowMask
														backing:NSBackingStoreBuffered defer:NO];
	[sswindow setContentView:ssmaker];
	[sswindow setLevel:CGShieldingWindowLevel()];
	[sswindow makeKeyAndOrderFront:self];
	self.screenshotWindow = [sswindow autorelease];
	[ssmaker release];
}

- (void)makeShift5 {
	ANKeyEvent * evt = [[ANKeyEvent alloc] init];
	[evt setTarget:self];
	[evt setSelector:@selector(takeSnapshot:)];
	[evt setKey_code:23];
	[evt setKey_command:YES];
	[evt setKey_control:NO];
	[evt setKey_option:NO];
	[evt setKey_shift:YES];
	[evt registerEvent];
}

- (void)makeShift6 {
	ANKeyEvent * evt = [[ANKeyEvent alloc] init];
	[evt setTarget:self];
	[evt setSelector:@selector(takeSnapshot2:)];
	[evt setKey_code:22];
	[evt setKey_command:YES];
	[evt setKey_control:NO];
	[evt setKey_option:NO];
	[evt setKey_shift:YES];
	[evt registerEvent];
}

- (void)quitApp:(id)sender {
	exit(0);
}
- (void)lasso:(id)sender {
	[self takeSnapshot2:self];
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
	menuItem = [menu addItemWithTitle:@"Quit"
                               action:@selector(quitApp:)
                        keyEquivalent:@""];
    [menuItem setTarget:self];
	
    return menu;
}

- (void)awakeFromNib {
	// Insert code here to initialize your application 
	
	NSRect frm2 = [[[[ANMultiScreenManager alloc] init] autorelease] totalScreenRect];
	NSLog(@"%@", NSStringFromRect(frm2));
	
	
	[ANKeyEvent configureKeyboard];
	[self makeShift5];
	[self makeShift6];
	[loadingText setFont:[NSFont systemFontOfSize:24.0]];
	NSRect frm = [loadingText frame];
	frm.size.height = 50;
	[loadingText setFrame:frm];

	NSMenu * menu = [self createMenu];
    NSStatusItem * _statusItem = [[[NSStatusBar systemStatusBar]
                                   statusItemWithLength:NSSquareStatusItemLength] retain];
    [_statusItem setMenu:menu];
    [_statusItem setHighlightMode:YES];
    [_statusItem setToolTip:@"Screenie"];
    [_statusItem setImage:[NSImage imageNamed:@"smallicon.png"]];
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

- (void)cropThread:(NSValue *)value {
	NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
	
	void ** ptr = [value pointerValue];
	PointArray * arr = ptr[0];
	NSImage * image = ptr[1];
	image = [[[NSImage alloc] initWithData:[image TIFFRepresentation]] autorelease];
	
	
	ANImageBitmapRep * irep = [[ANImageBitmapRep alloc] initWithImage:image];
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
	[self setDone:YES];
	
	[irep2 release];
	[irep release];
	
	[pool drain];
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
	
	// convert it to PNG
	NSImage * anotherImage = [[NSImage alloc] initWithData:[cropped TIFFRepresentation]];
	[cropped release];
	NSData * png = ImagePNGData(anotherImage);
	[anotherImage release];
	NSString * name = [NSString stringWithFormat:@"Screenshot %@.png", [NSDate date]];
	[png writeToFile:[NSHomeDirectory() stringByAppendingFormat:@"/Desktop/%@", name] 
		  atomically:YES];	
	
	[window orderOut:self];
	[window release];
}
- (void)screenshotMakerDoneCrop:(id)sender {
	[self.screenshotWindow orderOut:self];
	self.screenshotWindow = nil;
}

@end
