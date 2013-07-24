//
//  CGPointW.h
//  JumpProto
//
//  Created by gideong on 7/20/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CGPointW : NSObject {
    
    float x;
    float y;
}

@property (nonatomic, assign ) float x;
@property (nonatomic, assign ) float y;

+(CGPointW *)fromPoint:(CGPoint)p;
@end

