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

#import "MainController.h"
#import "HillsOpenGLView.h"
#import "Scene.h"
#import "PrefsController.h"
#import "Camera.h"

#import <OpenGL/OpenGL.h>

static NSString* ToolbarIdentifier = @"Toolbar Identifier";
static NSString* FullScreenToolbarItemIdentifier = @"FullScreen Item Identifier";
static NSString* StopToolbarItemIdentifier = @"Stop Item Identifier";
static NSString* StartToolbarItemIdentifier = @"Start Item Identifier";
static NSString* WireFrameToolbarItemIdentifier = @"WireFrame Item Identifier";
static NSString* PrefsToolbarItemIdentifier = @"Prefs Item Identifier";

@interface MainController (AnimationMethods)
- (BOOL) isAnimating;
- (void) startAnimation;
- (void) stopAnimation;
- (void) startAnimationTimer;
- (void) stopAnimationTimer;
- (void) animationTimerFired:(NSTimer *)timer;
@end

@implementation MainController

- (void) awakeFromNib
{
    isAnimating = NO;
	
	// Load default preferences from file
	NSDictionary *registrationDefaults = [NSDictionary dictionaryWithContentsOfFile: 
		[[NSBundle mainBundle] pathForResource: DEFAULTS_FILENAME ofType: DEFAULTS_FILETYPE]];
		
	[[NSUserDefaults standardUserDefaults] registerDefaults: registrationDefaults];

	[self setupToolbar];
	
    [self startAnimation];
}

- (IBAction) toggleWireFrame:(id)sender
{
	bool animating = [self isAnimating];
	if(animating)
		[self stopAnimation];

	Scene *scene = [mOpenGLView getScene];
	
	[scene setWireFrame: ![scene getWireFrame]];

	if(!stayInFullScreenMode)
		[mOpenGLView setNeedsDisplay:YES];

	if(animating)
		[self startAnimation];
}

- (void) toggleAnimation
{
	if ([self isAnimating] == YES)
		[self selectStopAnimation:self];
	else
		[self selectStartAnimation:self];
}

- (IBAction) selectStopAnimation:(id)sender
{
	if ([self isAnimating] == YES)
	{
		[[mOpenGLView getScene] setAnimate:false];
		[self stopAnimation];
	}
}

- (IBAction) selectStartAnimation:(id)sender
{
	if ([self isAnimating] == NO)
	{
		[[mOpenGLView getScene] setAnimate:true];

		[self startAnimation];
	}
}

