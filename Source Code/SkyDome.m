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

// This code originally came from Sphere Games (http://www.spheregames.com)
// and converted to Objective-C.

#import "SkyDome.h"
#import "Texture.h"

#define DTOR ((float)M_PI/180.0f)
#define SQR(x) (x*x)

@implementation SkyDome

- (id) init
{
    self = [super init];
	
    if (self)
	{
		Vertices = nil;
		NumVertices = 0;
		mListId = 0;
    }
	
    return self;
}

- (void) generateDome
{
	const float radius = 75.0f;
	const float dtheta = 15.0f;
	const float dphi = 15.0f;
	const float hTile = 1.0f;
	const float vTile = 1.0f;
	
	int theta, phi;

	// Make sure our vertex array is clear
	if (Vertices) 
	{
		free(Vertices);
		Vertices = NULL;
		NumVertices = 0;
	}

	// Initialize our Vertex array
	NumVertices = (int)((360/dtheta)*(90/dphi)*4);
	Vertices = malloc(sizeof(SKYDOME_VERTEX) * NumVertices);
	memset((unsigned char *)Vertices, 0, sizeof(SKYDOME_VERTEX) * NumVertices);

	// Used to calculate the UV coordinates
	float vx, vy, vz, mag;

	// Generate the dome
	int n = 0;
	for (phi=0; phi <= 90 - dphi; phi += (int)dphi)
	{
		for (theta=0; theta <= 360 - dtheta; theta += (int)dtheta)
		{
			// Calculate the vertex at phi, theta
			Vertices[n].x = radius * sinf(phi*DTOR) * cosf(DTOR*theta);
			Vertices[n].y = radius * sinf(phi*DTOR) * sinf(DTOR*theta);
			Vertices[n].z = radius * cosf(phi*DTOR);

			// Create a vector from the origin to this vertex
			vx = Vertices[n].x;
			vy = Vertices[n].y;
			vz = Vertices[n].z;

			// Normalize the vector
			mag = (float)sqrt(SQR(vx)+SQR(vy)+SQR(vz));
			vx /= mag;
			vy /= mag;
			vz /= mag;

			// Calculate the spherical texture coordinates
			Vertices[n].u = hTile * (float)(atan2(vx, vz)/(M_PI*2)) + 0.5f;
			Vertices[n].v = vTile * (float)(asinf(vy) / M_PI) + 0.5f;		
			n++;

			// Calculate the vertex at phi+dphi, theta
			Vertices[n].x = radius * sinf((phi+dphi)*DTOR) * cosf(theta*DTOR);
			Vertices[n].y = radius * sinf((phi+dphi)*DTOR) * sinf(theta*DTOR);
			Vertices[n].z = radius * cosf((phi+dphi)*DTOR);
			
			// Calculate the texture coordinates
			vx = Vertices[n].x;
			vy = Vertices[n].y;
			vz = Vertices[n].z;

			mag = (float)sqrt(SQR(vx)+SQR(vy)+SQR(vz));
			vx /= mag;
			vy /= mag;
			vz /= mag;

			Vertices[n].u = hTile * (float)(atan2(vx, vz)/(M_PI*2)) + 0.5f;
			Vertices[n].v = vTile * (float)(asinf(vy) / M_PI) + 0.5f;		
			n++;

			// Calculate the vertex at phi, theta+dtheta
			Vertices[n].x = radius * sinf(DTOR*phi) * cosf(DTOR*(theta+dtheta));
			Vertices[n].y = radius * sinf(DTOR*phi) * sinf(DTOR*(theta+dtheta));
			Vertices[n].z = radius * cosf(DTOR*phi);
			
			// Calculate the texture coordinates
			vx = Vertices[n].x;
			vy = Vertices[n].y;
			vz = Vertices[n].z;

			mag = (float)sqrt(SQR(vx)+SQR(vy)+SQR(vz));
			vx /= mag;
			vy /= mag;
			vz /= mag;

			Vertices[n].u = hTile * (float)(atan2(vx, vz)/(M_PI*2)) + 0.5f;
			Vertices[n].v = vTile * (float)(asinf(vy) / M_PI) + 0.5f;		
			n++;

			if (phi > -90 && phi < 90)
			{
				// Calculate the vertex at phi+dphi, theta+dtheta
				Vertices[n].x = radius * sinf((phi+dphi)*DTOR) * cosf(DTOR*(theta+dtheta));
				Vertices[n].y = radius * sinf((phi+dphi)*DTOR) * sinf(DTOR*(theta+dtheta));
				Vertices[n].z = radius * cosf((phi+dphi)*DTOR);
				
				// Calculate the texture coordinates
				vx = Vertices[n].x;
				vy = Vertices[n].y;
				vz = Vertices[n].z;

				mag = (float)sqrt(SQR(vx)+SQR(vy)+SQR(vz));
				vx /= mag;
				vy /= mag;
				vz /= mag;

				Vertices[n].u = hTile * (float)(atan2(vx, vz)/(M_PI*2)) + 0.5f;
				Vertices[n].v = vTile * (float)(asinf(vy) / M_PI) + 0.5f;		
				n++;
			}
		}
	}

	// Fix the problem at the seam
	int i;
	for (i=0; i < NumVertices-3; i++)
	{
		if (Vertices[i].u - Vertices[i+1].u > 0.9f)
			Vertices[i+1].u += 1.0f;

		if (Vertices[i+1].u - Vertices[i].u > 0.9f)
			Vertices[i].u += 1.0f;

		if (Vertices[i].u - Vertices[i+2].u > 0.9f)
			Vertices[i+2].u += 1.0f;

		if (Vertices[i+2].u - Vertices[i].u > 0.9f)
			Vertices[i].u += 1.0f;

		if (Vertices[i+1].u - Vertices[i+2].u > 0.9f)
			Vertices[i+2].u += 1.0f;

		if (Vertices[i+2].u - Vertices[i+1].u > 0.9f)
			Vertices[i+1].u += 1.0f;

		if (Vertices[i].v - Vertices[i+1].v > 0.8f)
			Vertices[i+1].v += 1.0f;

		if (Vertices[i+1].v - Vertices[i].v > 0.8f)
			Vertices[i].v += 1.0f;

		if (Vertices[i].v - Vertices[i+2].v > 0.8f)
			Vertices[i+2].v += 1.0f;

		if (Vertices[i+2].v - Vertices[i].v > 0.8f)
			Vertices[i].v += 1.0f;

		if (Vertices[i+1].v - Vertices[i+2].v > 0.8f)
			Vertices[i+2].v += 1.0f;

		if (Vertices[i+2].v - Vertices[i+1].v > 0.8f)
			Vertices[i+1].v += 1.0f;
	}

}

