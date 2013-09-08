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

@class Texture;

struct vertex
{
	float x;
	float y;
	float z;
	float u0;
	float v0;
	float u1;
	float v1;
};

@interface HeightField : NSObject
{
	struct vertex *mVertices;
	GLsizei mNumberOfVertices;
	
	GLuint *mIndices;
	int mNumberOfIndices;
	
	NSImage *mHeightImage;
	
	id mDetailTexture;	// GLKTextureInfo on Mountain Lion, Texture on older cats
	id mLightTexture;
	
	GLuint mListId;
}

+ (HeightField *)heightFieldWithFile:	(NSString *)filename
									detailTexture: (NSString *)detailTexture
									lightTexture: (NSString *)lightTexture
									gridsize:(GLsizei) gridsize;
- (id)init;
- (void)render: (BOOL)wireframe;
- (void)deleteList;
- (void)dealloc;
- (NSImage *) heightImage;
- (void)makeHeightField:(GLsizei)gridsize;

@end
