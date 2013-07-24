//
//  TouchFeedbackLayerView.h
//  JumpProto
//
//  Created by gideong on 7/14/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LayerView.h"


@interface TouchFeedbackLayerView : LayerView {
    
    NSMutableArray *         m_touchStack;
    
    GLuint           m_vertexCount;
    GLfloat *        m_vertexData;
    GLbyte *         m_colorData;
    
}

-(void)clearTouches;
-(void)pushTouchAt:(CGPoint)p;


@end
