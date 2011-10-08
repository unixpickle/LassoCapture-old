//
//  ScreenshotMaker.h
//  SimpleScreenshot
//
//  Created by Alex Nichol on 12/1/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "ANImageBitmapRep.h"
#import "SettingsController.h"

typedef struct {
	CGPoint * points_b;
	int points_c;
	int points_f;
} PointArray;

@protocol ScreenshotMakerDelegate
@optional

- (void)screenshotMaker:(id)sender cropPointsPath:(PointArray *)p;
- (void)screenshotMakerDoneCrop:(id)sender;

@end


@interface ScreenshotMaker : NSView {
	PointArray points; // used for storing points
	// this will crop our image
	float thickness;
	float components[4];
	id<ScreenshotMakerDelegate> delegate;	
}

@property (nonatomic, assign) id<ScreenshotMakerDelegate> delegate;

@end
