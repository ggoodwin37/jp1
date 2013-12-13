//
//  IParentChildVC.h
//  JumpProto
//
//  Created by Gideon Goodwin on 12/12/13.
//
//

#import <Foundation/Foundation.h>

@protocol IAppStartStop <NSObject>

-(void)onAppStart;
-(void)onAppStop;

@end


@protocol IParentVC <NSObject>

-(void)onChildClosing:(id)child withOptionalLevelName:(NSString *)optLevelName;

@end


@protocol IChildVC <IAppStartStop>

-(void)setParentDelegate:(id<IParentVC>)parent;
-(void)setStartingLevel:(NSString *)levelName;

@end
