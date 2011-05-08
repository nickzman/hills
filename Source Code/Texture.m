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

#import "Texture.h"

#define isPowerOfTwo(x)		(!(x & (x - 1)))

@implementation Texture

+ (Texture *)textureWithFile: (NSString *)aName
{
	return [[Texture alloc] initWithFile: aName];
}

- (id)initWithFile: (NSString *)aName
{
	mMipmaps = true;
	
    if (aName == nil)
        return nil;
		
#ifdef SCREENSAVER
	if( [self _loadTexture: [[NSBundle bundleForClass:[self class]] pathForImageResource:aName]])
#else
    NSString *resourcePath = [[NSBundle mainBundle] resourcePath];

	if( [self _loadTexture: [resourcePath stringByAppendingFormat:@"/%@", aName ]])
#endif
		[self generateTextureWithBytes: _textureBytes refresh: NO];

    return self;
}

- (BOOL)_loadTexture: (NSString *)bitmapFile
{
    NSBitmapImageRep	*theImage;

    if (theImage = [NSBitmapImageRep imageRepWithContentsOfFile: bitmapFile])
    {
        return [self bitmapFromImageRep: theImage]; 
    }

    return NO;
}

- (BOOL)bitmapFromImageRep: (NSBitmapImageRep *)theImage
{
    int					bitsPPixel, bytesPRow;
    GLubyte				*theImageData;
    GLint				maxTextureSize;
    int					rowNum, destRowNum;

    bitsPPixel	= [theImage bitsPerPixel];
    bytesPRow	= [theImage bytesPerRow];

    if (bitsPPixel == 24)        // No alpha channel
        _textureFormat = GL_RGB;
		
    else if( bitsPPixel == 32 )   // There is an alpha channel
        _textureFormat = GL_RGBA;

    glGetIntegerv(GL_MAX_TEXTURE_SIZE, &maxTextureSize);
	
    _textureSize.width	= [theImage pixelsWide];
    _textureSize.height	= [theImage pixelsHigh];

	//NSLog(@"Maximum Texture Size = %d", maxTextureSize);
	//NSLog(@"Texture Size = %f x %f", _textureSize.width, _textureSize.height);

    // Check if texture dimensions are valid
    if (((int)_textureSize.width > maxTextureSize) ||
		((int)_textureSize.height > maxTextureSize) ||
        (!isPowerOfTwo((int)_textureSize.width)) ||
		(!isPowerOfTwo((int)_textureSize.height)))
	{
        NSLog(@"Texture size is either too big, or not a power of 2");
        return NO;
    }

    _textureBytes		= calloc(bytesPRow * (int)_textureSize.height, 1);

    if (_textureBytes)
    {
        theImageData = [theImage bitmapData];

        for (rowNum = (int)_textureSize.height - 1, destRowNum = 0;
             rowNum >= 0;
             rowNum--, destRowNum++)
        {
            // Copy the entire row in one shot
            memcpy( _textureBytes + (destRowNum * bytesPRow),
                    theImageData + (rowNum * bytesPRow),
                    bytesPRow);
        }

        return YES;
    }

    return NO;
}

- (void)generateTextureWithBytes: (void *)texBytes refresh: (BOOL)isRefresh
{
	int type = (mAlpha) ? GL_RGBA : GL_RGB;
	bool _repeat = true;
    if (!isRefresh)
		glGenTextures (1, &mId);
	glBindTexture (GL_TEXTURE_2D, mId); 

	//glTexEnvi(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_MODULATE);	// texture blends with object background
	//glTexEnvi(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_DECAL);		// texture does NOT blend with object background
	
	glTexImage2D (GL_TEXTURE_2D, 0, type, _textureSize.width, _textureSize.height, 0, type, GL_UNSIGNED_BYTE, texBytes);
	int filter_min, filter_mag;
	
	filter_min = (mMipmaps) ? GL_LINEAR_MIPMAP_LINEAR : GL_NEAREST;
	filter_mag = (mMipmaps) ? GL_LINEAR_MIPMAP_LINEAR : GL_NEAREST;

	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, filter_min);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, filter_mag);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, (_repeat) ? GL_REPEAT : GL_CLAMP);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, (_repeat) ? GL_REPEAT : GL_CLAMP);
	
	if (mMipmaps)
		gluBuild2DMipmaps(GL_TEXTURE_2D, type, _textureSize.width, _textureSize.height, type, GL_UNSIGNED_BYTE, texBytes);

}

- (GLuint)getId
{
	return mId;
}

@end