- (void) renderSkyDome
{
    if (mListId != 0)
	{
        glCallList (mListId);
        return;
    }
	else
	{
		mListId = 2;
		glNewList (mListId, GL_COMPILE_AND_EXECUTE);

		glTranslatef(0.0f, -5.0f, 0.0f);
		glRotatef(270, 1.0f, 0.0f, 0.0f);

		float start_colour[3] = {0.6f, 0.8f, 0.98f};
		float end_colour[3] = {0.067f, 0.196f, 0.541f};

		glShadeModel(GL_SMOOTH);    
		glBegin(GL_TRIANGLE_STRIP);
		
		int i;
		for (i=0; i < NumVertices; i++)
		{
			float percentage = Vertices[i].z / 40.0f;
			
			float red = ((end_colour[0] - start_colour[0]) * percentage) + start_colour[0];
			float green = ((end_colour[1] - start_colour[1]) * percentage) + start_colour[1];
			float blue = ((end_colour[2] - start_colour[2]) * percentage) + start_colour[2];
			
			glColor3f(red, green, blue);

			//glTexCoord2f(Vertices[i].u, Vertices[i].v);
			glVertex3f(Vertices[i].x, Vertices[i].y, Vertices[i].z);
		}

		//glShadeModel(GL_FLAT);
		glColor3f(1.0f, 1.0f, 1.0f);
		glEnd();

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

- (void) release
{
	[self deleteList];

	if (Vertices)
	{
		free(Vertices);
		Vertices = NULL;
	}
}

@end
