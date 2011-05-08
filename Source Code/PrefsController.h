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
#import <HillsOpenGLView.h>

@interface PrefsController : NSResponder
{
    IBOutlet id mGridSizeSlider;
    IBOutlet id mGridSizeTextField;
    IBOutlet id mHillsHeightSlider;
    IBOutlet id mHillsHeightTextField;
    IBOutlet id mSpeedSlider;
    IBOutlet id mSpeedTextField;
    IBOutlet id mLookAheadSlider;
    IBOutlet id mLookAheadTextField;
    IBOutlet id mCameraHeightSlider;
    IBOutlet id mCameraHeightTextField;
    IBOutlet id mFogDensitySlider;
    IBOutlet id mFogDensityTextField;
    IBOutlet id mFogColourButton;
    IBOutlet NSPopUpButton* mResolutionPopUpButton;
	
	IBOutlet HillsOpenGLView *mHillsOpenGLView;
	
	NSMutableArray *mDisplayModes;
	NSDictionary *mOriginalDisplayMode;
}
- (IBAction)selectGridSize:(id)sender;
- (IBAction)selectHillsHeight:(id)sender;
- (IBAction)selectSpeed:(id)sender;
- (IBAction)selectLookAhead:(id)sender;
- (IBAction)selectCameraHeight:(id)sender;
- (IBAction)selectFogDensity:(id)sender;
- (IBAction)selectFogColour:(id)sender;
- (IBAction)selectDefaultSettings:(id)sender;
- (IBAction)selectResolution:(id)sender;

- (void) setAnimationSpeed:(float)speed;
- (void) setCameraHeight:(float)cameraheight;
- (void) setLookAhead:(float)lookahead;
- (NSDictionary *) displayMode;
- (void) createResolutionMenu;

@end
