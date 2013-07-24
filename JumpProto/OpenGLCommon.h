/*
 *  OpenGLCommon.h
 *  BASICPROJECT
 *
 *  Created by gideong on 7/16/10.
 *  Copyright 2010 __MyCompanyName__. All rights reserved.
 *
 */

#import <OpenGLES/ES1/gl.h>
#import <OpenGLES/ES1/glext.h>


struct TexturedVertexData3DStruct
{
	GLfloat vertex[3];
	GLfloat normalVector[3];
	GLfloat texCoord[2];
};
typedef struct TexturedVertexData3DStruct TexturedVertexData3D;


struct GeoDataStruct
{
	const TexturedVertexData3D			*vertexData;
	const uint							numVertices;
};
typedef struct GeoDataStruct GeoData;


struct BoundingBoxStruct
{
	float p0[3];
	float p1[3];
};
typedef struct BoundingBoxStruct BoundingBox;
