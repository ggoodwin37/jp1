//
//  HitZone.h
//  JumpProto
//
//  Created by gideong on 7/28/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


/////////////////////////////////////////////////////////////////////////////////////////////////////////// HitZone


@interface HitZone : NSObject {
    
}

-(BOOL)containsPoint:(CGPoint)p;

@end

/////////////////////////////////////////////////////////////////////////////////////////////////////////// RectHitZone


@interface RectHitZone : HitZone
{
    
    
}
@property (nonatomic, assign) CGRect rect;

-(id)initWithRect:(CGRect)rect;

@end