// Action method wired up to fire when the user clicks the "Go FullScreen" button. 
// We remain in this method until the user exits FullScreen mode.
- (IBAction) selectFullScreen:(id)sender
{
	SInt32 osVersion;
	
	Gestalt(gestaltSystemVersion, &osVersion);
	if (osVersion > 0x1050)	// Leopard & later
	{
		NSDictionary *lDisplayMode = [mPrefsController displayMode];
		
		[mOpenGLView enterFullScreenMode:[NSScreen mainScreen] withOptions:(lDisplayMode ? [NSDictionary dictionaryWithObject:lDisplayMode forKey:NSFullScreenModeSetting] : nil)];
		stayInFullScreenMode = YES;
		
		while (stayInFullScreenMode)
		{
			NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
			NSEvent *event;
			
			while (event = [NSApp nextEventMatchingMask:NSAnyEventMask untilDate:[NSDate distantPast] inMode:NSDefaultRunLoopMode dequeue:YES])
			{
				switch ([event type])
				{
					case NSKeyDown:
						[self keyDown:event];
						break;
					case NSLeftMouseDown:
						// Exit full-screen mode when mouse is clicked
						stayInFullScreenMode = NO;
						break;
					default:
						break;
				}
			}
			[pool release];
		}
		[mOpenGLView exitFullScreenModeWithOptions:nil];
		return;
	}
	
    Scene *scene = [mOpenGLView getScene];
    CGLContextObj cglContext;
    CGDisplayErr err;
    GLint oldSwapInterval;
    GLint newSwapInterval;

    // Pixel Format Attributes for the FullScreen NSOpenGLContext
    NSOpenGLPixelFormatAttribute attrs[] = {

        // Specify that we want a full-screen OpenGL context.
        NSOpenGLPFAFullScreen,

        // We may be on a multi-display system (and each screen may be driven by
		// a different renderer), so we need to specify which screen we want to
		// take over.  For this demo, we'll specify the main screen.
        NSOpenGLPFAScreenMask, CGDisplayIDToOpenGLDisplayMask(kCGDirectMainDisplay),

        // Attributes Common to FullScreen and non-FullScreen
        NSOpenGLPFAColorSize, 16,
        NSOpenGLPFADepthSize, 24,
        NSOpenGLPFADoubleBuffer,
        NSOpenGLPFAAccelerated,
		NSOpenGLPFASampleBuffers, 1,	// FSAA
        NSOpenGLPFASamples, 2,			// FSAA	
        0
    };
	
	//CGDisplayBestModeForParameters

    GLint rendererID;

    // Create the FullScreen NSOpenGLContext with the attributes listed above.
    NSOpenGLPixelFormat *pixelFormat = [[NSOpenGLPixelFormat alloc] initWithAttributes:attrs];
    
    // Just as a diagnostic, report the renderer ID that this pixel format binds to. 
	// CGLRenderers.h contains a list of known renderers and their corresponding RendererID codes.
    [pixelFormat getValues:&rendererID forAttribute:NSOpenGLPFARendererID forVirtualScreen:0];
    //NSLog(@"FullScreen pixelFormat RendererID = %08x", (unsigned)rendererID);

    // Create an NSOpenGLContext with the FullScreen pixel format.  By specifying
	// the non-FullScreen context as our "shareContext", we automatically inherit
	// all of the textures, display lists, and other OpenGL objects it has defined.
    fullScreenContext = [[NSOpenGLContext alloc] initWithFormat:pixelFormat shareContext:[mOpenGLView openGLContext]];

    // Create a GL context
//    fullScreenContext = [[NSOpenGLContext alloc] initWithFormat: pixelFormat shareContext: nil];
//    if (!fullScreenContext) {
//        NSLog(@"Unable to create an OpenGL context.");
//        return;
//    }

    [pixelFormat release];
    pixelFormat = nil;

    if (fullScreenContext == nil) {
        NSLog(@"Failed to create fullScreenContext");
        return;
    }

    // Pause animation in the OpenGL view.  While we're in full-screen mode,
	// we'll drive the animation actively instead of using a timer callback.
    if ([self isAnimating]) {
        [self stopAnimationTimer];
    }

    // Take control of the display where we're about to go FullScreen.
    err = CGCaptureAllDisplays();
	
    if (err != CGDisplayNoErr) {
        [fullScreenContext release];
        fullScreenContext = nil;
        return;
    }
	
	// Hide the cursor
	CGDisplayHideCursor(kCGDirectMainDisplay);

//	CGDisplaySwitchToMode( kCGDirectMainDisplay, 
//							CGDisplayBestModeForParameters( kCGDirectMainDisplay, 32, 1024, 768, NULL ) ) ;
	NSDictionary *displayMode = [mPrefsController displayMode];
	
	if(displayMode != NULL)
		CGDisplaySwitchToMode( kCGDirectMainDisplay, (CFDictionaryRef)displayMode ) ;

    // Enter FullScreen mode and make our FullScreen context the active context for OpenGL commands.
    [fullScreenContext setFullScreen];
    [fullScreenContext makeCurrentContext];

    // Save the current swap interval so we can restore it later, and then set
	// the new swap interval to lock us to the display's refresh rate.
    cglContext = CGLGetCurrentContext();
    CGLGetParameter(cglContext, kCGLCPSwapInterval, &oldSwapInterval);
    newSwapInterval = 1;
    CGLSetParameter(cglContext, kCGLCPSwapInterval, &newSwapInterval);

    // Tell the scene the dimensions of the area it's going to render to, so it
	// can set up an appropriate viewport and viewing transformation.
    [scene setViewportRect:NSMakeRect(0, 0, CGDisplayPixelsWide(kCGDirectMainDisplay),
									CGDisplayPixelsHigh(kCGDirectMainDisplay))];

    // Now that we've got the screen, we enter a loop in which we alternately
	// process input events and computer and render the next frame of our animation. 
	// The shift here is from a model in which we passively receive events handed
	// to us by the AppKit to one in which we are actively driving event processing.
    stayInFullScreenMode = YES;
	
    while (stayInFullScreenMode) {
        NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

        // Check for and process input events.
        NSEvent *event;
        while (event = [NSApp nextEventMatchingMask:NSAnyEventMask untilDate:[NSDate distantPast]
						inMode:NSDefaultRunLoopMode dequeue:YES])
		{
            switch ([event type])
			{
                case NSKeyDown:
                    [self keyDown:event];
                    break;

				case NSLeftMouseDown:
					// Exit full-screen mode when mouse is clicked
					stayInFullScreenMode = NO;
					break;
					
                default:
                    break;
            }
        }

        [scene render];
		
        [fullScreenContext flushBuffer];

        [pool release];
    }
    
    // Clear the front and back framebuffers before switching out of FullScreen mode. 
	// (This is not strictly necessary, but avoids an untidy flash of garbage.)
    glClearColor(0.0f, 0.0f, 0.0f, 0.0f);
    glClear(GL_COLOR_BUFFER_BIT);
    [fullScreenContext flushBuffer];
    glClear(GL_COLOR_BUFFER_BIT);
    [fullScreenContext flushBuffer];

    // Restore the previously set swap interval.
    CGLSetParameter(cglContext, kCGLCPSwapInterval, &oldSwapInterval);

   // Exit fullscreen mode and release our FullScreen NSOpenGLContext.
    [NSOpenGLContext clearCurrentContext];
    [fullScreenContext clearDrawable];
    [fullScreenContext release];
    fullScreenContext = nil;

    CGDisplayShowCursor(kCGDirectMainDisplay);

    // Release control of the display.
    CGReleaseAllDisplays();

    // Mark our view as needing drawing.  (The animation has advanced while we
	// were in FullScreen mode, so its current contents are stale.)
    [mOpenGLView setNeedsDisplay:YES];

    // Resume animation timer firings.
    if ([self isAnimating]) {
        [self startAnimationTimer];
    }
}

