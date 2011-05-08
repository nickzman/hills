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

#import "Camera.h"

#define	deg2rad(x) ((x)*0.0174532925194f)
#define	rad2deg(x) ((x)*57.295779514719f)

inline SVector cartesianToSpherical(CVector cvec)
{
    SVector	svec;

    svec.theta	= atan2(cvec.z, cvec.x);
    svec.phi	= atan2(cvec.y, sqrt( (cvec.x * cvec.x) + (cvec.z * cvec.z) ));
    svec.r		= sqrt( (cvec.x * cvec.x) + 
						(cvec.y * cvec.y) +
						(cvec.z * cvec.z) );
    
    return svec;
}

inline CVector sphericalToCartesian(SVector svec)
{
    CVector	cvec;

    cvec.x	= svec.r * cos(svec.phi) * cos(svec.theta);
    cvec.y	= svec.r * sin(svec.phi);
    cvec.z	= svec.r * cos(svec.phi) * sin(svec.theta);
    
    return cvec;
}

inline CVector vectorSubtract(const CVector a, const CVector b)
{
    CVector	r;

    r.x = a.x - b.x;
    r.y = a.y - b.y;
    r.z = a.z - b.z;
    
    return r;
}

inline CVector vectorAdd(const CVector a, const CVector b)
{
    CVector	r;

    r.x = a.x + b.x;
    r.y = a.y + b.y;
    r.z = a.z + b.z;
    
    return r;
}

inline CVector vectorNormalize(const CVector cvector)
{
    CVector	normalized_vector;

	float scale = (float) sqrt( (cvector.x * cvector.x) +
								(cvector.y * cvector.y) +
								(cvector.z * cvector.z) );
	
	if(scale == 0.0)
		return cvector;
	
	normalized_vector.x = cvector.x / scale;
	normalized_vector.y = cvector.y / scale;
	normalized_vector.z = cvector.z / scale;
	
	return normalized_vector;
}

inline CVector vectorScale(const float scale, const CVector cvector)
{
    CVector	scaled_vector;
    
    scaled_vector.x = cvector.x * scale;
    scaled_vector.y = cvector.y * scale;
    scaled_vector.z = cvector.z * scale;

    return scaled_vector;
}

@implementation Camera

- (void) lookAt_x:(float)x y:(float)y z:(float)z
{
	mLookAt.x = x;
	mLookAt.y = y;
	mLookAt.z = z;
}

- (void) positionAt_x:(float)x y:(float)y z:(float)z
{
	mPosition.x = x;
	mPosition.y = y;
	mPosition.z = z;
}

- (void) moveForwards:(float) distance;
{
	CVector dvector = vectorSubtract(mLookAt, mPosition);
	dvector = vectorNormalize(dvector);
	
	dvector = vectorScale(distance, dvector);
	mPosition = vectorAdd(mPosition, dvector);
	mLookAt = vectorAdd(mPosition, dvector);
}

- (void) moveBackwards:(float) distance;
{
	CVector dvector = vectorSubtract(mLookAt, mPosition);
	dvector = vectorNormalize(dvector);
	
	dvector = vectorScale(distance, dvector);

	mPosition = vectorSubtract(mPosition, dvector);
	mLookAt = vectorAdd(mPosition, dvector);
}

- (void) rotateByDegrees_x: (float)theta y: (float)phi
{
	SVector newPos = cartesianToSpherical(vectorSubtract(mPosition, mLookAt));
	
	// Limit the rotation in the y-axis as beyond this point the world
	// suddenly flips over. Not sure why this happens!
	
	if(phi > 89.0) phi = 89.0;
	if(phi < -89.0) phi = -89.0;
	
	newPos.theta		= deg2rad(theta);
	newPos.phi			= deg2rad(phi);

	mPosition = vectorAdd(sphericalToCartesian(newPos), mLookAt);
}

- (float) getXDegrees
{
	SVector pos = cartesianToSpherical(vectorSubtract(mPosition, mLookAt));
	
	return rad2deg(pos.theta);
}

- (float) getYDegrees
{
	SVector pos = cartesianToSpherical(vectorSubtract(mPosition, mLookAt));
	
	return rad2deg(pos.phi);
}

- (float) getDistance
{
	SVector svec = cartesianToSpherical(vectorSubtract(mPosition, mLookAt));
	
	return svec.r;
}

- (void) setDistance:(float)distance
{
	SVector newPos = cartesianToSpherical(vectorSubtract(mPosition, mLookAt));
	
	newPos.r = distance;
	
	if(newPos.r < 0.001)
		newPos.r = 0.0001;
	
	mPosition = vectorAdd(sphericalToCartesian(newPos), mLookAt);
}

- (void) render
{
    gluLookAt( mPosition.x, mPosition.y, mPosition.z,
               mLookAt.x, mLookAt.y, mLookAt.z,
               0.0f, 1.0f, 0.0f);
}

@end
