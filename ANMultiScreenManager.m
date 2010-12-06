//
//  ANMultiScreenManager.m
//  SimpleScreenshot
//
//  Created by Alex Nichol on 12/5/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "ANMultiScreenManager.h"


@implementation ANMultiScreenManager
- (NSRect)totalScreenRect {
	NSRect frm = [[NSScreen mainScreen] frame];
	for (NSScreen * screen in [NSScreen screens]) {
		NSRect frm1 = [screen frame];
		if (frm1.origin.x < frm.origin.x) {
			int diff = frm.origin.x - frm1.origin.x;
			frm.origin.x -= diff;
			frm.size.width += diff;
		}
		if (frm1.origin.y < frm.origin.y) {
			int diff = frm.origin.y - frm1.origin.y;
			frm.origin.y -= diff;
			frm.size.height += diff;
		}
		if (frm1.origin.x + frm1.size.width > frm.origin.x + frm.size.width) {
			int diff = frm1.origin.x + frm1.size.width - (frm.origin.x + frm.size.width);
			frm.size.width += diff;
		}
		if (frm1.origin.y + frm1.size.height > frm.origin.y + frm.size.height) {
			int diff = frm1.origin.y + frm1.size.height - (frm.origin.y + frm.size.height);
			frm.size.height += diff;
		}
	}
	return frm;
}
@end