#define ADD_ATTR(attr) \
do { \
    printf("ADD_ATTR(%s)\n", #attr); \
    attributeCount++; \
    attributes = realloc(attributes, sizeof(*attributes) * attributeCount); \
    attributes[attributeCount - 1] = attr; \
} while (0)

- (NSOpenGLPixelFormat *) _createPixelFormat;
{
    NSOpenGLPixelFormat *pixelFormat;
    NSOpenGLPixelFormatAttribute *attributes;
    unsigned int attributeCount = 0;

    attributes = malloc(sizeof(*attributes));

    ADD_ATTR(NSOpenGLPFAFullScreen);
    ADD_ATTR(NSOpenGLPFAColorSize);
    ADD_ATTR(32);
    ADD_ATTR(NSOpenGLPFADepthSize);
    ADD_ATTR(24);
	
    // We want double buffered and hardware accelerated
    ADD_ATTR(NSOpenGLPFADoubleBuffer);
    ADD_ATTR(NSOpenGLPFAAccelerated);
    
    // Note what display device we want to support
    ADD_ATTR(NSOpenGLPFAScreenMask);
    ADD_ATTR(CGDisplayIDToOpenGLDisplayMask(kCGDirectMainDisplay));
    
    // Terminate the list
    ADD_ATTR(0);
    
    pixelFormat = [[NSOpenGLPixelFormat alloc] initWithAttributes: attributes];
    free(attributes);
    
    return pixelFormat;
}

- (void) keyDown:(NSEvent *)event
{
    unichar c = [[event charactersIgnoringModifiers] characterAtIndex:0];
	
	//NSLog(@"ASCII = %d", (unsigned int)c);
	
    switch (c) {

        // [Esc] exits FullScreen mode.
        case 27:
            stayInFullScreenMode = NO;
			break;
			
        case 32:
			[self toggleAnimation];
            break;

        // [W] toggles wireframe rendering
        case 'w':
        case 'W':
            [self toggleWireFrame:self];
            break;
			
		case 'a':
		case 'A':
			if(isAnimating)
			{
				float camera_height = [[mOpenGLView getScene] getCameraHeight];
				camera_height += 0.03f;
				[mPrefsController setCameraHeight:camera_height];
			}
			break;
			
		case 'z':
		case 'Z':
			if(isAnimating)
			{
				float camera_height = [[mOpenGLView getScene] getCameraHeight];
				camera_height -= 0.06f;
				[mPrefsController setCameraHeight:camera_height];
			}
			break;

		case 's':
		case 'S':
			if(isAnimating)
			{
				float look_ahead = [[mOpenGLView getScene] getLookAhead];
				look_ahead += 0.06f;
				[mPrefsController setLookAhead:look_ahead];
			}
			break;
			
		case 'x':
		case 'X':
			if(isAnimating)
			{
				float look_ahead = [[mOpenGLView getScene] getLookAhead];
				look_ahead -= 0.03f;
				[mPrefsController setLookAhead:look_ahead];
			}
			break;

		case 63232:
			if(isAnimating)
			{
				// Up Arrow. Speed up.
				float speed = [[mOpenGLView getScene] getAnimationSpeed];
				speed += 2.0f;
				
				if(speed > 50.0f)
					speed = 50.0f;
					
				[mPrefsController setAnimationSpeed:speed];
			}
			else
			{
				[[[mOpenGLView getScene] camera] moveForwards:0.1f];
				
				if(!stayInFullScreenMode)
					[mOpenGLView setNeedsDisplay:YES];

			}
			break;
			
		case 63233:
			if(isAnimating)
			{
				// Down Arrow. Slow Down.
				float speed = [[mOpenGLView getScene] getAnimationSpeed];
				speed -= 2.0f;
				
				if(speed < -5.0f)
					speed = -5.0f;
					
				[mPrefsController setAnimationSpeed:speed];
			}
			else
			{
				[[[mOpenGLView getScene] camera] moveBackwards:0.1f];

				if(!stayInFullScreenMode)
					[mOpenGLView setNeedsDisplay:YES];
			}
			break;
			
        default:
            break;
    }
}

- (BOOL) isInFullScreenMode
{
    return fullScreenContext != nil;
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)theApplication
{
    return YES;
}

- (IBAction) openPrefsWindow:(id)sender
{
	[mPreferencesWindow makeKeyAndOrderFront:sender];
}

#pragma mark ---Toolbar---

- (void) setupToolbar
{
    // Create a new toolbar instance, and attach it to our document window 
    NSToolbar *toolbar = [[[NSToolbar alloc] initWithIdentifier: ToolbarIdentifier] autorelease];
    
    // Set up toolbar properties: Allow customization, give a default display mode, and remember state in user defaults 
    [toolbar setAllowsUserCustomization: YES];
    [toolbar setAutosavesConfiguration: YES];
	[toolbar setShowsBaselineSeparator: NO];
    [toolbar setDisplayMode: NSToolbarDisplayModeDefault];
    
    // We are the delegate
    [toolbar setDelegate: self];
    
    // Attach the toolbar to the document window 
    [mHillsWindow setToolbar: toolbar];
}

- (NSToolbarItem *) toolbar: (NSToolbar *)toolbar itemForItemIdentifier: (NSString *) itemIdent willBeInsertedIntoToolbar:(BOOL) willBeInserted
{

    NSToolbarItem *toolbarItem = nil;
    	
    if ([itemIdent isEqual: FullScreenToolbarItemIdentifier])
	{
        toolbarItem = [[[NSToolbarItem alloc] initWithItemIdentifier: itemIdent] autorelease];
	
		[toolbarItem setLabel: @"Full Screen"];
		[toolbarItem setPaletteLabel: @"Full Screen"];
		[toolbarItem setToolTip: @"Switch to Full Screen mode (use esc key to exit)"];
		[toolbarItem setImage: [NSImage imageNamed: @"Present"]];
		[toolbarItem setTarget: self];
		[toolbarItem setAction: @selector(selectFullScreen:)];
    }
	else if([itemIdent isEqual: StartToolbarItemIdentifier])
	{
        toolbarItem = [[[NSToolbarItem alloc] initWithItemIdentifier: itemIdent] autorelease];
	
		[toolbarItem setLabel: @"Start"];
		[toolbarItem setPaletteLabel: @"Start"];
		[toolbarItem setToolTip: @"Start Animation"];
		[toolbarItem setImage: [NSImage imageNamed: @"Run"]];
		[toolbarItem setTarget: self];
		[toolbarItem setAction: @selector(selectStartAnimation:)];
	}
	else if([itemIdent isEqual: StopToolbarItemIdentifier])
	{
        toolbarItem = [[[NSToolbarItem alloc] initWithItemIdentifier: itemIdent] autorelease];
	
		[toolbarItem setLabel: @"Stop"];
		[toolbarItem setPaletteLabel: @"Stop"];
		[toolbarItem setToolTip: @"Stop Animation"];
		[toolbarItem setImage: [NSImage imageNamed: @"Stop"]];
		[toolbarItem setTarget: self];
		[toolbarItem setAction: @selector(selectStopAnimation:)];
	}
	else if([itemIdent isEqual: WireFrameToolbarItemIdentifier])
	{
        toolbarItem = [[[NSToolbarItem alloc] initWithItemIdentifier: itemIdent] autorelease];
	
		[toolbarItem setLabel: @"Wire Frame"];
		[toolbarItem setPaletteLabel: @"Wire Frame"];
		[toolbarItem setToolTip: @"Toggle Wire Frame Mode"];
		[toolbarItem setImage: [NSImage imageNamed: @"wireframe"]];
		[toolbarItem setTarget: self];
		[toolbarItem setAction: @selector(toggleWireFrame:)];
	}
	else if([itemIdent isEqual: PrefsToolbarItemIdentifier])
	{
        toolbarItem = [[[NSToolbarItem alloc] initWithItemIdentifier: itemIdent] autorelease];
	
		[toolbarItem setLabel: @"Preferences"];
		[toolbarItem setPaletteLabel: @"Preferences"];
		[toolbarItem setToolTip: @"Preferences"];
		[toolbarItem setImage: [NSImage imageNamed: @"hillsprefs"]];
		[toolbarItem setTarget: self];
		[toolbarItem setAction: @selector(openPrefsWindow:)];
	}
	
	return toolbarItem;
}

- (NSArray *) toolbarDefaultItemIdentifiers: (NSToolbar *) toolbar
{
    return [NSArray arrayWithObjects:	StartToolbarItemIdentifier,
										StopToolbarItemIdentifier,
										FullScreenToolbarItemIdentifier,
										WireFrameToolbarItemIdentifier,
										PrefsToolbarItemIdentifier,
										nil];
}

- (NSArray *) toolbarAllowedItemIdentifiers: (NSToolbar *) toolbar
{
    return [NSArray arrayWithObjects: 	StartToolbarItemIdentifier,
										StopToolbarItemIdentifier,
										FullScreenToolbarItemIdentifier,
										WireFrameToolbarItemIdentifier,
										PrefsToolbarItemIdentifier,
										NSToolbarSeparatorItemIdentifier,
										NSToolbarFlexibleSpaceItemIdentifier,
										NSToolbarSpaceItemIdentifier,
										NSToolbarCustomizeToolbarItemIdentifier,
										nil];
}

-(BOOL) validateToolbarItem:(NSToolbarItem *)toolbarItem
{
    BOOL enable = YES;
	
	if ([[toolbarItem itemIdentifier] isEqual:StartToolbarItemIdentifier])
	{
        enable = ![self isAnimating];
    }
	else if ([[toolbarItem itemIdentifier] isEqual:StopToolbarItemIdentifier])
	{
        enable = [self isAnimating];
    }
	
    return enable;
}

@end

@implementation MainController (AnimationMethods)

- (BOOL) isAnimating
{
    return isAnimating;
}

- (void) startAnimation
{
    if (!isAnimating) {
        isAnimating = YES;
        if (![self isInFullScreenMode]) {
            [self startAnimationTimer];
        }
    }
}

- (void) stopAnimation
{
    if (isAnimating) {
        if (animationTimer != nil) {
            [self stopAnimationTimer];
        }
        isAnimating = NO;
    }
}

- (void) startAnimationTimer
{
    if (animationTimer == nil) {
        animationTimer = [[NSTimer scheduledTimerWithTimeInterval:0.017
						target:self selector:@selector(animationTimerFired:)
						userInfo:nil repeats:YES] retain];
    }
}

- (void) stopAnimationTimer
{
    if (animationTimer != nil) {
        [animationTimer invalidate];
        [animationTimer release];
        animationTimer = nil;
    }
}

- (void) animationTimerFired:(NSTimer *)timer
{
    [mOpenGLView setNeedsDisplay:YES];
}

@end
