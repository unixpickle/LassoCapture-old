//
//  FocusManager.m
//  Pasties
//
//  Created by Alex Nichol on 7/3/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "FocusManager.h"


@implementation FocusManager

@synthesize secondaryMainApp;

+ (FocusManager *)sharedFocusManager {
	static FocusManager * man = nil;
	if (!man) man = [[FocusManager alloc] init];
	return man;
}
- (void)forceAppFocus {
	if (![[CarbonAppProcess currentProcess] isEqual:[CarbonAppProcess frontmostProcess]]) {
		[self setSecondaryMainApp:[CarbonAppProcess frontmostProcess]];
	}
	[[CarbonAppProcess currentProcess] makeFrontmost];
}
- (void)resignAppFocus {
	[self.secondaryMainApp makeFrontmost];
}

- (id)init {
    if ((self = [super init])) {
        // Initialization code here.
    }
    return self;
}

- (void)dealloc {
	self.secondaryMainApp = nil;
    [super dealloc];
}

@end
