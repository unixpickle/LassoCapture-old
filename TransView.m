//
//  TransView.m
//  SimpleScreenshot
//
//  Created by Alex Nichol on 12/5/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "TransView.h"


@implementation TransView


- (id)initWithFrame:(NSRect)frame {
    
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code.
    }
    return self;
}


// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(NSRect)rect {
    // Drawing code.
	CGContextRef context = [[NSGraphicsContext currentContext] graphicsPort];
	CGContextClearRect(context, *(CGRect *)&rect);
}


- (void)dealloc {
    [super dealloc];
}


@end
