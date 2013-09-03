//
//  ISolidObject.h
//  JumpProto
//
//  Created by Gideon Goodwin on 11/7/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "gutil.h"
#import "sharedTypes.h"
#import "ERDirection.h"
#import "Emu.h"

@class BlockProps;

@protocol ISolidObject <NSObject>

-(BOOL)isGroup;
-(BOOL)isGroupElement;

-(BlockProps *)              getProps;

-(EmuPoint)                  getV;
-(void)                      setV:(EmuPoint)v;

-(EmuPoint)                  getMotive;        // signed velocity
-(EmuPoint)                  getMotiveAccel;   // signed velocity delta

// velocity updater support
-(void)changePositionOnXAxis:(BOOL)onXAxis signedMoveOffset:(Emu)didMoveOffset elbowRoom:(id)elbowRoomIn;

-(NSString *)getKey;

-(void)bouncedOnXAxis:(BOOL)xAxis;

// returns YES if a bounce happened already, so we can avoid triggering a distinct bounce event
//  on the same frame. conceptually this can return any information that may be useful later, but
//  right now we just have the bounced flag.
-(BOOL)collidedInto:(NSObject<ISolidObject> *)node inDir:(ERDirection)dir usePropOverrides:(BOOL)propOverrides hurtyMaskOverride:(UInt32)hurtyOverride goalOverride:(UInt32)goalOverride springyOverride:(UInt32)springyOverride;

@end

typedef NSObject<ISolidObject> ASolidObject;
