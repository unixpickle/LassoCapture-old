//
//  ANScreenshotCropper.h
//  SimpleScreenshot
//
//  Created by Alex Nichol on 10/23/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "ANImageBitmapRep.h"
#import "PointArray.h"
#import "SettingsController.h"

typedef void (^ANScreenshotCropperCallback) (NSData * pngData);

@interface ANScreenshotCropper : NSObject {
	PointArray * array;
	NSUInteger windowNumber;
	BOOL invert;
	ANScreenshotCropperCallback callbackFunct;
}

+ (void)cropScreenshotWithPoints:(PointArray *)parray
					   topWindow:(NSUInteger)windowNumber
						callback:(ANScreenshotCropperCallback)callback;

/**
 * Create a new screenshot cropper with a point array.
 * @param parray The point array to be used for cropping. This will be copied
 * @param winNumber The window under which all windows will be captured in the
 * screenshot.
 * by the screenshot cropper.
 */
- (id)initWithPointArray:(PointArray *)parray windowNumber:(NSUInteger)winNumber;
- (void)cropScreenshotInBackground:(ANScreenshotCropperCallback)callback invertColors:(BOOL)inverse;

@end
