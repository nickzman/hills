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

@class HillsOpenGLView;
@class PrefsController;

#ifndef MAC_OS_X_VERSION_10_6
@protocol NSToolbarDelegate <NSObject> @optional @end
#endif

@interface MainController : NSResponder <NSToolbarDelegate>
{
    BOOL isAnimating;
    NSTimer *animationTimer;

    BOOL stayInFullScreenMode;
    NSOpenGLContext *fullScreenContext;

    IBOutlet HillsOpenGLView *mOpenGLView;
	IBOutlet NSWindow *mHillsWindow;
	IBOutlet NSPanel *mPreferencesWindow;
	IBOutlet PrefsController *mPrefsController;
	
	float mSavedAnimationSpeed;
}

- (IBAction) selectFullScreen:(id)sender;
- (IBAction) toggleWireFrame:(id)sender;
- (IBAction) selectStopAnimation:(id)sender;
- (IBAction) selectStartAnimation:(id)sender;
- (IBAction) openPrefsWindow:(id)sender;
- (BOOL) isInFullScreenMode;
- (BOOL) applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)theApplication;
- (void) toggleAnimation;
- (NSOpenGLPixelFormat *) _createPixelFormat;

// Toolbar methods
- (void) setupToolbar;
- (NSToolbarItem *) toolbar: (NSToolbar *)toolbar itemForItemIdentifier: (NSString *) itemIdent willBeInsertedIntoToolbar:(BOOL) willBeInserted;
- (NSArray *) toolbarDefaultItemIdentifiers: (NSToolbar *) toolbar;
- (NSArray *) toolbarAllowedItemIdentifiers: (NSToolbar *) toolbar;
- (BOOL) validateToolbarItem:(NSToolbarItem *)toolbarItem;


@end
