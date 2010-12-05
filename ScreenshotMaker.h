//
//  ScreenshotMaker.h
//  SimpleScreenshot
//
//  Created by Alex Nichol on 12/1/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Screenshot.h"
#import "ANImageBitmapRep.h"

typedef struct {
	CGPoint * points_b;
	int points_c;
	int points_f;
} PointArray;

@protocol ScreenshotMakerDelegate
@optional

- (void)screenshotMaker:(id)sender 
		 cropPointsPath:(PointArray *)p 
			 fromImage:(NSImage *)bmp;
- (void)screenshotMakerDoneCrop:(id)sender;

@end


@interface ScreenshotMaker : NSView {
	// screenshotImage is where we store the screenshot
	NSImage * screenshotImage;
	PointArray points; // used for storing points
	// this will crop our image
	id<ScreenshotMakerDelegate> delegate;	
}
@property (nonatomic, assign) id<ScreenshotMakerDelegate> delegate;
@end
