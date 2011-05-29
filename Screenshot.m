//
//  Screenshot.m
//  ScreenShotR
//
//  Created by Alex Nichol on 8/30/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "Screenshot.h"


@implementation Screenshot
+ (NSImage *)imageFromCGImageRef:(CGImageRef)image {
    NSRect imageRect = NSMakeRect(0.0, 0.0, 0.0, 0.0);
    CGContextRef imageContext = nil;
    NSImage * newImage = nil;
	
    // Get the image dimensions.
    imageRect.size.height = CGImageGetHeight(image);
    imageRect.size.width = CGImageGetWidth(image);
	
    // Create a new image to receive the Quartz image data.
    newImage = [[NSImage alloc] initWithSize:imageRect.size];
    [newImage lockFocus];
	
    // Get the Quartz context and draw.
    imageContext = (CGContextRef)[[NSGraphicsContext currentContext]
								  graphicsPort];
    CGContextDrawImage(imageContext, * (CGRect *)&imageRect, image);
    [newImage unlockFocus];
	
	NSImage * returnImage = [[NSImage alloc] initWithData:[newImage TIFFRepresentation]];
	[newImage release];
	
    return [returnImage autorelease];
}
+ (NSImage *)captureAllScreens {
	// read through all displays
	NSMutableDictionary * screenshots = [[[NSMutableDictionary alloc] init] autorelease];
	NSArray * r = [NSScreen screens];
	int index = 0;
	for (NSScreen * scrn in [NSScreen screens]) {
		// capture the screen
		Screenshot * m = [[Screenshot alloc] initWithScreen:scrn];
		[m readFullScreenToBuffer];
		NSImage * image = [m capturedImage];
		[m release];
		m = nil;
		[screenshots setObject:image forKey:[NSNumber numberWithInt:index]];
		index += 1;
	}
	ANMultiScreenManager * man = [[ANMultiScreenManager alloc] init];
	NSRect totalFrame = [man totalScreenRect];
	[man release];
	NSPoint offset = totalFrame.origin;
	NSImage * image = [[NSImage alloc] initWithSize:totalFrame.size];
	[image lockFocus];
	for (NSNumber * screenI in screenshots) {
		NSScreen * screen = [r objectAtIndex:[screenI intValue]];
		NSRect frm = [screen frame];
		frm.origin.x -= offset.x;
		frm.origin.y -= offset.y;
		NSImage * image1 = [screenshots objectForKey:screenI];
		// alright, draw that sucker
		[image1 drawInRect:frm
				 fromRect:NSZeroRect 
				operation:NSCompositeSourceOver fraction:1];
	}
	[image unlockFocus];
	NSData * d = [image TIFFRepresentation];
	NSImage * newImage = [[NSImage alloc] initWithData:d];
	[image release];
	// now we have our large image
	return [newImage autorelease];
}
+ (NSImage *)captureScreen {
	
	return [Screenshot captureAllScreens];
	
	Screenshot * m = [[Screenshot alloc] initWithScreen:[NSScreen mainScreen]];
	[m readFullScreenToBuffer];
	NSImage * image = [m capturedImage];
	[m release];
	m = nil;
	return image;
}

- (void)flipImageData {
    long top, bottom;
    void * buffer;
    void * topP;
    void * bottomP;
    void * base;
    long rowBytes;
	
    top = 0;
    bottom = mHeight - 1;
    base = mData;
    rowBytes = mByteWidth;
    buffer = malloc(rowBytes);
    NSAssert(buffer != nil, @"malloc failure");
	
    while (top < bottom) {
        topP = (void *)((top * rowBytes) + (intptr_t)base);
        bottomP = (void *)((bottom * rowBytes) + (intptr_t)base);
		
        /*
		 * Save and swap scanlines.
		 *
		 * This code does a simple in-place exchange with a temp buffer.
		 * If you need to reformat the pixels, replace the first two bcopy()
		 * calls with your own custom pixel reformatter.
		 */
        bcopy(topP, buffer, rowBytes );
        bcopy(bottomP, topP, rowBytes );
        bcopy(buffer, bottomP, rowBytes );
		
        ++top;
        --bottom;
    }
    free(buffer);
}

