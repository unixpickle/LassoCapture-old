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
#import "PointArray.h"

@protocol ScreenshotMakerDelegate

- (void)screenshotMakerDoneCrop:(id)sender;

@optional
- (void)screenshotMaker:(id)sender cropPointsPath:(PointArray *)p;

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
