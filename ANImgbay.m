//
//  ANImgbay.m
//  SimpleScreenshot
//
//  Created by Alex Nichol on 3/31/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ANImgbay.h"


@implementation ANImgbay

- (id)initWithImage:(NSImage *)_image {
	if (self = [super init]) {
		image = [_image retain];
	}
	return self;
}

- (void)postInBackground {
	NSImage * imageCopy = [image copy];
	NSThread * thread = [[NSThread alloc] initWithTarget:self
												selector:@selector(backgroundThread:)
												  object:imageCopy];
	[thread start];
	
	[thread release];
	[imageCopy release];
}

- (void)backgroundThread:(NSImage *)data {
	NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
	
	NSData * imageData = [data TIFFRepresentation];
	NSBitmapImageRep * imageRep = [NSBitmapImageRep imageRepWithData:imageData];
	NSDictionary * imageProps = [NSDictionary dictionaryWithObject:[NSNumber numberWithFloat:1] forKey:NSImageCompressionFactor];
	imageData = [imageRep representationUsingType:NSJPEGFileType properties:imageProps];
	
	NSString * postLength = [NSString stringWithFormat:@"%d", [imageData length]];
	NSMutableURLRequest * request = [[[NSMutableURLRequest alloc] init] autorelease];
	[request setURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://www.aqnichol.com/imgbay/post.php"]]];
	[request setHTTPMethod:@"POST"];
	[request setValue:postLength forHTTPHeaderField:@"Content-Length"];
	[request setValue:@"application/octet-stream" forHTTPHeaderField:@"Content-Type"];
	[request setHTTPBody:imageData];
	
	NSData * d;
	if (!(d = [NSURLConnection sendSynchronousRequest:request returningResponse:nil error:nil])) {
		NSLog(@"Error posting image to ImgBay");
		NSRunAlertPanel(@"Error", @"Your image could not be posted", @"OK", nil, nil);
	} else {
		NSString * str = [[NSString alloc] initWithData:d encoding:NSASCIIStringEncoding];
		if ([str isEqual:@"big"]) {
			NSRunAlertPanel(@"Error", @"Your image was over the size limit", @"OK", nil, nil);
			[str release];
		} else {
			NSString * uri = [[NSString alloc] initWithFormat:@"http://www.aqnichol.com/imgbay/%@", str];
			[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:uri]];
			[uri release];
		}
		[str release];
	}
	
	[pool drain];
}

- (void)dealloc {
	[image release];
	[super dealloc];
}

@end
