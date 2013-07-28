//
//  EBlockPreset.h
//  JumpProto
//
//  Created by gideong on 10/9/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

/////////////////////////////////////////////////////////////////////////////////////////////////////////// EBlockPreset

// note: Don't change the order of these or insert new ones before end. These get serialized.
enum EBlockPresetEnum
{
    EBlockPreset_None = 0,
    
    // batch 1: early test assets (24x24)
    EBlockPreset_Test0,
    EBlockPreset_PlayerStart,
    EBlockPreset_MovingPlatformRightMedium,
    EBlockPreset_TestCrate,
    
    EBlockPreset_GroundColumn,
    EBlockPreset_OneWayU,
    EBlockPreset_OneWayL,
    EBlockPreset_OneWayR,
    EBlockPreset_OneWayD,
    EBlockPreset_PropSpikes,
    EBlockPreset_PropSkull,
    EBlockPreset_PropGoal,
    EBlockPreset_GroundBrickAVTest,
    EBlockPreset_PropFancyCrate,
    
    EBlockPreset_ConveyorL,
    EBlockPreset_ConveyorR,
    
    EBlockPreset_BLTurf,
    
    EBlockPreset_TestGroupA,
    EBlockPreset_TestGroupB,
    
    EBlockPreset_SillyEm0,
    EBlockPreset_SillyMax0,
    
    EBlockPreset_TestMeanieB,
    
    EBlockPreset_FaceBone,
    EBlockPreset_MineFloat,
    EBlockPreset_MineCrate,
    
    EBlockPreset_GroundRusty,
    EBlockPreset_GroundWood,
    EBlockPreset_GroundQuilt,
    EBlockPreset_PropSpring,
    
    EBlockPreset_Crumbles1,
    
    EBlockPreset_WoodCrate,
    EBlockPreset_Algae,
    EBlockPreset_Qik,
    EBlockPreset_RedBrick,
    EBlockPreset_Lavender,
    
    // batch 2: slightly less early test assets, "tiny" motif, 8x8.
    // TODO assets
    
    
    EBlockPresetCount,
};
typedef enum EBlockPresetEnum EBlockPreset;


/////////////////////////////////////////////////////////////////////////////////////////////////////////// ICurrentBlockPresetStateHolder
@protocol ICurrentBlockPresetStateHolder

-(void)currentBlockPresetUpdated:(EBlockPreset)preset;
-(EBlockPreset)getCurrentBlockPreset;

@end


/////////////////////////////////////////////////////////////////////////////////////////////////////////// ICurrentBlockPresetStateConsumer
@protocol ICurrentBlockPresetStateConsumer

-(void)setPresetStateHolder:(id<ICurrentBlockPresetStateHolder>)holder;

@end