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

#import <OpenGL/gl.h>
#import <OpenGL/glext.h>
#import <OpenGL/OpenGL.h>

#import "HillsOpenGLView.h"
#import "Scene.h"
#import "Camera.h"

@implementation HillsOpenGLView

- initWithFrame:(NSRect)frameRect
{
#ifdef SCREENSAVER
	return [self initWithFrame:frameRect FSAA:NO];
#else
	return [self initWithFrame:frameRect FSAA:YES];
#endif
}


- (id)initWithFrame:(NSRect)frameRect FSAA:(BOOL)useFSAA
{
#ifdef SCREENSAVER
	mRender = false;
#else
	mWireFrame = false;
	mRender = true;
#endif

	mFirstDraw = true;

    NSOpenGLPixelFormatAttribute attrs[] =
	{
        NSOpenGLPFANoRecovery,
        NSOpenGLPFAColorSize, 32,
        NSOpenGLPFADepthSize, 24,
        NSOpenGLPFADoubleBuffer,
        NSOpenGLPFAAccelerated,
		NSOpenGLPFASampleBuffers, (useFSAA ? 1 : 0),
        NSOpenGLPFASamples, (useFSAA ? 2 : 0),
		NSOpenGLPFAMultisample, (useFSAA ? 1 : 0),
		NSOpenGLPFAAllowOfflineRenderers,	// necessary to make the OpenGL view work on the integrated GPU
        0
    };
	
	NSOpenGLPixelFormat* pixelFormat = [[NSOpenGLPixelFormat alloc] initWithAttributes:attrs];
	
    self = [super initWithFrame:frameRect pixelFormat:pixelFormat];
	
    if (self)
	{
        scene = [[Scene alloc] init];
		
		[scene setWireFrame:mWireFrame];
		self.wantsBestResolutionOpenGLSurface = YES;
	}
	
    return self;
}

- (Scene *)getScene
{
    return scene;
}

- (void) drawRect:(NSRect)aRect
{
	if(mRender)
	{
		if(mFirstDraw)
		{
			GLint VBL = 1;
			CGLSetParameter(CGLGetCurrentContext(),  kCGLCPSwapInterval, &VBL);
			mFirstDraw = false;
		}
		
		[scene render];
	}
	else
	{
		glClearColor( 0, 0, 0, 0 );
		glClear( GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT );
	}
	
    [[self openGLContext] flushBuffer];
}

- (void) reshape
{
	[super reshape];
	if ([self respondsToSelector:@selector(convertRectToBacking:)] && self.wantsBestResolutionOpenGLSurface)	// on Lion & later, if best resolution is on, then we need to convert our rect for glViewport()
		[scene setViewportRect:[self convertRectToBacking:self.bounds]];
	else
		[scene setViewportRect:[self bounds]];
}

- (BOOL) acceptsFirstResponder
{
    return YES;
}

- (void) keyDown:(NSEvent *)theEvent
{
	if (controller)
		[controller keyDown:theEvent];
	else
		[super keyDown:theEvent];
}

- (void)mouseDown:(NSEvent *)theEvent
{
	mLastClickPoint = [theEvent locationInWindow];
	mDegreesX = [[scene camera] getXDegrees];
	mDegreesY = [[scene camera] getYDegrees];
	
	[controller mouseDown:theEvent];
}

- (void)mouseDragged:(NSEvent *)anEvent
{
    NSPoint newLocation	= [anEvent locationInWindow];
    float angleX, angleY;

    angleX = mDegreesX + (float)(newLocation.x - mLastClickPoint.x);
    angleY = -mDegreesY + (float)(newLocation.y - mLastClickPoint.y);

	[[scene camera] rotateByDegrees_x: angleX y: -angleY];

    [self setNeedsDisplay: YES];

    [super mouseDragged: anEvent];
}


- (void)scrollWheel:(NSEvent *)theEvent
{
	[[scene camera] setDistance: [[scene camera] getDistance] - ((float)[theEvent deltaY] * 0.25f)];

    [self setNeedsDisplay: YES];

    [super scrollWheel: theEvent];
}

- (void)setWireFrame:(bool)wireframe
{
	mWireFrame = wireframe;
	
	[scene setWireFrame:mWireFrame];
}

- (void)setRender:(bool)render
{
	// Setting mRender to false will just draw a black screen, which is
	// what we want to do until we know we are allowed to draw on the
	// main or other displays.
	mRender = render;
}

@end
