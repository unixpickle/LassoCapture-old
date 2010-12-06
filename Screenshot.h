//
//  Screenshot.h
//  ScreenShotR
//
//  Created by Alex Nichol on 8/30/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Quartz/Quartz.h>
#import "ANMultiScreenManager.h"

@interface Screenshot : NSObject {
	NSOpenGLContext * mGLContext;
    void * mData;
    long mByteWidth, mWidth, mHeight;
}
- (void)flipImageData;
- (CGImageRef)createRGBImageFromBufferData;

- (id)initWithScreen:(NSScreen *)scrn;

- (void)readPartialScreenToBuffer:(size_t)width bufferHeight:(size_t)height bufferBaseAddress:(void *)baseAddress;
- (void)readFullScreenToBuffer;
- (NSImage *)capturedImage;

+ (NSImage *)imageFromCGImageRef:(CGImageRef)image;
+ (NSImage *)captureScreen;
+ (NSImage *)captureAllScreens;
@end
