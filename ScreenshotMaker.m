//
//  ScreenshotMaker.m
//  SimpleScreenshot
//
//  Created by Alex Nichol on 12/1/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "ScreenshotMaker.h"
#import "Screenshot.h"

@interface ScreenshotMaker (private)

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
		screenshotImage = [[Screenshot captureScreen] retain];
    }
    return self;
}

- (BOOL)canBecomeKeyView {
	return YES;
}

- (void)keyDown:(NSEvent *)theEvent {
	NSLog(@"%d", [theEvent keyCode]);
}

- (void)mouseDown:(NSEvent *)theEvent {
	// first point
	NSPoint p = [theEvent locationInWindow];
	[self addPoint:*(CGPoint *)&p];
}

- (void)mouseDragged:(NSEvent *)theEvent {
	NSPoint p = [theEvent locationInWindow];
	[self addPoint:*(CGPoint *)&p];
	[self setNeedsDisplay:YES];
}

- (void)mouseUp:(NSEvent *)theEvent {
	// here we will save the image.
	if (points.points_c < 2) {
		[self pointsFree];
		[self pointsInit];
		return;
	}
	if ([(id)delegate respondsToSelector:@selector(screenshotMaker:cropPointsPath:fromImage:)]) {
		// call it
		[delegate screenshotMaker:self cropPointsPath:&points fromImage:screenshotImage];
	}
	// tell the delegate to close us down
	if ([(id)delegate respondsToSelector:@selector(screenshotMakerDoneCrop:)]) {
		// call it
		[delegate screenshotMakerDoneCrop:self];
	}
}

- (void)drawRect:(NSRect)dirtyRect {
    // Drawing code here.
	// draw the ANImageBitmapContext
	
	
	CGContextRef context = [[NSGraphicsContext currentContext] graphicsPort];
	
	[screenshotImage drawInRect:[self bounds]
					   fromRect:NSZeroRect
					  operation:NSCompositeSourceOver fraction:1];
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
	
	
	CGContextSetStrokeColorWithColor(context, CGColorCreateGenericRGB(0, 1, 0, 1));
	CGContextSetLineCap(context, kCGLineCapRound);
	CGContextSetLineWidth(context, 5);
	CGContextStrokePath(context);
	
	CGContextRestoreGState(context);
}

- (void)dealloc {
	[self pointsFree];
	[screenshotImage release];
	[super dealloc];
}

@end

@implementation ScreenshotMaker (private)

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

