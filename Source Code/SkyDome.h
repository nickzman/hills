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

#import <OpenGL/glu.h>
#import <Cocoa/Cocoa.h>

typedef struct
{
	float x,y,z;
	unsigned int color;
	float u, v;
} SKYDOME_VERTEX;

@interface SkyDome : NSObject
{
	SKYDOME_VERTEX *Vertices;
	int NumVertices;
	GLuint mListId;
}

- (void) generateDome;
- (void) renderSkyDome;
- (void)deleteList;

@end
