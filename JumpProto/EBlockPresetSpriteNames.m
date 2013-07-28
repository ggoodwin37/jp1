//
//  EBlockPresetSpriteNames.m
//  JumpProto
//
//  Created by Gideon Goodwin on 1/1/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "EBlockPresetSpriteNames.h"

@implementation EBlockPresetSpriteNames


+(NSString *)getSpriteNameForPreset:(EBlockPreset)preset
{
    switch( preset )
    {
        case EBlockPreset_None:
            return nil;
            
        // batch 1
        case EBlockPreset_Test0:
            return @"bl_brick";
        case EBlockPreset_PlayerStart:
            return @"pr1_still";
        case EBlockPreset_MovingPlatformRightMedium:
            return @"bl_ice";
        case EBlockPreset_TestCrate:
            return @"bl_clown";
        case EBlockPreset_GroundColumn:
            return @"bl_column_mid";
        case EBlockPreset_OneWayU:
            return @"bl_oneway0_up";
        case EBlockPreset_OneWayL:
            return @"bl_oneway0_left";
        case EBlockPreset_OneWayR:
            return @"bl_oneway0_right";
        case EBlockPreset_OneWayD:
            return @"bl_oneway0_down";
        case EBlockPreset_PropSpikes:
            return @"props0_spikes";
        case EBlockPreset_PropSkull:
            return @"props0_skull";
        case EBlockPreset_PropGoal:
            return @"props0_goalflag_0";
        case EBlockPreset_GroundBrickAVTest:
            return @"bl_brickAVTest0_avlf";
        case EBlockPreset_PropFancyCrate:
            return @"bl_fancyCrate0";
        case EBlockPreset_ConveyorL:
            return @"bl_convL_1";
        case EBlockPreset_ConveyorR:
            return @"bl_convR_1";
        case EBlockPreset_BLTurf:
            return @"bl_turf_avlf";
        case EBlockPreset_TestGroupA:
            return @"bl_clown";
        case EBlockPreset_TestGroupB:
            return @"bl_fancyCrate0";
        case EBlockPreset_SillyEm0:
            return @"bl_sillyEm0";
        case EBlockPreset_SillyMax0:
            return @"bl_sillyMax0";
        case EBlockPreset_TestMeanieB:
            return @"props0_testMeanieB_0";
        case EBlockPreset_FaceBone:
            return @"badguy_faceBone0";
        case EBlockPreset_MineFloat:
            return @"badguy_cheapMineBlue";
        case EBlockPreset_MineCrate:
            return @"badguy_cheapMineRed";
        case EBlockPreset_GroundRusty:
            return @"bl_rusty";
        case EBlockPreset_GroundWood:
            return @"bl_wood";
        case EBlockPreset_GroundQuilt:
            return @"bl_quilt";
        case EBlockPreset_PropSpring:
            return @"prop_testSpring";
        case EBlockPreset_Crumbles1:
            return @"bl_crumbles1_crumbling2";
        case EBlockPreset_WoodCrate:
            return @"bl_wood_crate";
        case EBlockPreset_Algae:
            return @"bl_algae_avlf";
        case EBlockPreset_Qik:
            return @"bl_qik_avlf";
        case EBlockPreset_RedBrick:
            return @"bl_half_redbrick";
        case EBlockPreset_Lavender:
            return @"bl_half_lavender";
            
        // batch 2
            
        default:
            return @"icon_close";  // TODO: better "unknown" tile?
            
    }
    
}

@end
