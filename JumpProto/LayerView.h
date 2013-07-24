//
//  LayerView.h
//  BASICPROJECT
//
//  Created by gideong on 7/1/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <OpenGLES/ES1/gl.h>
#import <OpenGLES/ES1/glext.h>
#import <Foundation/Foundation.h>


@interface LayerView : NSObject {

	
}

-(void)buildScene;
-(void)updateWithTimeDelta:(float)timeDelta;

// convenience
-(void)setupStandardOrthoView;
-(void)drawRectAt:(CGRect)rect r:(GLbyte)r g:(GLbyte)g b:(GLbyte)b a:(GLbyte)a;

@end
