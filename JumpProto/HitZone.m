//
//  HitZone.m
//  JumpProto
//
//  Created by gideong on 7/28/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "HitZone.h"

/////////////////////////////////////////////////////////////////////////////////////////////////////////// HitZone

@implementation HitZone

-(BOOL)containsPoint:(CGPoint)p
{
    return NO;
}

@end


/////////////////////////////////////////////////////////////////////////////////////////////////////////// RectHitZone

@implementation RectHitZone

@synthesize rect = m_rect;

-(id)initWithRect:(CGRect)rect
{
    if( self = [super init] )
    {
        m_rect = rect;
    }
    return self;
}


-(void)dealloc
{
    [super dealloc];
}


// override
-(BOOL)containsPoint:(CGPoint)p
{
    return CGRectContainsPoint( m_rect, p );
}


@end
