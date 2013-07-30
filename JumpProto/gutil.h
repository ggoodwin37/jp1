/*
 *  gutil.h
 *  pop_v0
 *
 *  Created by gideong on 4/25/10.
 *  Copyright 2010 __MyCompanyName__. All rights reserved.
 *
 */
#import <stdlib.h>
#import <math.h>
#import <mach/mach.h>
#import <mach/mach_time.h>
#import <CoreGraphics/CoreGraphics.h>

#define RadToDeg(x) ((x)*180.0f/M_PI)
#define DegToRad(x) ((x)*M_PI/180.0f)

#define OK_OR_NIL( myref )   ((myref) == nil ? @"nil" : @"ok")
#define YORN( mybool )       ((mybool)       ? @"y"   : @"n")

#define foo 0
#define bar 1

float frand();
long getUpTimeMs();

// there must be a library somewhere for these.
CGPoint addVectors( CGPoint first, CGPoint second );
CGPoint subtractVectors( CGPoint first, CGPoint second );
float vectorMagnitude( CGPoint vec );
CGPoint vectorScalarMult( CGPoint vec, float scalar );
CGPoint normalizeVector( CGPoint vec );
float dotProduct( CGPoint v1, CGPoint v2 );
CGPoint makeVectorFromPolar( float theta, float rX, float rY );
float sqDist( CGPoint p1, CGPoint p2 );
