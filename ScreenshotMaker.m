//
//  ScreenshotMaker.m
//  SimpleScreenshot
//
//  Created by Alex Nichol on 12/1/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "ScreenshotMaker.h"

@interface ScreenshotMaker (Private)

- (void)addPoint:(CGPoint)p;
- (void)pointsInit;
- (void)pointsFree;

@end

@implementation ScreenshotMaker

@synthesize delegate;

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
		[self pointsInit];
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
	// first point
	NSPoint p = [theEvent locationInWindow];
	[self addPoint:CGPointMake(round(p.x), round(p.y))];
	[self setNeedsDisplay:YES];
}

- (void)mouseDragged:(NSEvent *)theEvent {
	NSPoint p = [theEvent locationInWindow];
	[self addPoint:CGPointMake(round(p.x), round(p.y))];
	[self setNeedsDisplay:YES];
}

- (void)mouseUp:(NSEvent *)theEvent {
	// here we will save the image.
	if (points.points_c < 2) {
		[self pointsFree];
		[self pointsInit];
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
    // Drawing code here.
	// draw the ANImageBitmapContext
	
	
	CGContextRef context = [[NSGraphicsContext currentContext] graphicsPort];
	
	// draw lines
	CGContextSaveGState(context);
	CGContextBeginPath(context);
	// draw lines
	for (int i = 0; i < points.points_c; i++) {
		CGPoint p = points.points_b[i];
		if (i == 0) {
			CGContextMoveToPoint(context, p.x, p.y);
		} else {
			CGContextAddLineToPoint(context, p.x, p.y);
			
		}
	}
	
	
	CGColorRef color = CGColorCreateGenericRGB(components[0], components[1], components[2], components[3]);
	CGContextSetStrokeColorWithColor(context, color);
	CGContextSetLineCap(context, kCGLineCapRound);
	CGContextSetLineWidth(context, thickness);
	CGContextStrokePath(context);
	CGColorRelease(color);
	
	CGContextRestoreGState(context);
}

- (void)dealloc {
	[self pointsFree];
	[super dealloc];
}

@end

@implementation ScreenshotMaker (Private)

- (void)addPoint:(CGPoint)p {
	if (points.points_c + 1 > points.points_f) {
		// add points
		points.points_b = realloc(points.points_b,
								  (points.points_f + 512) * sizeof(CGPoint));
	}
	points.points_b[points.points_c] = p;
	points.points_c += 1;
}

- (void)pointsInit {
	points.points_c = 0;
	points.points_f = 512;
	points.points_b = (CGPoint *)malloc((sizeof(CGPoint) * 512) + 1);
	bzero(points.points_b, (sizeof(CGPoint) * 512) + 1);
}

- (void)pointsFree {
	free(points.points_b);
	points.points_c = 0;
	points.points_b = NULL;
	points.points_f = 0;
}

@end

