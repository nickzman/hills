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

#import "HeightField.h"
#import "Texture.h"

@interface HeightField (PrivateMethods)
- (void)loadImage:(NSString *)path;
- (void)loadDetailTexture:(NSString*)filename;
- (void)loadLightingTexture:(NSString*)filename;
@end

@implementation HeightField

+ (HeightField *)heightFieldWithFile:	(NSString *)filename
									detailTexture: (NSString *)detailTexture
									lightTexture: (NSString *)lightTexture
									gridsize:(unsigned int) gridsize
{
	HeightField *heightField = [HeightField alloc];
	
	if(heightField != nil)
	{
		[heightField loadImage:filename];
	
		[heightField makeHeightField:gridsize];
		
		[heightField loadDetailTexture: detailTexture];
		[heightField loadLightingTexture: lightTexture];
	}
	
    return heightField;
}

- (NSImage *) heightImage
{
	return mHeightImage;
}

- (id)init
{
	mListId = 0;
	return [super init];
}

- (void)loadDetailTexture:(NSString*)filename
{
	if(filename != nil)
		mDetailTexture = [Texture textureWithFile: filename];
}

- (void)loadLightingTexture:(NSString*)filename
{
	if(filename != nil)
		mLightTexture = [Texture textureWithFile:filename];
}

- (void) loadImage:(NSString *)path
{
	if (path && [path length] > 0)
	{
#ifdef SCREENSAVER
		NSString *ss_path = [[NSBundle bundleForClass:[self class]] pathForImageResource:path];
		
		mHeightImage = [[NSImage alloc] initWithContentsOfFile:ss_path];
#else
		// First we'll look in the main bundle for an image with this name
		mHeightImage = [NSImage imageNamed:path];
		
		if (mHeightImage == nil)
		{
			// Now we'll look for one by it's path
			mHeightImage = [[NSImage alloc] initWithContentsOfFile:path];
		}
#endif
	}
}

- (void)makeHeightField:(unsigned int)gridsize
{
    NSBitmapImageRep *bitmap;

    bitmap = [[NSBitmapImageRep alloc]initWithData: [mHeightImage TIFFRepresentation]];

    if (bitmap == nil)
	{
		NSLog(@"makeHeightField : failed to create bitmap");
	}
	else
	{
		GLubyte *srcBuffer = (GLubyte*)[bitmap bitmapData];
		
		// size is the number of vertex in a row in the resulting mesh
		// for example, we can have a 1024x1024 map but we want a 64x64 mesh
		// so we need to subsample the map
		unsigned int thegridsize = gridsize;
		
		float step = (float)[bitmap pixelsWide] / (float)gridsize;
		
		if (step < 1)
		{
			thegridsize = [bitmap pixelsWide];
			step = 1;
		}

		float lighttex_delta = 1.0f / [bitmap pixelsWide];
		float detailtex_delta = 32.0f / [bitmap pixelsWide];
		
		struct vertex v;
		int i = 0;

		// Loop through pixels in the map
		mNumberOfVertices = thegridsize * thegridsize;

		if(mVertices)
			free(mVertices);

		mVertices = (struct vertex *)malloc(sizeof(struct vertex) * mNumberOfVertices);

		int x, y;
		for (y=0; y < thegridsize; y++) {
			for (x=0; x < thegridsize; x++) {
				i = y*thegridsize + x;
				v.x = ( (float) x / (float) thegridsize - 0.5f);
				v.z = ( (float) y / (float) thegridsize - 0.5f);
				int x_pixel = (int) (((float)x * step) + 0.5);
				int y_pixel = (int) (((float)y * step) + 0.5);
				int index = (y_pixel * [bitmap pixelsWide]) + x_pixel;
				v.y = (float)(srcBuffer[index])/256.0f;
				v.u0 = (float)x*step        * detailtex_delta;
				v.v0 = 1.0f - (float)y*step * detailtex_delta;
				v.u1 = (float)x*step        * lighttex_delta;
				v.v1 = 1.0f - (float)y*step * lighttex_delta;
				mVertices[i] = v;
			}
		}

		// Make triangles indices
		mNumberOfIndices = (thegridsize-1)*(thegridsize-1)*6;
		
		if(mIndices)
			free(mIndices);
			
		mIndices = (GLuint *)malloc(sizeof(GLuint) * mNumberOfIndices);
		int j = 0;
		for (y=0; y < thegridsize-1; y++)
		{
			for (x=0; x < thegridsize-1; x++)
			{
				i = y*(thegridsize)+x;
				mIndices[j++] = i;
				mIndices[j++] = i+1;
				mIndices[j++] = i+thegridsize;
				mIndices[j++] = i+thegridsize+1;
				mIndices[j++] = i+thegridsize;
				mIndices[j++] = i+1;
			}
		}
	}
}

