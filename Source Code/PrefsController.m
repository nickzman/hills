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

#import "PrefsController.h"
#import "HillsOpenGLView.h"
#import "Scene.h"

static int CompareDisplayModes(id arg1, id arg2, void *context);

@implementation PrefsController

- (void) awakeFromNib
{
	NSString *defaultspath = [[NSBundle mainBundle] pathForResource: DEFAULTS_FILENAME ofType: DEFAULTS_FILETYPE];
	NSDictionary *defaults = [NSDictionary dictionaryWithContentsOfFile: defaultspath];
	[[NSUserDefaults standardUserDefaults] registerDefaults: defaults];

	float speed = [[NSUserDefaults standardUserDefaults] floatForKey:SPEED_KEY];
	[mSpeedTextField setStringValue:[NSString stringWithFormat:@"%.2f ", speed]];
	[mSpeedSlider setFloatValue:speed];

	float hillsheight = [[NSUserDefaults standardUserDefaults] floatForKey:HILLS_HEIGHT_KEY];
	[mHillsHeightTextField setStringValue:[NSString stringWithFormat:@"%.2f ", hillsheight]];
	[mHillsHeightSlider setFloatValue:hillsheight];

	float cameraheight = [[NSUserDefaults standardUserDefaults] floatForKey:CAMERA_HEIGHT_KEY];
	[mCameraHeightTextField setStringValue:[NSString stringWithFormat:@"%.2f ", cameraheight]];
	[mCameraHeightSlider setFloatValue:cameraheight];

	float lookahead = [[NSUserDefaults standardUserDefaults] floatForKey:LOOK_AHEAD_KEY];
	[mLookAheadTextField setStringValue:[NSString stringWithFormat:@"%.2f ", lookahead]];
	[mLookAheadSlider setFloatValue:lookahead];

	int gridsize = [[NSUserDefaults standardUserDefaults] integerForKey:GRID_SIZE_KEY];
	[mGridSizeTextField setIntValue:gridsize];
	[mGridSizeSlider setIntValue:gridsize];

	float fog_density = [[NSUserDefaults standardUserDefaults] floatForKey:FOG_DENSITY_KEY];
	[mFogDensityTextField setStringValue:[NSString stringWithFormat:@"%.3f ", fog_density * 0.01]];
	[mFogDensitySlider setFloatValue:fog_density];

	NSArray *fog_colour_array = [[NSUserDefaults standardUserDefaults] objectForKey:FOG_COLOUR_KEY];
	float redc = [[fog_colour_array objectAtIndex:0] floatValue];
	float greenc = [[fog_colour_array objectAtIndex:1] floatValue];
	float bluec = [[fog_colour_array objectAtIndex:2] floatValue];
	float alphac = [[fog_colour_array objectAtIndex:3] floatValue];
	NSColor *fog_colour = [NSColor colorWithCalibratedRed:redc green:greenc blue:bluec alpha:alphac];
	
	[mFogColourButton setColor:fog_colour];
	
    mOriginalDisplayMode = [(NSDictionary *)CGDisplayCurrentMode(kCGDirectMainDisplay) retain];
	//NSLog(@"%@", mOriginalDisplayMode);

	[self createResolutionMenu];
}

