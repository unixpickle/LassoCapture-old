//
//  ANImgbay.h
//  SimpleScreenshot
//
//  Created by Alex Nichol on 3/31/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#define kImgbayPostURL @"http://aqnichol.com/img/post.php"

typedef enum {
	ANImgbayFormatPNG,
	ANImgbayFormatJPEG
} ANImgbayFormat;

typedef void (^ANImgbaySuccessCallback)(NSURL * imageURL);
typedef void (^ANImgbayFailureCallback)(NSString * error);

@interface ANImgbay : NSObject {
	NSImage * image;
	ANImgbaySuccessCallback callback;
	ANImgbayFailureCallback errorCallback;
	ANImgbayFormat format;
}

@property (readwrite) ANImgbayFormat format;
@property (copy) ANImgbaySuccessCallback callback;
@property (copy) ANImgbayFailureCallback errorCallback;

- (id)initWithImage:(NSImage *)anImage callback:(ANImgbaySuccessCallback)aCallback;
- (void)postInBackground;

@end