- (void)render: (BOOL)wireframe
{
    if (mListId)
	{
        glCallList (mListId);
        return;
    }
	else
	{
		mListId = 1;
		glNewList (mListId, GL_COMPILE_AND_EXECUTE);

		if(wireframe)
		{
			glEnable (GL_POLYGON_OFFSET_LINE);
			glPolygonMode (GL_FRONT_AND_BACK, GL_LINE);
		}
		else
		{
			glEnable (GL_POLYGON_OFFSET_FILL);
			glPolygonMode (GL_FRONT_AND_BACK, GL_FILL);
		}

		glVertexPointer (3, GL_FLOAT, sizeof(struct vertex), &mVertices[0].x);

		// Needs GL_ARB_multitexture
		// Texture Unit 0
		glActiveTextureARB (GL_TEXTURE0_ARB);
		glClientActiveTextureARB (GL_TEXTURE0_ARB);
		glEnable (GL_TEXTURE_2D);

		glTexCoordPointer (2, GL_FLOAT, sizeof(struct vertex), &mVertices[0].u0);
		glBindTexture (GL_TEXTURE_2D, [mDetailTexture getId]);
		glEnableClientState (GL_TEXTURE_COORD_ARRAY);
		glEnableClientState (GL_VERTEX_ARRAY);

		// Texture Unit 1
		glActiveTextureARB(GL_TEXTURE1_ARB);
		glClientActiveTextureARB(GL_TEXTURE1_ARB);
		glEnable (GL_TEXTURE_2D);

		// Set up the blending of the 2 textures
		glTexEnvi(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_MODULATE);

		glTexCoordPointer (2, GL_FLOAT, sizeof(struct vertex), &mVertices[0].u1);
		glBindTexture (GL_TEXTURE_2D, [mLightTexture getId]);
		glEnableClientState (GL_TEXTURE_COORD_ARRAY);
		glEnableClientState (GL_VERTEX_ARRAY);

		// Render the Terrain
		glDrawElements(GL_TRIANGLES, mNumberOfIndices, GL_UNSIGNED_INT, mIndices);

		// Switch off Texture Unit 1
		glDisable (GL_TEXTURE_2D);
		glDisableClientState (GL_VERTEX_ARRAY);
		glDisableClientState (GL_TEXTURE_COORD_ARRAY);

		// Half-switch off of Texture Unit 0
		glActiveTextureARB (GL_TEXTURE0_ARB);
		glClientActiveTextureARB (GL_TEXTURE0_ARB);
		glDisableClientState (GL_TEXTURE_COORD_ARRAY);
		glDisableClientState (GL_VERTEX_ARRAY);

		// Disable texture binding
		glBindTexture (GL_TEXTURE_2D, -1);

		glEndList();
	}
}

- (void)deleteList
{
	if(mListId != 0)
	{
		glDeleteLists( mListId, 1 );
		mListId = 0;
	}
}

- (void)dealloc
{
	[self deleteList];

	if(mVertices)
		free(mVertices);
	
	if(mIndices)
		free(mIndices);
		
	[mDetailTexture release];
	[mLightTexture release];
	[mHeightImage release];
		
	[super dealloc];
}

@end