- (void) createResolutionMenu
{	
	int prefs_width = [[NSUserDefaults standardUserDefaults] integerForKey:FULLSCREEN_WIDTH_KEY];
	int prefs_height = [[NSUserDefaults standardUserDefaults] integerForKey:FULLSCREEN_HEIGHT_KEY];
	bool prefs_stretched = [[NSUserDefaults standardUserDefaults] boolForKey:FULLSCREEN_STRETCHED_KEY];
	
	//NSLog(@"Preferences fullscreen resolution: %d x %d", prefs_width, prefs_height);

	// Get the list of all available modes
    NSArray *all_display_modes = [(NSArray *)CGDisplayAvailableModes(kCGDirectMainDisplay) retain];
	//NSLog(@"Display modes: %@", mDisplayModes);
	
	unsigned int all_display_modes_size = [all_display_modes count];
	unsigned int all_display_modes_index = 0;
	
	if(mDisplayModes == nil)
		mDisplayModes = [[NSMutableArray alloc] init];
	else
		[mDisplayModes removeAllObjects];
		
	int original_display_bits_per_pixel = [[mOriginalDisplayMode objectForKey: (NSString *)kCGDisplayBitsPerPixel] intValue];
		
	for (; all_display_modes_index < all_display_modes_size; all_display_modes_index++)
	{
		NSDictionary *mode = [all_display_modes objectAtIndex: all_display_modes_index];

		int bits_per_pixel = [[mode objectForKey: (NSString *)kCGDisplayBitsPerPixel] intValue];

		if (bits_per_pixel == original_display_bits_per_pixel)
			[mDisplayModes addObject: mode];
	}

	// Sort the display modes, before adding to menu
    [mDisplayModes sortUsingFunction: CompareDisplayModes context: NULL];

	[mResolutionPopUpButton removeAllItems];
	
	unsigned int display_modes_size = [mDisplayModes count];
	unsigned int display_modes_index = 0;
	
	[mResolutionPopUpButton addItemWithTitle: NSLocalizedStringFromTable (@"DontChange", @"Custom", @"Localized Strings")];
	[[mResolutionPopUpButton menu] addItem:[NSMenuItem separatorItem]];
	[mResolutionPopUpButton selectItemAtIndex:0];
	
	for(; display_modes_index < display_modes_size; display_modes_index++)
	{
		NSDictionary *mode = [mDisplayModes objectAtIndex: display_modes_index];
		
		int modeWidth = [[mode objectForKey: (NSString *)kCGDisplayWidth] intValue];
		int modeHeight = [[mode objectForKey: (NSString *)kCGDisplayHeight] intValue];
		bool stretched = [[mode objectForKey: (id)kCGDisplayIOFlags] intValue] & kDisplayModeStretchedFlag;
 
		NSString *description;
		
		if(stretched)
			description = [NSString stringWithFormat: @"%d x %d (Stretched)", modeWidth, modeHeight];
		else
			description = [NSString stringWithFormat: @"%d x %d", modeWidth, modeHeight];
			
		[mResolutionPopUpButton addItemWithTitle: description];
		
		if((modeWidth == prefs_width) && (modeHeight == prefs_height) && (stretched == prefs_stretched))
		{
			// Allow for the 'Don't Change' and separator menu items by adding 2
			[mResolutionPopUpButton selectItemAtIndex:display_modes_index + 2];
		}
	}
}

- (void) setAnimationSpeed:(float)speed
{
	[mSpeedTextField setStringValue:[NSString stringWithFormat:@"%.2f ", speed]];
	[[mHillsOpenGLView getScene] setAnimationSpeed:speed];
	[mSpeedSlider setFloatValue:speed];
	[[NSUserDefaults standardUserDefaults] setFloat:speed forKey:SPEED_KEY];
}

- (void) setCameraHeight:(float)cameraheight;
{
	[mCameraHeightTextField setStringValue:[NSString stringWithFormat:@"%.2f ", cameraheight]];
	[[mHillsOpenGLView getScene] setCameraHeight:cameraheight];
	[mCameraHeightSlider setFloatValue:cameraheight];
	[[NSUserDefaults standardUserDefaults] setFloat:cameraheight forKey:CAMERA_HEIGHT_KEY];
}

- (void) setLookAhead:(float)lookahead;
{
	[mLookAheadTextField setStringValue:[NSString stringWithFormat:@"%.2f ", lookahead]];
	[[mHillsOpenGLView getScene] setLookAhead:lookahead];
	[mLookAheadSlider setFloatValue:lookahead];
	[[NSUserDefaults standardUserDefaults] setFloat:lookahead forKey:LOOK_AHEAD_KEY];
}

- (IBAction)selectGridSize:(id)sender
{
	[mGridSizeTextField setIntValue:[sender intValue]];
	[[mHillsOpenGLView getScene] setGridSize: [sender intValue]];
	[[NSUserDefaults standardUserDefaults] setInteger:[sender intValue] forKey:GRID_SIZE_KEY];
	
	bool isAnimating = [[mHillsOpenGLView getScene] getAnimate];
	[[mHillsOpenGLView getScene] setAnimate:NO];
	
	[mHillsOpenGLView display];
	
	if(isAnimating)
		[[mHillsOpenGLView getScene] setAnimate:YES];
}

- (IBAction)selectHillsHeight:(id)sender
{
	float hillsheight = [sender floatValue];
	[mHillsHeightTextField setStringValue:[NSString stringWithFormat:@"%.2f ", hillsheight]];
	[[mHillsOpenGLView getScene] setHillsHeight: hillsheight];
	[[NSUserDefaults standardUserDefaults] setFloat:hillsheight forKey:HILLS_HEIGHT_KEY];
	
	bool isAnimating = [[mHillsOpenGLView getScene] getAnimate];
	[[mHillsOpenGLView getScene] setAnimate:NO];
	
	[mHillsOpenGLView display];
	
	if(isAnimating)
		[[mHillsOpenGLView getScene] setAnimate:YES];
}

