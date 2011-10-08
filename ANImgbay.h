//
//  ANImgbay.h
//  SimpleScreenshot
//
//  Created by Alex Nichol on 3/31/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface ANImgbay : NSObject {
	NSImage * image;
}

- (id)initWithImage:(NSImage *)_image;
- (void)postInBackground;
- (void)backgroundThread:(NSImage *)data;

@end
