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

#import "Scene.h"
#import <OpenGL/glu.h>
#import "Camera.h"
#import "HeightField.h"
#import "SkyDome.h"

#ifdef SCREENSAVER
#import <ScreenSaver/ScreenSaverDefaults.h>
#endif

// The time value is a static member so that the animation is synchronised
// between the screensaver preview and when you test it in full-screen mode.
static double smTime = 0.0f;
static NSTimeInterval sLastFrameTime = 0.0;


@implementation Scene

- (id)init
{
    self = [super init];
	
    if (self)
	{
		mHeightField = nil;
		mSkyDome = nil;
		mCamera = [[Camera alloc] init];
		mWireFrame = NO;
		mAnimate = YES;

#ifdef SCREENSAVER
		NSString *identifier = [[NSBundle bundleForClass:[self class]] bundleIdentifier];
		ScreenSaverDefaults *defaults = [ScreenSaverDefaults defaultsForModuleWithName:identifier];    
#else
		NSString *defaultspath = [[NSBundle mainBundle] pathForResource: DEFAULTS_FILENAME ofType: DEFAULTS_FILETYPE];
		NSDictionary *base_defaults = [NSDictionary dictionaryWithContentsOfFile: defaultspath];
		[[NSUserDefaults standardUserDefaults] registerDefaults: base_defaults];
		NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
#endif

 		mSpeed = [defaults floatForKey:SPEED_KEY];
		mLookAhead = [defaults floatForKey:LOOK_AHEAD_KEY];
		mHillsHeight = [defaults floatForKey:HILLS_HEIGHT_KEY];
		mFogDensity = [defaults floatForKey:FOG_DENSITY_KEY] * 0.01f;
		mCameraHeight = [defaults floatForKey:CAMERA_HEIGHT_KEY];
		mGridSize = (int)[defaults integerForKey:GRID_SIZE_KEY];

		NSArray *fog_colour_array = [defaults objectForKey:FOG_COLOUR_KEY];
		mFogColour[0] = [[fog_colour_array objectAtIndex:0] floatValue];
		mFogColour[1] = [[fog_colour_array objectAtIndex:1] floatValue];
		mFogColour[2] = [[fog_colour_array objectAtIndex:2] floatValue];
		mFogColour[3] = [[fog_colour_array objectAtIndex:3] floatValue];
    }
	
    return self;
}

- (void)setWireFrame:(bool)wireframe
{
	if(wireframe != mWireFrame)
	{
		[mHeightField deleteList];
		mWireFrame = wireframe;
	}
}

- (BOOL)getWireFrame
{
    return mWireFrame;
}

- (void)setViewportRect:(NSRect)bounds
{
    glViewport((GLfloat)bounds.origin.x, (GLfloat)bounds.origin.y, (GLfloat)bounds.size.width, (GLfloat)bounds.size.height);

    glMatrixMode( GL_PROJECTION );
    glLoadIdentity();
    gluPerspective( 30, bounds.size.width / bounds.size.height, 0.1, 1000.0 );

    glMatrixMode( GL_MODELVIEW );
    glLoadIdentity();
}

- (void)animate
{
	const double radius = 25.0;
	static double eyeX = 0.0;
	double eyeY = mCameraHeight;
	static double eyeZ = 0.0;
	double centerX = 0.0;
	const double centerY = 0.0;
	double centerZ = 0.0;

	NSTimeInterval currentFrameTime = [[NSDate date] timeIntervalSinceReferenceDate];
	
	smTime += (currentFrameTime - sLastFrameTime) * 0.002f * mSpeed;
	
	sLastFrameTime = currentFrameTime;
	
	float xfactor = 0.5f;
	
	double dx = cos((smTime+xfactor)) * radius - eyeX;
	double dz = sin(1.7f*(smTime+xfactor)) * radius - eyeZ;
	double d = sqrt(dx*dx+dz*dz);
	dx /= d;
	dz /= d;
	
	const float dfactor = mLookAhead;
	
	centerX = cos(smTime)*radius  + dx*dfactor;
	centerZ = sin(1.7*smTime)*radius  + dz*dfactor;
	eyeX = cos(smTime)*radius;
	eyeZ = sin(1.7*smTime)*radius;

    glPushMatrix();

	[mCamera lookAt_x:(float)centerX y:(float)centerY z:(float)centerZ];
	[mCamera positionAt_x:(float)eyeX y:(float)eyeY z:(float)eyeZ];

    glPopMatrix();
}

