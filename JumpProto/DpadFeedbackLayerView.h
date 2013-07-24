//
//  DpadFeedbackLayerView.h
//  JumpProto
//
//  Created by gideong on 7/21/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LayerView.h"
#import "DpadInput.h"

@interface DpadFeedbackLayerView : LayerView<DpadEventDelegate> {
    CGRect m_bounds;
    TouchZone m_touchZone;

    BOOL m_leftPressed;
    BOOL m_rightPressed;
    CGPoint m_meanPointLeft;
    CGPoint m_meanPointRight;
    
}

// weak reference
@property (nonatomic, assign, setter=setDpadInputRef:) DpadInput *dpadInput;

-(id)initWithBounds:(CGRect)bounds forTouchZone:(TouchZone)touchZone;
-(void)onDpadEvent:(DpadEvent *)event;


@end
