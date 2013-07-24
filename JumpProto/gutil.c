/*
 *  gutil.c
 *  pop_v0
 *
 *  Created by gideong on 4/25/10.
 *  Copyright 2010 __MyCompanyName__. All rights reserved.
 *
 */

#include "gutil.h"


// assume main() or somewhere has a line like:
//  srandom(time(NULL));

inline float frand()
{
	return ((float)(random() & 0x0fff)) / ((float)0x1000);
}

// usage note: this appears to wrap around fairly often, on the order of minutes. Whenever this is used
//  should check for unexpected wraps.
long getUpTimeMs()
{
	static mach_timebase_info_data_t sTimebaseInfo;
	// If this is the first time we've run, get the timebase.
	// We can use denom == 0 to indicate that sTimebaseInfo is
	// uninitialised because it makes no sense to have a zero
	// denominator is a fraction.
	if ( sTimebaseInfo.denom == 0 ) {
		mach_timebase_info(&sTimebaseInfo);
	}
	uint64_t thenano;
	thenano = mach_absolute_time() * sTimebaseInfo.numer / sTimebaseInfo.denom;
	return (long)( thenano / 1000000.0 );
}


CGPoint addVectors( CGPoint first, CGPoint second )
{
	return CGPointMake( first.x + second.x, first.y + second.y );
}

CGPoint subtractVectors( CGPoint first, CGPoint second )
{
	return CGPointMake( first.x - second.x, first.y - second.y );
}

float vectorMagnitude( CGPoint vec )
{
	return sqrtf( (vec.x * vec.x) + (vec.y * vec.y) );
}

CGPoint vectorScalarMult( CGPoint vec, float scalar )
{
	return CGPointMake( vec.x * scalar, vec.y * scalar );
}

CGPoint normalizeVector( CGPoint vec )
{
	float mag = vectorMagnitude( vec );
	if( mag > 0 )
	{
		return vectorScalarMult( vec, 1.0 / mag );
	}
	return CGPointMake( 0.0, 0.0 );
}

float dotProduct( CGPoint v1, CGPoint v2 )
{
	return (v1.x * v2.x) + (v1.y * v2.y);
}

CGPoint makeVectorFromPolar( float theta, float rX, float rY )
{
	return CGPointMake( rX * cosf( theta ), rY * sinf( theta ) );
}

// return the square of the distance between the points
float sqDist( CGPoint p1, CGPoint p2 )
{
    float a = p2.x - p1.x;
    float b = p2.y - p1.y;
    return (a * a) + (b * b);
}

