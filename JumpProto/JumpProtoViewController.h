//
//  JumpProtoViewController.h
//  JumpProto
//
//  Created by gideong on 7/14/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "JumpProtoAppDelegate.h"
#import "JumpProtoLaunchViewController.h"
#import "EAGLView.h"
#import "MainDrawController.h"
#import "DpadInput.h"
#import "World.h"
#import "GlobalCommand.h"
#import "SpriteManager.h"

@interface JumpProtoViewController : UIViewController<IChildVC,DpadEventDelegate> {
    EAGLView                *m_mainGlView;
    MainDrawController      *m_mainDrawController;
    
    DpadInput               *m_dpadInput;
    World                   *m_world;
    GlobalButtonManager     *m_globalButtonManager;
    
    id<IParentVC>           m_parentVC;
    
    NSString                *m_startingLevel;
}

@property (nonatomic, readonly) EAGLView *mainGlView;

@property (nonatomic, retain) DpadInput *dpadInput;

@property (nonatomic, assign) BOOL loadFromDisk;

@end
