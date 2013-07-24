//
//  ILauncherUI.h
//  JumpProto
//
//  Created by Gideon Goodwin on 2/27/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//
#import <UIKit/UIKit.h>

//////////////////////////////////////////////////////////////////////// enums

enum LauncherUIDialogIdEnum
{
    LauncherUIDialog_None,
    LauncherUIDialog_NewPack,
    LauncherUIDialog_DeletePack,
    LauncherUIDialog_ExportPack,
    LauncherUIDialog_Count
};

typedef enum LauncherUIDialogIdEnum LauncherUIDialogId;


enum LauncherUILabelIdEnum
{
    LauncherUILabel_None,
    LauncherUILabel_1,
    LauncherUILabel_Count
};

typedef enum LauncherUILabelIdEnum LauncherUILabelId;


enum LauncherUIButtonSelectionEnum
{
    LauncherUIButton_None,
    LauncherUIButton_1,
    LauncherUIButton_2,
    LauncherUIButton_3,
    LauncherUIButton_Count
};

typedef enum LauncherUIButtonSelectionEnum LauncherUIButtonSelection;


//////////////////////////////////////////////////////////////////////// api

@protocol ILauncherUIParent

-(void)onDialogClosed:(LauncherUIDialogId)dialogId withStringInput:(NSString *)stringInput buttonSelection:(LauncherUIButtonSelection)button;

@end


@protocol ILauncherUIChild

-(void)setParent:(NSObject<ILauncherUIParent> *)parentWeakRef;
-(void)setLabel:(LauncherUILabelId)label toString:(NSString *)labelString;

@end
