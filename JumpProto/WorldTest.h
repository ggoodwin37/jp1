//
//  WorldTest.h
//  JumpProto
//
//  Created by gideong on 7/26/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "World.h"


/////////////////////////////////////////////////////////////////////////////////////////////////////////// TestBlock
@interface TestBlock : Block {
    
}

@property (nonatomic, readonly) UInt32 color;


-(id)initWithRect:(EmuRect)rect color:(UInt32)color;


@end


/////////////////////////////////////////////////////////////////////////////////////////////////////////// WorldTest
@interface WorldTest : NSObject {
    
}

+(void)runMiscTests;

+(void)runTestsOnWorld:(World *)world;

+(void)loadTestWorldTo:(World *)world loadFromDisk:(BOOL)fromDisk nextWorld:(BOOL)next;

+(void)loadTestWorldTo:(World *)world loadFromDisk:(BOOL)fromDisk startingWith:(NSString *)preferredStartingWorld;

@end