- (void)render
{
	if(mAnimate)
		[self animate];
		
    glEnable( GL_DEPTH_TEST );
    glDisable (GL_LIGHTING);

	if(mFogDensity >= 0.01)
	{
		glEnable (GL_FOG);
		glFogi (GL_FOG_MODE, GL_EXP2);
		glFogfv (GL_FOG_COLOR, mFogColour);
		glFogf (GL_FOG_DENSITY, (GLfloat) mFogDensity);
		glHint (GL_FOG_HINT, GL_NICEST);
	}
	else
	{
		glDisable (GL_FOG);
	}
	
    // Set up texturing parameters.
    glTexEnvf( GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_MODULATE );
    glEnable( GL_TEXTURE_2D );

    // Clear the framebuffer.
    glClearColor( 0, 0, 0, 0 );
    glClear( GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT );
    
	glDisable(GL_CULL_FACE);

	glPushMatrix(); // Level 1

 	[mCamera render];

	if(mHeightField == nil)
	{
		mHeightField = [HeightField heightFieldWithFile:@"heightmap.png"
			detailTexture:@"grass.jpg" lightTexture:@"lightmap.png" gridsize:mGridSize];
	}
	
	glPushMatrix(); // Level 2

	glTranslatef(0, - mHillsHeight * 0.5f, 0);
 	glScalef (100.0f, mHillsHeight, 100.0f);
	[mHeightField render:mWireFrame];

    glPopMatrix(); // Level 2
    
	if(!mWireFrame)
	{
		if(mSkyDome == nil)
		{
			mSkyDome = [[SkyDome alloc] init];
			[mSkyDome generateDome];
		}

		glPushMatrix(); // Level 2

		[mSkyDome renderSkyDome];
		
		glPopMatrix(); // Level 2
	}

	glPopMatrix(); // Level 1
	
    // Flush out any unfinished rendering before swapping.
    glFinish();

}

- (void)setAnimationSpeed: (float)speed
{
	mSpeed = speed;
}

- (float)getAnimationSpeed
{
	return mSpeed;
}

- (void)setHillsHeight: (float)height
{
	mHillsHeight = height;
}

- (void)setLookAhead: (float)distance
{
	mLookAhead = distance;
}

- (float)getLookAhead
{
	return(mLookAhead);
}

- (void)setCameraHeight: (float)height
{
	mCameraHeight = height;
}

- (float)getCameraHeight
{
	return(mCameraHeight);
}

- (void)setFogDensity: (float) fog_density
{
	mFogDensity = fog_density;
}

- (void)setGridSize: (int)gridsize
{
	if(gridsize != mGridSize)
	{
		mGridSize = gridsize;
		[mHeightField makeHeightField: mGridSize];
		[mHeightField deleteList];
	}
}

- (void)setFogColour_red: (float)red green:(float)green blue:(float)blue alpha:(float)alpha
{
	mFogColour[0] = red;
	mFogColour[1] = green;
	mFogColour[2] = blue;
	mFogColour[3] = alpha;
}

- (Camera *) camera
{
	return mCamera;
}

- (void)setAnimate:(BOOL)animate
{
	mAnimate = animate;
	
	// When the animation restarts, make sure we start at the same place
	// that we stopped. This is done by making the last recorded time
	// the same as the current time.
	if(animate)
		sLastFrameTime = [[NSDate date] timeIntervalSinceReferenceDate];
}

- (BOOL)getAnimate
{
	return(mAnimate);
}

@end
