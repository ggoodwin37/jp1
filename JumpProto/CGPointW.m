//
//  CGPointW.m
//  JumpProto
//
//  Created by gideong on 7/20/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "CGPointW.h"


@implementation  CGPointW

@synthesize x, y;

+(CGPointW *)fromPoint:(CGPoint)p
{
    CGPointW *pw = [[[CGPointW alloc] init] autorelease];
    pw.x = p.x;
    pw.y = p.y;
    return pw;
}

@end