// Create a RGB CGImageRef from our buffer data
- (CGImageRef)createRGBImageFromBufferData {
    CGColorSpaceRef cSpace = CGColorSpaceCreateWithName (kCGColorSpaceGenericRGB);
    NSAssert(cSpace != NULL, @"CGColorSpaceCreateWithName failure");
	
    CGContextRef bitmap = CGBitmapContextCreate(mData, mWidth, mHeight, 8, mByteWidth,
												cSpace,  
#if __BIG_ENDIAN__
												kCGImageAlphaNoneSkipFirst | kCGBitmapByteOrder32Big /* XRGB Big Endian */);
#else
	kCGImageAlphaNoneSkipFirst | kCGBitmapByteOrder32Little /* XRGB Little Endian */);
#endif                                    
    NSAssert(bitmap != NULL, @"CGBitmapContextCreate failure");
	
    // Get rid of color space
    CFRelease(cSpace);
	
    // Make an image out of our bitmap; does a cheap vm_copy of the  
    // bitmap
    CGImageRef image = CGBitmapContextCreateImage(bitmap);
    NSAssert(image != NULL, @"CGBitmapContextCreate failure");
	
    // Get rid of bitmap
    CFRelease(bitmap);
    
    return image;
}

#pragma mark ---------- Initialization ----------

- (id)initWithScreen:(NSScreen *)scrn {
	if (self = [super init]) {
		// Create a full-screen OpenGL graphics context
		
		CGDirectDisplayID dspID;
		unsigned int i;
		NSRect frm = [scrn frame];
		CGGetDisplaysWithRect(*(CGRect *)&frm, 1, &dspID, &i);
		
		
		// Specify attributes of the GL graphics context
		NSOpenGLPixelFormatAttribute attributes[] = {
			NSOpenGLPFAFullScreen,
			NSOpenGLPFAScreenMask,
			CGDisplayIDToOpenGLDisplayMask(dspID),
			(NSOpenGLPixelFormatAttribute) 0
		};
		
		NSOpenGLPixelFormat *glPixelFormat = [[NSOpenGLPixelFormat alloc] initWithAttributes:attributes];
		if (!glPixelFormat) {
			return nil;
		}
		
		// Create OpenGL context used to render
		mGLContext = [[[NSOpenGLContext alloc] initWithFormat:glPixelFormat shareContext:nil] autorelease];
		
		// Cleanup, pixel format object no longer needed
		[glPixelFormat release];
		
        if (!mGLContext) {
            [self release];
            return nil;
        }
        [mGLContext retain];
		
        // Set our context as the current OpenGL context
        [mGLContext makeCurrentContext];
        // Set full-screen mode
        [mGLContext setFullScreen];
		
		NSRect mainScreenRect = [scrn frame];
		mWidth = mainScreenRect.size.width;
		mHeight = mainScreenRect.size.height;
		
        mByteWidth = mWidth * 4;                // Assume 4 bytes/pixel for now
        mByteWidth = (mByteWidth + 3) & ~3;    // Align to 4 bytes
		
        mData = malloc(mByteWidth * mHeight);
        NSAssert(mData != 0, @"malloc failed");
	}
	return self;
}

- (id)init {
    if (self = [super init]) {
		// Create a full-screen OpenGL graphics context
		
		// Specify attributes of the GL graphics context
		NSOpenGLPixelFormatAttribute attributes[] = {
			NSOpenGLPFAFullScreen,
			NSOpenGLPFAScreenMask,
			CGDisplayIDToOpenGLDisplayMask(kCGDirectMainDisplay),
			(NSOpenGLPixelFormatAttribute) 0
		};
		
		NSOpenGLPixelFormat *glPixelFormat = [[NSOpenGLPixelFormat alloc] initWithAttributes:attributes];
		if (!glPixelFormat) {
			return nil;
		}
		
		// Create OpenGL context used to render
		mGLContext = [[[NSOpenGLContext alloc] initWithFormat:glPixelFormat shareContext:nil] autorelease];
		
		// Cleanup, pixel format object no longer needed
		[glPixelFormat release];
		
        if (!mGLContext) {
            [self release];
            return nil;
        }
        [mGLContext retain];
		
        // Set our context as the current OpenGL context
        [mGLContext makeCurrentContext];
        // Set full-screen mode
        [mGLContext setFullScreen];
		
		NSRect mainScreenRect = [[NSScreen mainScreen] frame];
		mWidth = mainScreenRect.size.width;
		mHeight = mainScreenRect.size.height;
		
        mByteWidth = mWidth * 4;                // Assume 4 bytes/pixel for now
        mByteWidth = (mByteWidth + 3) & ~3;    // Align to 4 bytes
		
        mData = malloc(mByteWidth * mHeight);
        NSAssert(mData != 0, @"malloc failed");
    }
    return self;
}

