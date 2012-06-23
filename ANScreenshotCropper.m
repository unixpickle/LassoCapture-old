//
//  ANScreenshotCropper.m
//  SimpleScreenshot
//
//  Created by Alex Nichol on 10/23/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "ANScreenshotCropper.h"

#ifndef MIN
#define MIN(x,y) (x < y ? x : y)
#endif
#ifndef MAX
#define MAX(x,y) (x > y ? x : y)
#endif

NSData * NSImagePNGData (NSImage * img);

@interface ANScreenshotCropper (Private)

- (void)_cropInBackground;
- (void)_performCallback:(NSData *)image;

@end

@implementation ANScreenshotCropper

+ (void)cropScreenshotWithPoints:(PointArray *)parray
					   topWindow:(NSUInteger)windowNumber
						callback:(ANScreenshotCropperCallback)callback {
	BOOL invValue = [[[SettingsController sharedSettings] valueForKey:@"inverse"] boolValue];
	ANScreenshotCropper * cropper = [[ANScreenshotCropper alloc] initWithPointArray:parray windowNumber:windowNumber];
	[cropper cropScreenshotInBackground:callback
						   invertColors:invValue];
	[cropper release];
}

- (id)initWithPointArray:(PointArray *)parray windowNumber:(NSUInteger)winNumber {
	if ((self = [super init])) {
		windowNumber = winNumber;
		array = (PointArray *)malloc(sizeof(PointArray));
		array->lines = parray->lines;
		array->points_c = parray->points_c;
		array->points_f = parray->points_f;
		array->points_b = (CGPoint *)malloc(sizeof(CGPoint) * parray->points_f);
		memcpy(array->points_b, parray->points_b, sizeof(CGPoint) * parray->points_c);
	}
	return self;
}

- (void)cropScreenshotInBackground:(ANScreenshotCropperCallback)callback invertColors:(BOOL)_invert {
	invert = _invert;
	if (callbackFunct) {
		Block_release(callbackFunct);
	}
	callbackFunct = Block_copy(callback);
	[NSThread detachNewThreadSelector:@selector(_cropInBackground) toTarget:self
						   withObject:nil];
}

- (void)_cropInBackground {
	NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
	
    CGFloat minX = 0, maxX = 0, minY = 0, maxY = 0;
    for (NSScreen * screen in [NSScreen screens]) {
        CGRect frame = NSRectToCGRect(screen.frame);
        minX = MIN(minX, frame.origin.x);
        maxX = MAX(maxX, CGRectGetMaxX(frame));
        minY = MIN(minY, frame.origin.y);
        maxY = MAX(maxY, CGRectGetMaxY(frame));
    }
    
	CFArrayRef windows = CGWindowListCreate(kCGWindowListOptionOnScreenBelowWindow, windowNumber);
	CGImageRef screenShot = CGWindowListCreateImageFromArray(CGRectInfinite, windows, kCGWindowImageDefault);
	CFRelease(windows);
	// NSBitmapImageRep * bitmapRep = [[NSBitmapImageRep alloc] initWithCGImage:screenShot];
	// Create an NSImage and add the bitmap rep to it...
	CGFloat scale = 1;
    if (CGImageGetWidth(screenShot) > (maxX - minX) + 1) scale = 2;
    else if (CGImageGetHeight(screenShot) > (maxY - minY) + 1) scale = 2;
    
	NSImage * image = [[NSImage alloc] initWithCGImage:screenShot size:NSZeroSize];
	CGImageRelease(screenShot);
	
	ANImageBitmapRep * irep = [(ANImageBitmapRep *)[ANImageBitmapRep alloc] initWithImage:image];
	ANImageBitmapRep * newImage = [[ANImageBitmapRep alloc] initWithSize:[irep bitmapSize]];
	
	CGContextRef ctx = [newImage context];
	CGContextSaveGState(ctx);
	
    // scale the stuff
    for (int i = 0; i < array->points_c; i++) {
        CGPoint point = array->points_b[i];
        point.x *= scale;
        point.y *= scale;
        array->points_b[i] = point;
    }
    
	CGContextBeginPath(ctx);
	CGContextAddLines(ctx, array->points_b, array->points_c - 1);
	CGContextClosePath(ctx);
	CGContextClip(ctx);
	
	CGContextDrawImage(ctx, CGRectMake(0, 0, [irep bitmapSize].x, [irep bitmapSize].y), [irep CGImage]);
	CGContextRestoreGState(ctx);
	
	[newImage setNeedsUpdate:YES];
	[irep release];
	[image release];
	irep = nil;
	
	if (invert) {
		[newImage invertColors];
	}
	
	// find the minimum and maximum point for cropping
	CGPoint min = CGPointMake(FLT_MAX, FLT_MAX);
	CGPoint max = CGPointMake(FLT_MIN, FLT_MIN);
	
	for	(int i = 0; i < array->points_c; i++) {
		CGPoint p = array->points_b[i];
		if (p.x < min.x) min.x = p.x;
		if (p.y < min.y) min.y = p.y;
		if (p.x > max.x) max.x = p.x;
		if (p.y > max.y) max.y = p.y;
	}
	
	CGRect frm = CGRectMake(min.x, min.y, max.x - min.x, max.y - min.y);
	[newImage cropFrame:frm];
	
	NSImage * cropped = [newImage image];
	[newImage release];
	
	NSImage * freshImage = [[NSImage alloc] initWithData:[cropped TIFFRepresentation]];
	NSData * theData = NSImagePNGData(freshImage);
	
	[self performSelectorOnMainThread:@selector(_performCallback:) withObject:theData waitUntilDone:YES];
	[freshImage release];
	[pool drain];
}

- (void)_performCallback:(NSData *)theData {
	if (callbackFunct) {
		// create PNG data
		callbackFunct(theData);
	}
}

- (void)dealloc {
	point_array_free(array);
	free(array);
	Block_release(callbackFunct);
	[super dealloc];
}

@end

NSData * NSImagePNGData (NSImage * img) {
	NSBitmapImageRep * bits = [[img representations] objectAtIndex:0];
	
	NSData * data;
	data = [bits representationUsingType:NSPNGFileType
							  properties:nil];
	
	return data;
}
