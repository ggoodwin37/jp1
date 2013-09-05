//
//  IRedBluState.h
//  JumpProto
//
//  Created by Gideon iOS on 9/4/13.
//
//

#import <Foundation/Foundation.h>

// this is broken into its own file so we can reference this from lower modules (e.g. sprite) without importing all of World.
// TODO: consider having an IWorldState file where several such protocols can live.

@protocol IRedBluStateProvider <NSObject>

-(BOOL)isCurrentlyRed;
-(void)toggleState;

@end