- (IBAction)selectSpeed:(id)sender
{
	float newSpeed = [sender floatValue];
	
	[mSpeedTextField setStringValue:[NSString stringWithFormat:@"%.2f ", newSpeed]];
	[[mHillsOpenGLView getScene] setAnimationSpeed:newSpeed];
	[[NSUserDefaults standardUserDefaults] setFloat:newSpeed forKey:SPEED_KEY];
}

- (IBAction)selectLookAhead:(id)sender
{
	float distance = [sender floatValue];
	[mLookAheadTextField setStringValue:[NSString stringWithFormat:@"%.2f ", distance]];
	[[mHillsOpenGLView getScene] setLookAhead: distance];
	[[NSUserDefaults standardUserDefaults] setFloat:distance forKey:LOOK_AHEAD_KEY];

	float speed = [[mHillsOpenGLView getScene] getAnimationSpeed];
	[[mHillsOpenGLView getScene] setAnimationSpeed:0.0];
	
	[[mHillsOpenGLView getScene] animate];
	[mHillsOpenGLView display];
	
	[[mHillsOpenGLView getScene] setAnimationSpeed:speed];
}

- (IBAction)selectCameraHeight:(id)sender
{
	float height = [sender floatValue];
	[mCameraHeightTextField setStringValue:[NSString stringWithFormat:@"%.2f ", height]];
	[[mHillsOpenGLView getScene] setCameraHeight: height];
	[[NSUserDefaults standardUserDefaults] setFloat:height forKey:CAMERA_HEIGHT_KEY];

	float speed = [[mHillsOpenGLView getScene] getAnimationSpeed];
	[[mHillsOpenGLView getScene] setAnimationSpeed:0.0];
	
	[[mHillsOpenGLView getScene] animate];
	[mHillsOpenGLView display];
	
	[[mHillsOpenGLView getScene] setAnimationSpeed:speed];
}

- (IBAction)selectFogDensity:(id)sender
{
	float fog_density = [sender floatValue];
	[mFogDensityTextField setStringValue:[NSString stringWithFormat:@"%.3f ", fog_density * 0.01]];
	[[mHillsOpenGLView getScene] setFogDensity: fog_density * 0.01];
	[[NSUserDefaults standardUserDefaults] setFloat:fog_density forKey:FOG_DENSITY_KEY];

	float speed = [[mHillsOpenGLView getScene] getAnimationSpeed];
	[[mHillsOpenGLView getScene] setAnimationSpeed:0.0];
	
	[mHillsOpenGLView display];
	[[mHillsOpenGLView getScene] setAnimationSpeed:speed];
}

- (IBAction)selectFogColour:(id)sender
{
	NSColor *color = [[sender color] colorUsingColorSpaceName:NSCalibratedRGBColorSpace];

	NSNumber *red = [NSNumber numberWithFloat:[color redComponent]];
	NSNumber *green = [NSNumber numberWithFloat:[color greenComponent]];
	NSNumber *blue = [NSNumber numberWithFloat:[color blueComponent]];
	NSNumber *alpha = [NSNumber numberWithFloat:[color alphaComponent]];

	NSArray *colarray = [[NSArray alloc] initWithObjects:red, green, blue, alpha, nil];

	[[NSUserDefaults standardUserDefaults] setObject:colarray forKey:FOG_COLOUR_KEY];

	[[mHillsOpenGLView getScene]  setFogColour_red: [red floatValue] green:[green floatValue] blue:[blue floatValue] alpha:[alpha floatValue]];
	[mHillsOpenGLView display];
}

