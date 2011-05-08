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

#import <ScreenSaver/ScreenSaver.h>
#import "HillsOpenGLView.h"

@interface HillsScreensaverView : ScreenSaverView 
{
    HillsOpenGLView *glView;
    NSRect theRect;
	bool mIsConfiguring;
	bool mFSAA;
	bool mWireFrame;
	bool mMainDisplayOnly;

	IBOutlet id mConfigureSheet;
	IBOutlet id mFSAAButton;
	IBOutlet id mWireFrameButton;
	IBOutlet id mMainDisplayButton;
	IBOutlet id mSpeedSlider;
	IBOutlet id mHillsHeightSlider;
	IBOutlet id mHillsHeightTextField;
	IBOutlet id mSpeedTextField;
	IBOutlet id mLookAheadSlider;
	IBOutlet id mLookAheadTextField;
	IBOutlet id mCameraHeightSlider;
	IBOutlet id mCameraHeightTextField;
	IBOutlet id mFogDensitySlider;
	IBOutlet id mFogDensityTextField;
	IBOutlet id mFogColourButton;
	IBOutlet id mGridSizeSlider;
	IBOutlet id mGridSizeTextField;
}

- (BOOL) hasConfigureSheet;
- (NSWindow*) configureSheet;
- (IBAction)closeSheet:(id)sender;
- (IBAction)selectFSAAButton:(id)sender;
- (IBAction)selectWireFrameButton:(id)sender;
- (IBAction)selectMainDisplayButton:(id)sender;
- (IBAction)selectSpeedSlider:(id)sender;
- (IBAction)selectHillsHeightSlider:(id)sender;
- (IBAction)selectCameraHeightSlider:(id)sender;
- (IBAction)selectLookAheadSlider:(id)sender;
- (IBAction)selectFogColourButton:(id)sender;
- (IBAction)selectGridSizeSlider:(id)sender;
- (IBAction)selectFogDensitySlider:(id)sender;
- (IBAction)selectDefaultSettings:(id)sender;
- (void) loadOptions;
- (void) updateControls;


@end
