//
//  PointArray.c
//  SimpleScreenshot
//
//  Created by Alex Nichol on 10/23/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#include "PointArray.h"

void point_array_init (PointArray * array) {
	array->points_b = (CGPoint *)malloc(sizeof(CGPoint) * 512);
	array->points_c = 0;
	array->points_f = 512;
	array->lines = 0;
}

void point_array_add (PointArray * array, CGPoint point) {
	if (array->points_c + 1 > array->points_f) {
		// add points
		array->points_b = realloc(array->points_b,
								  (array->points_f + 512) * sizeof(CGPoint));
		array->points_f += 512;
	}
	array->points_b[array->points_c] = point;
	array->points_c += 1;
}

void point_array_free (PointArray * array) {
	free(array->points_b);
	bzero(array, sizeof(PointArray));
}
