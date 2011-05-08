//	Copyright (c) 2006 Chris Kent
//
//	Hills is free software; you can redistribute it and/or modify
//	it under the terms of the GNU General Public License as published by
//	the Free Software Foundation; either version 2 of the License, or
//	(at your option) any later version.
//	
//	Hills is distributed in the hope that it will be useful,
//	but WITHOUT ANY WARRANTY; without even the implied warranty of
//	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//	GNU General Public License for more details.
//	
//	You should have received a copy of the GNU General Public License
//	along with Hills; if not, write to the Free Software
//	Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA

#import <Cocoa/Cocoa.h>

// cartesian coordinate system
typedef struct
{
	float x;
	float y;
	float z;
} CVector;

// spherical coordinate system
typedef struct
{
	float theta;
	float phi;
	float r;
} SVector;

@interface Camera : NSObject
{
	CVector mPosition;
	CVector mLookAt;
}

- (void) lookAt_x:(float)x y:(float)y z:(float)z;
- (void) positionAt_x:(float)x y:(float)y z:(float)z;
- (void) rotateByDegrees_x: (float)theta y: (float)phi;
- (void) moveForwards:(float)distance;
- (void) moveBackwards:(float)distance;
- (float) getDistance;
- (void) setDistance:(float)distance;
- (float) getXDegrees;
- (float) getYDegrees;
- (void) render;

@end
