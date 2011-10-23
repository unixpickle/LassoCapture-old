//
//  PointArray.h
//  SimpleScreenshot
//
//  Created by Alex Nichol on 10/23/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#ifndef SimpleScreenshot_PointArray_h
#define SimpleScreenshot_PointArray_h

#import <Quartz/Quartz.h>

typedef struct {
	CGPoint * points_b;
	int points_c;
	int points_f;
	int lines;
} PointArray;

void point_array_init (PointArray * array);
void point_array_add (PointArray * array, CGPoint point);
void point_array_free (PointArray * array);

#endif
