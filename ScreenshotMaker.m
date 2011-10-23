//
//  ScreenshotMaker.m
//  SimpleScreenshot
//
//  Created by Alex Nichol on 12/1/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "ScreenshotMaker.h"

@implementation ScreenshotMaker

@synthesize delegate;

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
		point_array_init(&points);
		// screenshotImage = [[Screenshot captureScreen] retain];
		thickness = (int)[[[SettingsController sharedSettings] valueForKey:@"lassothickness"] floatValue];
		NSColor * c = [[SettingsController sharedSettings] colorForKey:@"lassocolor"];
		
		[self becomeFirstResponder];
		
		components[0] = [c redComponent];
		components[1] = [c greenComponent];
		components[2] = [c blueComponent];
		components[3] = [c alphaComponent];
		[[NSCursor crosshairCursor] set];
		[self addCursorRect:self.bounds cursor:[NSCursor crosshairCursor]];
    }
    return self;
}

- (void)cursorUpdate:(NSEvent *)event {
	NSCursor * custom = [[NSCursor alloc] initWithImage:[NSImage imageNamed:@"lasso.png"] hotSpot:NSMakePoint(3, 21)];
	[custom set];
	[custom release];
}

- (BOOL)canBecomeKeyView {
	return YES;
}

- (void)keyDown:(NSEvent *)theEvent {
	if ([theEvent keyCode] == 53) {
		// close the window
		[delegate screenshotMakerDoneCrop:self];
	}
}

- (void)mouseDown:(NSEvent *)theEvent {
	NSPoint p = [theEvent locationInWindow];
	CGPoint newP = CGPointMake(round(p.x), round(p.y));
	if (points.lines == 0) {
		point_array_add(&points, newP);
	} else {
		point_array_add(&points, newP);
		point_array_add(&points, newP);
	}
	points.lines ++;
	[self setNeedsDisplay:YES];
}

- (void)mouseDragged:(NSEvent *)theEvent {
	NSPoint p = [theEvent locationInWindow];
	CGPoint newP = CGPointMake(round(p.x), round(p.y));
	if (points.lines == 0) {
		point_array_add(&points, newP);
	} else {
		point_array_add(&points, newP);
		point_array_add(&points, newP);
	}
	points.lines ++;
	[self setNeedsDisplay:YES];
}

- (void)mouseUp:(NSEvent *)theEvent {
	// here we will save the image.
	if (points.points_c < 2) {
		[delegate screenshotMakerDoneCrop:self];
		point_array_free(&points);
		point_array_init(&points);
		return;
	}
	
	if ([(id)delegate respondsToSelector:@selector(screenshotMaker:cropPointsPath:)]) {
		[delegate screenshotMaker:self cropPointsPath:&points];
	}
	
	// tell the delegate to close us down
	if ([(id)delegate respondsToSelector:@selector(screenshotMakerDoneCrop:)]) {
		[delegate screenshotMakerDoneCrop:self];
	}
}

- (void)drawRect:(NSRect)dirtyRect {
	if (points.lines <= 1) return;
	
	CGContextRef context = [[NSGraphicsContext currentContext] graphicsPort];
	
	CGContextSaveGState(context);
	CGContextBeginPath(context);
	CGContextAddLines(context, points.points_b, points.points_c - 1);

	CGColorRef color = CGColorCreateGenericRGB(components[0], components[1], components[2], components[3]);
	CGContextSetStrokeColorWithColor(context, color);
	CGContextSetLineCap(context, kCGLineCapRound);
	CGContextSetLineWidth(context, thickness);
	
	CGContextStrokePath(context);
	CGColorRelease(color);

	CGContextRestoreGState(context);
}

- (void)dealloc {
	point_array_free(&points);
	[super dealloc];
}

@end
