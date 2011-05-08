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

#import "URLTextField.h"

@implementation URLTextField

- (id)initWithFrame:(NSRect)frameRect
{
	if ((self = [super initWithFrame:frameRect]) != nil)
	{
		mInitialized = NO;
	}
	
	return self;
}

- (void)awakeFromNib
{
    if (mInitialized)
        return;
		
    mInitialized = YES;

    // we set up a tracking region so we can get mouseEntered and mouseExited events
    mTrackingRectTag = [self addTrackingRect:[self bounds] owner:self userData:nil assumeInside:NO];
}

- (void)mouseEntered:(NSEvent *)theEvent
{
#pragma unused(theEvent)
	NSAttributedString *atStr = [self attributedStringValue];
	NSMutableAttributedString *matString = [atStr mutableCopyWithZone:[self zone]];

	NSString *scanString;
	NSRange scanRange;

	NSScanner *scanner = [NSScanner scannerWithString:[matString string]];
	NSCharacterSet *whitespaceSet = [NSCharacterSet whitespaceAndNewlineCharacterSet];

	[scanner scanUpToCharactersFromSet:whitespaceSet intoString:&scanString];
	scanRange.length = [scanString length];
	scanRange.location = [scanner scanLocation] - scanRange.length;
		
	NSColor *linkColor = [NSColor colorWithCalibratedRed:1.0 green:0.4 blue:0.0 alpha:1.0];
	
	NSDictionary* linkAttr = [NSDictionary dictionaryWithObjectsAndKeys:
							[NSNumber numberWithInt:NSSingleUnderlineStyle], NSUnderlineStyleAttributeName,
							linkColor, NSForegroundColorAttributeName, NULL ];
							
	[matString addAttributes:linkAttr range:scanRange];
	
	[self setAttributedStringValue:matString];
	
	[matString release];
}

- (void)mouseExited:(NSEvent *)theEvent
{
#pragma unused(theEvent)
	NSAttributedString *atStr = [self attributedStringValue];
	NSMutableAttributedString *matString = [atStr mutableCopyWithZone:[self zone]];

	NSString*					scanString;
	NSRange						scanRange;

	NSScanner *scanner = [NSScanner scannerWithString:[matString string]];
	NSCharacterSet *whitespaceSet = [NSCharacterSet whitespaceAndNewlineCharacterSet];

	[scanner scanUpToCharactersFromSet:whitespaceSet intoString:&scanString];
	scanRange.length = [scanString length];
	scanRange.location = [scanner scanLocation] - scanRange.length;
		
	NSColor *linkColor = [NSColor colorWithCalibratedRed:0.0 green:0.0 blue:1.0 alpha:1.0];

	NSDictionary* linkAttr = [NSDictionary dictionaryWithObjectsAndKeys:
							[NSNumber numberWithInt:NSNoUnderlineStyle], NSUnderlineStyleAttributeName,
							linkColor, NSForegroundColorAttributeName, NULL ];
							
	[matString addAttributes:linkAttr range:scanRange];
	
	[self setAttributedStringValue:matString];
	
	[matString release];
}

- (void)resetCursorRects
{
	// Change the cursor when the mouse is on top of us
	[self addCursorRect:[self visibleRect] cursor:[NSCursor pointingHandCursor]];
}

- (void)mouseDown:(NSEvent*)inEvent
{
	bool done = false;
	unsigned int eventMask = NSLeftMouseUpMask | NSLeftMouseDraggedMask;
	NSDate *distantFuture = [NSDate distantFuture];
	NSPoint mouseLoc = [self convertPoint:[inEvent locationInWindow] fromView:nil];

	while( !done )
	{
		// Get the next event and mouse location
		inEvent = [NSApp nextEventMatchingMask:eventMask untilDate:distantFuture inMode:NSEventTrackingRunLoopMode dequeue:YES];
		mouseLoc = [self convertPoint:[inEvent locationInWindow] fromView:nil];
		
		switch( [inEvent type] )
		{
			// Case Done Tracking Click
			case NSLeftMouseUp:
				if( NSMouseInRect( mouseLoc, [self bounds], YES ) )
				{
					NSURL *linkURL = [NSURL URLWithString:[NSString stringWithFormat:@"http://%@", [self stringValue]]];
					[[NSWorkspace sharedWorkspace] openURL:linkURL];
				}
				
				done = YES;
				break;
			
			case NSLeftMouseDragged:
				
				if( NSMouseInRect( mouseLoc, [self bounds], YES ) )
					[self mouseEntered:inEvent];
				else
					[self mouseExited:inEvent];

				break;
			
			default:
				break;
		}
	}
}

@end