#pragma mark ---------- Screen Reader  ----------

// Perform a simple, synchronous full-screen read operation using glReadPixels(). 
// Although this is not the most optimal technique, it is sufficient for doing 
// simple one-shot screen grabs.
- (void)readFullScreenToBuffer {
    [self readPartialScreenToBuffer: mWidth bufferHeight: mHeight bufferBaseAddress: mData];
}

// Use this routine if you want to read only a portion of the screen pixels
- (void)readPartialScreenToBuffer:(size_t)width bufferHeight:(size_t)height bufferBaseAddress:(void *)baseAddress {
    // select front buffer as our source for pixel data
    glReadBuffer(GL_FRONT);
    
    //Read OpenGL context pixels directly.
	
    // For extra safety, save & restore OpenGL states that are changed
    glPushClientAttrib(GL_CLIENT_PIXEL_STORE_BIT);
    
    glPixelStorei(GL_PACK_ALIGNMENT, 4); /* Force 4-byte alignment */
    glPixelStorei(GL_PACK_ROW_LENGTH, 0);
    glPixelStorei(GL_PACK_SKIP_ROWS, 0);
    glPixelStorei(GL_PACK_SKIP_PIXELS, 0);
    
    //Read a block of pixels from the frame buffer
    glReadPixels(0, 0, width, height, GL_BGRA, 
				 GL_UNSIGNED_INT_8_8_8_8_REV,
				 baseAddress);
	
    glPopClientAttrib();
	
    //Check for OpenGL errors
    GLenum theError = GL_NO_ERROR;
    theError = glGetError();
    NSAssert1(theError == GL_NO_ERROR, @"OpenGL error 0x%04X", theError);
}

- (NSImage *)capturedImage {
    // glReadPixels writes things from bottom to top, but we
    // need a top to bottom representation, so we must flip
    // the buffer contents.
    [self flipImageData];
	
    // Create a Quartz image from our pixel buffer bits
    CGImageRef imageRef = [self createRGBImageFromBufferData];
	if (imageRef == 0) return nil;
	
	NSImage * ret = [Screenshot imageFromCGImageRef:imageRef];
	CGImageRelease(imageRef);
	return ret;
	/*
	 // Make full pathname to the desktop directory
	 NSString *desktopDirectory = nil;
	 NSArray *paths = NSSearchPathForDirectoriesInDomains
	 (NSDesktopDirectory, NSUserDomainMask, YES);
	 if ([paths count] > 0)  
	 {
	 desktopDirectory = [paths objectAtIndex:0];
	 }
	 
	 NSMutableString *fullFilePathStr = [NSMutableString stringWithString:desktopDirectory];
	 NSAssert(fullFilePathStr != nil, @"stringWithString failed");
	 [fullFilePathStr appendString:@"/ScreenSnapshot.tiff"];
	 
	 NSString *finalPath = [NSString stringWithString:fullFilePathStr];
	 NSAssert(finalPath != nil, @"stringWithString failed");
	 
	 CFURLRef url = CFURLCreateWithFileSystemPath (
	 kCFAllocatorDefault,
	 (CFStringRef)finalPath,
	 kCFURLPOSIXPathStyle,
	 false);
	 NSAssert(url != 0, @"CFURLCreateWithFileSystemPath failed");
	 // Save our screen bits to an image file on disk
	 
	 // Save the image to the file
	 CGImageDestinationRef dest = CGImageDestinationCreateWithURL(url, CFSTR("public.tiff"), 1, nil);
	 NSAssert(dest != 0, @"CGImageDestinationCreateWithURL failed");
	 
	 // Set the image in the image destination to be `image' with
	 // optional properties specified in saved properties dict.
	 CGImageDestinationAddImage(dest, imageRef, nil);
	 
	 bool success = CGImageDestinationFinalize(dest);
	 NSAssert(success != 0, @"Image could not be written successfully");
	 
	 CFRelease(dest);
	 CGImageRelease(imageRef);
	 CFRelease(url);
	 */
}

// Create a TIFF file on the desktop from our data buffer

#pragma mark ---------- Cleanup  ----------

- (void)dealloc {    
    // Get rid of GL context
    [NSOpenGLContext clearCurrentContext];
    // disassociate from full screen
    [mGLContext clearDrawable];
    // and release the context
    [mGLContext release];
	// release memory for screen data
	free(mData);
	
    [super dealloc];
}
@end
