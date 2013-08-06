//
//  ClearBufferLayerView.m
//  BASICPROJECT
//
//  Created by gideong on 7/16/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "ClearBufferLayerView.h"

@interface ClearBufferLayerView (private)


@end

@implementation ClearBufferLayerView


-(void)buildScene
{
    // TODO: wouldn't mind seeing a gradient rectangle here instead. can't be that much slower.
	glClearColor(0.1f, 0.1f, 0.3f, 1.0f);
	glClear( GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT );
}


-(void)updateWithTimeDelta:(float)timeDelta
{
}

@end
