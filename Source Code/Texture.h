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
#import <OpenGL/glu.h>

@interface Texture : NSObject
{
    NSString		*mFilename;
    bool			mAlpha;
    bool			mMipmaps;
    bool			mRepeat;
    GLuint			mId;
	
	GLenum		_textureFormat;		// Format of texture (GL_RGB, GL_RGBA)
    NSSize		_textureSize;		// Width and height
    GLubyte		*_textureBytes;		// Texture data
}

+ (Texture *)textureWithFile: (NSString *)aName;

- (id)initWithFile: (NSString *)aName;
- (BOOL)_loadTexture: (NSString *)bitmapFile;
- (BOOL)bitmapFromImageRep: (NSBitmapImageRep *)theImage;
- (void)generateTextureWithBytes: (void *)texBytes refresh: (BOOL)isRefresh;
- (GLuint)name;

@end
