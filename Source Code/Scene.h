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
#import <OpenGL/gl.h>

@class HeightField;
@class Camera;
@class SkyDome;

@interface Scene : NSObject
{
	HeightField *mHeightField;
	SkyDome *mSkyDome;
	Camera *mCamera;
	
    BOOL mWireFrame;
	BOOL mAnimate;
	float mSpeed;
	float mHillsHeight;
	float mLookAhead;
	float mCameraHeight;
	int mGridSize;
	float mFogDensity;
	GLfloat mFogColour[4];
}

- (id) init;
- (void) setViewportRect:(NSRect)bounds;
- (void) animate;
- (void) render;
- (void) setWireFrame:(bool)wireframe;
- (BOOL) getWireFrame;
- (void) dealloc;
- (void) setAnimationSpeed: (float)speed;
- (void) setHillsHeight: (float)height;
- (void) setLookAhead: (float)distance;
- (float)getLookAhead;
- (void) setCameraHeight: (float)height;
- (float) getCameraHeight;
- (void) setGridSize: (int)gridsize;
- (double) getAnimationSpeed;
- (void) setAnimate:(BOOL)animate;
- (BOOL) getAnimate;
- (void) setFogDensity: (float) fog_density;
- (void) setFogColour_red: (float)red green:(float)green blue:(float)blue alpha:(float)alpha;
- (Camera *) camera;

@end