- (IBAction)selectDefaultSettings:(id)sender
{
	NSString *defaultspath = [[NSBundle mainBundle] pathForResource: DEFAULTS_FILENAME ofType: DEFAULTS_FILETYPE];
	NSDictionary *base_defaults = [NSDictionary dictionaryWithContentsOfFile: defaultspath];

	NSNumber *speed_number = [base_defaults objectForKey:SPEED_KEY];
	[[NSUserDefaults standardUserDefaults] setFloat:[speed_number floatValue] forKey:SPEED_KEY];
	[[mHillsOpenGLView getScene] setAnimationSpeed: [speed_number floatValue]];

	NSNumber *hillsheight_number = [base_defaults objectForKey:HILLS_HEIGHT_KEY];
	[[NSUserDefaults standardUserDefaults] setFloat:[hillsheight_number floatValue] forKey:HILLS_HEIGHT_KEY];
	[[mHillsOpenGLView getScene] setHillsHeight: [hillsheight_number floatValue]];

	NSNumber *cameraheight_number = [base_defaults objectForKey:CAMERA_HEIGHT_KEY];
	[[NSUserDefaults standardUserDefaults] setFloat:[cameraheight_number floatValue] forKey:CAMERA_HEIGHT_KEY];
	[[mHillsOpenGLView getScene] setCameraHeight: [cameraheight_number floatValue]];
	
	NSNumber *lookahead_number = [base_defaults objectForKey:LOOK_AHEAD_KEY];
	[[NSUserDefaults standardUserDefaults] setFloat:[lookahead_number floatValue] forKey:LOOK_AHEAD_KEY];
	[[mHillsOpenGLView getScene] setLookAhead: [lookahead_number floatValue]];
	
	NSNumber *fogdensity_number = [base_defaults objectForKey:FOG_DENSITY_KEY];
	[[NSUserDefaults standardUserDefaults] setFloat:[fogdensity_number floatValue] forKey:FOG_DENSITY_KEY];
	[[mHillsOpenGLView getScene] setFogDensity: [fogdensity_number floatValue] * 0.01];
	
	NSNumber *gridsize_number = [base_defaults objectForKey:GRID_SIZE_KEY];
	[[NSUserDefaults standardUserDefaults] setInteger:[gridsize_number intValue] forKey:GRID_SIZE_KEY];
	[[mHillsOpenGLView getScene] setGridSize: [gridsize_number intValue]];
	
	NSArray *fogcol_array = [base_defaults objectForKey:FOG_COLOUR_KEY];
	[[NSUserDefaults standardUserDefaults] setObject:fogcol_array forKey:FOG_COLOUR_KEY];
	
	GLfloat red = [[fogcol_array objectAtIndex:0] floatValue];
	GLfloat green = [[fogcol_array objectAtIndex:1] floatValue];
	GLfloat blue = [[fogcol_array objectAtIndex:2] floatValue];
	GLfloat alpha = [[fogcol_array objectAtIndex:3] floatValue];
	[[mHillsOpenGLView getScene]  setFogColour_red:red green:green blue:blue alpha:alpha];

	// Update the controls
	[self awakeFromNib];
}

- (IBAction)selectResolution:(id)sender
{
	int index = [mResolutionPopUpButton indexOfSelectedItem];
	
	int width = 0;
	int height = 0;
	bool stretched = false;
	
	if(index > 1)
	{
		// Allow for the 'Don't Change' and separator menu items
		index -= 2;
	
		NSDictionary *mode = [mDisplayModes objectAtIndex:index];
		width = [[mode objectForKey: (NSString *)kCGDisplayWidth] intValue];
		height = [[mode objectForKey: (NSString *)kCGDisplayHeight] intValue];
		stretched = [[mode objectForKey: (id)kCGDisplayIOFlags] intValue] & kDisplayModeStretchedFlag;

	}
	
	[[NSUserDefaults standardUserDefaults] setInteger:width forKey:FULLSCREEN_WIDTH_KEY];
	[[NSUserDefaults standardUserDefaults] setInteger:height forKey:FULLSCREEN_HEIGHT_KEY];
	[[NSUserDefaults standardUserDefaults] setBool:stretched forKey:FULLSCREEN_STRETCHED_KEY];
}

- (NSDictionary *) displayMode;
{
	int item_index = [mResolutionPopUpButton indexOfSelectedItem];
	
	NSDictionary *mode = NULL;
	
	if(item_index > 1)
	{
		// Subtract 2 to allow for the 'Don'r Change' and separator
		mode = [mDisplayModes objectAtIndex:item_index - 2];
	}

	return mode;
}

@end


static int CompareDisplayModes(id arg1, id arg2, void *context)
{
    NSDictionary *mode1 = (NSDictionary *)arg1;
    NSDictionary *mode2 = (NSDictionary *)arg2;
    
    // Sort first on pixel count
    int size1 = [[mode1 objectForKey: (NSString *)kCGDisplayWidth] intValue] *
				[[mode1 objectForKey: (NSString *)kCGDisplayHeight] intValue];
    int size2 = [[mode2 objectForKey: (NSString *)kCGDisplayWidth] intValue] *
				[[mode2 objectForKey: (NSString *)kCGDisplayHeight] intValue];
			
    if (size1 != size2)
        return size1 - size2;
        
    // Then on bit depth
	int bpp1 = (int)[[mode1 objectForKey: (NSString *)kCGDisplayBitsPerPixel] intValue];
	int bpp2 = (int)[[mode2 objectForKey: (NSString *)kCGDisplayBitsPerPixel] intValue];
	
	if(bpp1 != bpp2)
		return bpp1 - bpp2;
		
	// Then on stretched
	bool stretched1 = [[mode1 objectForKey: (id)kCGDisplayIOFlags] intValue] & kDisplayModeStretchedFlag;
	bool stretched2 = [[mode1 objectForKey: (id)kCGDisplayIOFlags] intValue] & kDisplayModeStretchedFlag;
	
	if(stretched1 == stretched2)
		return 0;
	else
		return stretched1 ? -1 : 1;
}

