//
//  ANImgbay.m
//  SimpleScreenshot
//
//  Created by Alex Nichol on 3/31/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ANImgbay.h"

@interface ANImgbay (Private)

- (void)_postInBackground;
- (NSData *)_generatePostData:(NSString *)mime data:(NSData *)data;
- (NSURLRequest *)_generateRequestForPost:(NSData *)post;
- (NSString *)_responseStringForRequest:(NSURLRequest *)request;
- (NSURL *)_urlFromResponseString:(NSString *)response;
- (NSString *)_errorFromResponseString:(NSString *)response;

- (void)_callbackSuccess:(NSURL *)imageURL;
- (void)_callbackError:(NSString *)msg;

@end

@implementation ANImgbay

@synthesize format;
@synthesize callback;
@synthesize errorCallback;

- (id)initWithImage:(NSImage *)anImage callback:(ANImgbaySuccessCallback)aCallback {
	if ((self = [super init])) {
		image = [anImage retain];
		format = ANImgbayFormatPNG;
		self.callback = aCallback;
	}
	return self;
}

- (void)postInBackground {
	[NSThread detachNewThreadSelector:@selector(_postInBackground) toTarget:self withObject:nil];
}

#pragma mark - Private -

- (void)_postInBackground {
	NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
	
	NSString * mimeStr = @"image/png";
	NSData * data = nil;
	switch (self.format) {
		case ANImgbayFormatJPEG:
		{
			mimeStr = @"image/jpeg";
			NSData * tiffData = [image TIFFRepresentation];
			NSBitmapImageRep * imageRep = [NSBitmapImageRep imageRepWithData:tiffData];
			NSDictionary * properties = [NSDictionary dictionaryWithObject:[NSNumber numberWithFloat:1] forKey:NSImageCompressionFactor];
			data = [imageRep representationUsingType:NSJPEGFileType properties:properties];
			break;
		}
		case ANImgbayFormatPNG:
		{
			mimeStr = @"image/png";
			NSData * tiffData = [image TIFFRepresentation];
			NSBitmapImageRep * imageRep = [NSBitmapImageRep imageRepWithData:tiffData];
			data = [imageRep representationUsingType:NSPNGFileType properties:nil];
			break;
		}
		default:
			break;
	}
	
	if (!data) {
		[pool drain];
		return;
	}
	
	NSData * postData = [self _generatePostData:mimeStr data:data];
	NSURLRequest * request = [self _generateRequestForPost:postData];
	NSString * string = [self _responseStringForRequest:request];
	NSURL * url = [self _urlFromResponseString:string];
	if (url) {
		[self _callbackSuccess:url];
	} else {
		NSString * error = [self _errorFromResponseString:string];
		[self _callbackError:error];
	}
	
	[pool drain];
}

- (NSData *)_generatePostData:(NSString *)mime data:(NSData *)data {
	NSMutableData * postData = [[NSMutableData alloc] init];
	
	[postData appendData:[[mime stringByAppendingString:@"\n"] dataUsingEncoding:NSASCIIStringEncoding]];
	[postData appendData:data];
	
	return [postData autorelease];
}

- (NSURLRequest *)_generateRequestForPost:(NSData *)post {
	NSString * postLength = [NSString stringWithFormat:@"%lld", [post length]];
	NSMutableURLRequest * request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:kImgbayPostURL]
																 cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData
															 timeoutInterval:10];
	[request setHTTPMethod:@"POST"];
	[request setValue:postLength forHTTPHeaderField:@"Content-Length"];
	[request setValue:@"application/octet-stream" forHTTPHeaderField:@"Content-Type"];
	[request setHTTPBody:post];
	return [request autorelease];
}

- (NSString *)_responseStringForRequest:(NSURLRequest *)request {
	NSData * response = [NSURLConnection sendSynchronousRequest:request returningResponse:nil error:nil];
	if (!response) return nil;
	NSString * respString = [[NSString alloc] initWithData:response encoding:NSASCIIStringEncoding];
	return [respString autorelease];
}

- (NSURL *)_urlFromResponseString:(NSString *)response {
	if (!response) return nil;
	if ([response hasPrefix:@"("] && [response hasSuffix:@")"]) {
		NSRange range = NSMakeRange(1, [response length] - 2);
		return [NSURL URLWithString:[response substringWithRange:range]];
	}
	return nil;
}

- (NSString *)_errorFromResponseString:(NSString *)response {
	if (![response hasPrefix:@"["] || ![response hasPrefix:@"]"]) {
		return nil;
	}
	NSRange range = NSMakeRange(1, [response length] - 2);
	return [response substringWithRange:range];
}

- (void)_callbackSuccess:(NSURL *)imageURL {
	if (![[NSThread currentThread] isMainThread]) {
		[self performSelectorOnMainThread:@selector(_callbackSuccess:) withObject:imageURL waitUntilDone:NO];
		return;
	}
	if (self.callback) self.callback(imageURL);
}

- (void)_callbackError:(NSString *)msg {
	if (![[NSThread currentThread] isMainThread]) {
		[self performSelectorOnMainThread:@selector(_callbackError:) withObject:msg waitUntilDone:NO];
		return;
	}
	if (self.errorCallback) self.errorCallback(msg);
}

- (void)dealloc {
	[image release];
	self.callback = nil;
	self.errorCallback = nil;
	[super dealloc];
}

@end
