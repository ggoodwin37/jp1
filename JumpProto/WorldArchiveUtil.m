//
//  WorldArchiveUtil.m
//  JumpProto
//
//  Created by gideong on 10/7/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "WorldArchiveUtil.h"
#import "ArchiveFormat.h"
#import "constants.h"
#import "SpriteAutoVariationDefines.h"
#import "Emu.h"
#import "LevelUtil.h"
#import "BadGuyActor.h"
#import "EventActor.h"

@implementation WorldArchiveUtil


+(AFBlockProps *)readAFBlockPropsFromBlockProps:(BlockProps *)blockProps
{
    AFBlockProps *afBlockProps;
    afBlockProps = [[[AFBlockProps alloc] init] autorelease];
    afBlockProps.token = blockProps.token;
    afBlockProps.canMoveFreely = blockProps.canMoveFreely;
    afBlockProps.affectedByGravity = blockProps.affectedByGravity;
    afBlockProps.affectedByFriction = blockProps.affectedByFriction;
    afBlockProps.bounceDampFactor = blockProps.bounceDampFactor;
    afBlockProps.initialVelocity = FlPointFromEmuPoint( blockProps.initialVelocity );
    return afBlockProps;
}


+(void)setProps_batch1Style_ForBlock:(Block *)block fromPreset:(EBlockPreset)preset
{
    switch( preset )
    {
        // just ground
        case EBlockPreset_Test0:
        case EBlockPreset_GroundColumn:
        case EBlockPreset_GroundBrickAVTest:
        case EBlockPreset_BLTurf:
        case EBlockPreset_GroundRusty:
        case EBlockPreset_GroundWood:
        case EBlockPreset_GroundQuilt:
        case EBlockPreset_Algae:
        case EBlockPreset_RedBrick:
        case EBlockPreset_Lavender:
            break;
            
        // one-way ground
        case EBlockPreset_OneWayU:
            block.props.solidMask = BlockEdgeDirMask_Up;
            break;
        case EBlockPreset_OneWayL:
            block.props.solidMask = BlockEdgeDirMask_Left;
            break;
        case EBlockPreset_OneWayR:
            block.props.solidMask = BlockEdgeDirMask_Right;
            break;
        case EBlockPreset_OneWayD:
            block.props.solidMask = BlockEdgeDirMask_Down;
            break;
            
        case EBlockPreset_PropSpikes:
            block.props.hurtyMask = BlockEdgeDirMask_Up;
            break;
            
        case EBlockPreset_PropSkull:
            block.props.hurtyMask = BlockEdgeDirMask_Full;
            break;
            
        case EBlockPreset_MineCrate:
            block.props.canMoveFreely = YES;
            block.props.affectedByGravity = YES;
            block.props.affectedByFriction = YES;
            block.props.hurtyMask = BlockEdgeDirMask_Full;
            break;

        case EBlockPreset_MineFloat:
            block.props.canMoveFreely = YES;
            block.props.bounceDampFactor = 1.f;    
            block.props.initialVelocity = EmuPointMake( MOVING_PLATFORM_RIGHT_MEDIUM_VX * 0.9f, 0.f );
            block.props.hurtyMask = BlockEdgeDirMask_Full;
            break;

        case EBlockPreset_PropGoal:
            block.props.isGoalBlock = YES;
            break;
            
        case EBlockPreset_PropSpring:
            block.props.springyMask = BlockEdgeDirMask_Up;
            break;

        case EBlockPreset_MovingPlatformRightMedium:
            block.props.canMoveFreely = YES;
            block.props.bounceDampFactor = 1.f;    
            block.props.initialVelocity = EmuPointMake( MOVING_PLATFORM_RIGHT_MEDIUM_VX, 0.f );
            break;
        
        case EBlockPreset_PropFancyCrate:
        case EBlockPreset_TestCrate:
        case EBlockPreset_WoodCrate:
        case EBlockPreset_Qik:
            block.props.canMoveFreely = YES;
            block.props.affectedByGravity = YES;
            block.props.affectedByFriction = YES;
            break;
        
        case EBlockPreset_ConveyorL:
            block.props.solidMask = BlockEdgeDirMask_Up;
            block.props.xConveyor = -CONVEYOR_VX;
            break;
        case EBlockPreset_ConveyorR:
            block.props.solidMask = BlockEdgeDirMask_Up;
            block.props.xConveyor =  CONVEYOR_VX;
            break;
            
        case EBlockPreset_TestGroupA:
            NSLog( @"Deprecated code, I only expect to see testGroups in old levels." );
            block.props.canMoveFreely = YES;
            block.props.affectedByGravity = YES;
            block.props.affectedByFriction = YES;
            block.groupId = 0x1d1;
            break;
        case EBlockPreset_TestGroupB:
            NSLog( @"Deprecated code, I only expect to see testGroups in old levels." );
            block.props.canMoveFreely = YES;
            block.props.affectedByGravity = YES;
            block.props.affectedByFriction = YES;
            block.groupId = 0x1d2;
            break;

        case EBlockPreset_SillyEm0:
        case EBlockPreset_SillyMax0:
            // TODO: just act as crates for now...can use these to play with random effects if you get around to it.
            block.props.canMoveFreely = YES;
            block.props.affectedByGravity = YES;
            block.props.affectedByFriction = YES;
            break;
        default:
            break;
    }
}


+(void)setProps_batch2Style_ForBlock:(Block *)block fromPreset:(EBlockPreset)preset
{
    switch( preset )
    {
        // just ground
        case EBlockPreset_tiny_bl_0:
        case EBlockPreset_tiny_bl_1:
        case EBlockPreset_tiny_bl_2:
        case EBlockPreset_tiny_bl_3:
        case EBlockPreset_tiny_bl_4:
        case EBlockPreset_tiny_bl_5:
        case EBlockPreset_tiny_bl_6:
        case EBlockPreset_tiny_bl_7:
        case EBlockPreset_tiny_bl_8:
        case EBlockPreset_tiny_bl_9:
        case EBlockPreset_tiny_col:
        case EBlockPreset_tiny_bl_stretch:
        case EBlockPreset_tiny_bl_turf1:
        case EBlockPreset_tiny_bl_turf2:
        case EBlockPreset_tiny_avPlain:
        case EBlockPreset_tiny_sprtiny_0:
        case EBlockPreset_tiny_sprtiny_1:
        case EBlockPreset_tiny_sprtiny_2:
        case EBlockPreset_tiny_sprtiny_3:
        case EBlockPreset_tiny_pipe:
        case EBlockPreset_tiny_pipe_bub:
            break;
            
        // crates
        case EBlockPreset_tiny_cr_1:
        case EBlockPreset_tiny_cr_2:
        case EBlockPreset_tiny_bigcr:
        case EBlockPreset_tiny_avCrate:
            block.props.canMoveFreely = YES;
            block.props.affectedByGravity = YES;
            block.props.affectedByFriction = YES;
            break;

        case EBlockPreset_tiny_conveyor_l:
            block.props.solidMask = BlockEdgeDirMask_Up;
            block.props.xConveyor = -CONVEYOR_VX;
            break;
        case EBlockPreset_tiny_conveyor_r:
            block.props.solidMask = BlockEdgeDirMask_Up;
            block.props.xConveyor = CONVEYOR_VX;
            break;
            
        case EBlockPreset_tiny_oneway_u:
            block.props.solidMask = BlockEdgeDirMask_Up;
            break;
        case EBlockPreset_tiny_oneway_l:
            block.props.solidMask = BlockEdgeDirMask_Left;
            break;
        case EBlockPreset_tiny_oneway_r:
            block.props.solidMask = BlockEdgeDirMask_Right;
            break;
        case EBlockPreset_tiny_oneway_d:
            block.props.solidMask = BlockEdgeDirMask_Down;
            break;

        case EBlockPreset_tiny_spikes_u:
            block.props.hurtyMask = BlockEdgeDirMask_Up;
            break;
        case EBlockPreset_tiny_spikes_l:
            block.props.hurtyMask = BlockEdgeDirMask_Left;
            break;
        case EBlockPreset_tiny_spikes_r:
            block.props.hurtyMask = BlockEdgeDirMask_Right;
            break;
        case EBlockPreset_tiny_spikes_d:
            block.props.hurtyMask = BlockEdgeDirMask_Down;
            break;

        case EBlockPreset_tiny_bl_exit:
            block.props.isGoalBlock = YES;
            break;
        
        case EBlockPreset_tiny_mv_plat_l:
            block.props.canMoveFreely = YES;
            block.props.bounceDampFactor = 1.f;
            block.props.initialVelocity = EmuPointMake( -MOVING_PLATFORM_RIGHT_MEDIUM_VX, 0.f );
            block.props.solidMask = BlockEdgeDirMask_Up | BlockEdgeDirMask_Left | BlockEdgeDirMask_Right;
            block.props.followsAiHints = YES;  // so it can bounce
            block.props.immovable = YES;
            break;
        case EBlockPreset_tiny_mv_plat_r:
            block.props.canMoveFreely = YES;
            block.props.bounceDampFactor = 1.f;
            block.props.initialVelocity = EmuPointMake( MOVING_PLATFORM_RIGHT_MEDIUM_VX, 0.f );
            block.props.solidMask = BlockEdgeDirMask_Up | BlockEdgeDirMask_Left | BlockEdgeDirMask_Right;
            block.props.followsAiHints = YES;  // so it can bounce
            block.props.immovable = YES;
            break;
            
        case EBlockPreset_tiny_aiBounceHint:
            block.props.isAiHint = YES;
            break;
            
        case EBlockPreset_tiny_bl_wallJump:
            block.props.isWallJumpable = YES;
            break;
            
        // TODOs
        case EBlockPreset_tiny_bl_ice:
            break;
            
        // TODO: implement red/blu switching. for now just pretend blu is active.
        case EBlockPreset_tiny_redblu_red:
            block.props.solidMask = 0;
            break;
        case EBlockPreset_tiny_redblu_blu:
            break;
            
        // TODO creeps
        case EBlockPreset_tiny_creep_martian:
        case EBlockPreset_tiny_creep_mosquito:
            block.props.hurtyMask = BlockEdgeDirMask_Full;
            break;
            
        case EBlockPreset_tiny_mineCrate:
            block.props.canMoveFreely = YES;
            block.props.affectedByGravity = YES;
            block.props.affectedByFriction = YES;
            block.props.hurtyMask = BlockEdgeDirMask_Full;
            break;
            
        default:
            break;
    }
}


+(void)setPropsForBlock:(Block *)block fromPreset:(EBlockPreset)preset
{
    // defaults
    block.props.canMoveFreely = NO;
    block.props.affectedByGravity = NO;
    block.props.affectedByFriction = NO;
    block.props.bounceDampFactor = 0.f;
    block.props.initialVelocity = EmuPointMake( 0, 0 );
    block.props.solidMask = BlockEdgeDirMask_Full;
    block.props.xConveyor = 0.f;
    block.props.hurtyMask = BlockEdgeDirMask_None;
    block.props.isGoalBlock = NO;
    block.props.isActorBlock = NO;
    block.props.isPlayerBlock = NO;
    
    if( preset == EBlockPreset_PlayerStart || preset == EBlockPreset_tiny_playerStart || preset == EBlockPreset_None )
    {
        NSAssert( NO, @"Didn't expect this." );
    }
    
    // these are additive
    [WorldArchiveUtil setProps_batch1Style_ForBlock:block fromPreset:preset];
    [WorldArchiveUtil setProps_batch2Style_ForBlock:block fromPreset:preset];
}


+(float)getAnimDurForPreset:(EBlockPreset)preset
{
    switch( preset )
    {
        // batch 1
        case EBlockPreset_PropGoal:
            return 0.5f;
            
        case EBlockPreset_ConveyorL:
        case EBlockPreset_ConveyorR:
            return 0.1f;
            
        // batch 2
        case EBlockPreset_tiny_conveyor_l:
        case EBlockPreset_tiny_conveyor_r:
            return 0.15f;
            
        case EBlockPreset_tiny_spikes_u:
        case EBlockPreset_tiny_spikes_l:
        case EBlockPreset_tiny_spikes_r:
        case EBlockPreset_tiny_spikes_d:
            return 0.35f;
            
        case EBlockPreset_tiny_mv_plat_l:
        case EBlockPreset_tiny_mv_plat_r:
            return 0.3f;

        default:
            return 0.f;
    }
}


+(NSString *)getSpriteResourceName_batch1Style_forPreset:(EBlockPreset)preset fourWayAVCode:(UInt32)fourWayAVCode
{
    switch( preset )
    {
        // just ground
        case EBlockPreset_Test0:
            return @"bl_brick";
            
        case EBlockPreset_MovingPlatformRightMedium:
            return @"bl_ice";
            
        case EBlockPreset_TestCrate:
            return @"bl_clown";

            
        case EBlockPreset_GroundColumn:
            if( ! (fourWayAVCode & AutoVariationMask_U) )
            {
                return @"bl_column_top";
            }
            else if( ! (fourWayAVCode & AutoVariationMask_D) )
            {
                return @"bl_column_bottom";
            }
            else
            {
                return @"bl_column_mid";
            }
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
            return @"props0_goalflag_anim";
        case EBlockPreset_GroundBrickAVTest:
            return [NSString stringWithFormat:@"bl_brickAVTest0_avl%lx", (fourWayAVCode & 0x0f)];
        case EBlockPreset_PropFancyCrate:
            return @"bl_fancyCrate0";
        case EBlockPreset_ConveyorL:
            return @"convL";
        case EBlockPreset_ConveyorR:
            return @"convR";
        case EBlockPreset_BLTurf:
            return [NSString stringWithFormat:@"bl_turf_avl%lx", (fourWayAVCode & 0x0f)];
        case EBlockPreset_TestGroupA:
            return @"bl_clown";
        case EBlockPreset_TestGroupB:
            return @"bl_fancyCrate0";
        case EBlockPreset_SillyEm0:
            return @"bl_sillyEm0";
        case EBlockPreset_SillyMax0:
            return @"bl_sillyMax0";
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
        case EBlockPreset_WoodCrate:
            return @"bl_wood_crate";
        case EBlockPreset_Algae:
            return [NSString stringWithFormat:@"bl_algae_avl%lx", (fourWayAVCode & 0x0f)];
        case EBlockPreset_Qik:
            return [NSString stringWithFormat:@"bl_qik_avl%lx", (fourWayAVCode & 0x0f)];
        case EBlockPreset_RedBrick:
            return @"bl_half_redbrick";
        case EBlockPreset_Lavender:
            return @"bl_half_lavender";
            
        default:
            return nil;
    }
}


+(NSString *)getSpriteResourceName_batch2Style_forPreset:(EBlockPreset)preset fourWayAVCode:(UInt32)fourWayAVCode
{
    switch( preset )
    {
        case EBlockPreset_tiny_bl_0: return @"tiny-bl-0";
        case EBlockPreset_tiny_bl_1: return @"tiny-bl-1";
        case EBlockPreset_tiny_bl_2: return @"tiny-bl-2";
        case EBlockPreset_tiny_bl_3: return @"tiny-bl-3";
        case EBlockPreset_tiny_bl_4: return @"tiny-bl-4";
        case EBlockPreset_tiny_bl_5: return @"tiny-bl-5";
        case EBlockPreset_tiny_bl_6: return @"tiny-bl-6";
        case EBlockPreset_tiny_bl_7: return @"tiny-bl-7";
        case EBlockPreset_tiny_bl_8: return @"tiny-bl-8";
        case EBlockPreset_tiny_bl_9: return @"tiny-bl-9";
            
        case EBlockPreset_tiny_col:
            if( ! (fourWayAVCode & AutoVariationMask_U) )
            {
                return @"tiny-col-t";
            }
            else if( ! (fourWayAVCode & AutoVariationMask_D) )
            {
                return @"tiny-col-b";
            }
            else
            {
                return @"tiny-col-m";
            }

        case EBlockPreset_tiny_bl_stretch:
            if( ! (fourWayAVCode & AutoVariationMask_L) )
            {
                return @"tiny-bl-stretch-l";
            }
            else if( ! (fourWayAVCode & AutoVariationMask_R) )
            {
                return @"tiny-bl-stretch-r";
            }
            else
            {
                return @"tiny-bl-stretch-m";
            }

        case EBlockPreset_tiny_bl_turf1:
            if( ! (fourWayAVCode & AutoVariationMask_U) )
            {
                return @"tiny-bl-turf1-t";
            }
            else
            {
                return @"tiny-bl-turf1-m";
            }

        case EBlockPreset_tiny_avPlain:
            return [NSString stringWithFormat:@"tiny-av-plain-1_%lx", (fourWayAVCode & 0x0f)];

        case EBlockPreset_tiny_bl_turf2:
            if( ! (fourWayAVCode & AutoVariationMask_U) )
            {
                return @"tiny-bl-turf2-t";
            }
            else
            {
                return @"tiny-bl-turf2-m";
            }
            
        case EBlockPreset_tiny_cr_1: return @"tiny-cr-1";
        case EBlockPreset_tiny_cr_2: return @"tiny-cr-2";
        case EBlockPreset_tiny_bigcr: return @"tiny-bigcr";
            
        case EBlockPreset_tiny_avCrate:
            return [NSString stringWithFormat:@"tiny-av-crate-1_%lx", (fourWayAVCode & 0x0f)];
            
        case EBlockPreset_tiny_conveyor_l: return @"tiny-conveyor-l";
        case EBlockPreset_tiny_conveyor_r: return @"tiny-conveyor-r";
        case EBlockPreset_tiny_oneway_u: return @"tiny-oneway-u";
        case EBlockPreset_tiny_oneway_l: return @"tiny-oneway-l";
        case EBlockPreset_tiny_oneway_r: return @"tiny-oneway-r";
        case EBlockPreset_tiny_oneway_d: return @"tiny-oneway-d";
        case EBlockPreset_tiny_spikes_u: return @"tiny-spikes-u";
        case EBlockPreset_tiny_spikes_l: return @"tiny-spikes-l";
        case EBlockPreset_tiny_spikes_r: return @"tiny-spikes-r";
        case EBlockPreset_tiny_spikes_d: return @"tiny-spikes-d";
        case EBlockPreset_tiny_bl_wallJump: return @"tiny-bl-walljump";
        case EBlockPreset_tiny_bl_exit: return @"tiny-exit";
        case EBlockPreset_tiny_mv_plat_l: return @"tiny-mv-plat";
        case EBlockPreset_tiny_mv_plat_r: return @"tiny-mv-plat";
        case EBlockPreset_tiny_sprtiny_0: return @"tiny-sprtiny-0";
        case EBlockPreset_tiny_sprtiny_1: return @"tiny-sprtiny-1";
        case EBlockPreset_tiny_sprtiny_2: return @"tiny-sprtiny-2";
        case EBlockPreset_tiny_sprtiny_3: return @"tiny-sprtiny-3";
        case EBlockPreset_tiny_pipe:
            if( ! (fourWayAVCode & AutoVariationMask_U) && ! (fourWayAVCode & AutoVariationMask_D) )
            {
                return @"tiny-pipe-lr";
            }
            else if( ! (fourWayAVCode & AutoVariationMask_R) && ! (fourWayAVCode & AutoVariationMask_L) )
            {
                return @"tiny-pipe-ud";
            }
            else
            {
                return @"tiny-pipe-m";
            }

        case EBlockPreset_tiny_pipe_bub: return @"tiny-pipe-bub";

        case EBlockPreset_tiny_creep_martian: //return @"tiny-creep-martian-0";
        case EBlockPreset_tiny_creep_mosquito: //return @"tiny-creep-mosquito-0";
            return nil; // TODO: actors
            
        case EBlockPreset_tiny_redblu_red: return @"tiny-redblu-red-off";  // pretends initial blu-is-on state
        case EBlockPreset_tiny_redblu_blu: return @"tiny-redblu-blu-on";
        case EBlockPreset_tiny_bl_ice: return @"tiny-bl-ice";
        case EBlockPreset_tiny_aiBounceHint: return nil;
        case EBlockPreset_tiny_mineCrate: return @"tiny-creep-mine";
  
        default:
            return nil;
    }
}


+(NSString *)getSpriteResourceNameForPreset:(EBlockPreset)preset fourWayAVCode:(UInt32)fourWayAVCode
{
    if( preset == EBlockPreset_PlayerStart || preset == EBlockPreset_tiny_playerStart || preset == EBlockPreset_None )
    {
        NSAssert( NO, @"Didn't expect this." );
    }

    NSString *result = nil;
    result = [WorldArchiveUtil getSpriteResourceName_batch1Style_forPreset:preset fourWayAVCode:fourWayAVCode];
    if( result == nil )
    {
        result = [WorldArchiveUtil getSpriteResourceName_batch2Style_forPreset:preset fourWayAVCode:fourWayAVCode];
    }
    return result;
}


+(SpriteStateMap *)getSpriteStateMapForPresetBlock:(AFPresetBlockBase *)presetBlock
{
    SpriteStateMap *resultMap = [[[SpriteStateMap alloc] initWithSize:presetBlock.autoVariationMap.size] autorelease];
    for( int y = 0; y < presetBlock.autoVariationMap.size.height; ++y )
    {
        for( int x = 0; x < presetBlock.autoVariationMap.size.width; ++x )
        {
            UInt32 thisHint = [presetBlock.autoVariationMap getHintAtX:x y:y];
            float animDur = [WorldArchiveUtil getAnimDurForPreset:presetBlock.preset];
            NSString *resourceName = [WorldArchiveUtil getSpriteResourceNameForPreset:presetBlock.preset fourWayAVCode:thisHint];
            SpriteState *spriteState;
            if( animDur > 0.f )
            {
                spriteState = [[[AnimSpriteState alloc] initWithAnimName:resourceName animDur:animDur] autorelease];
            }
            else
            {
                spriteState = [[[StaticSpriteState alloc] initWithSpriteName:resourceName] autorelease];
            }
            [resultMap setSpriteStateAtX:x y:y to:spriteState];
        }
    }
    return resultMap;
}


+(void)setGroupAndPropsForBlock:(Block *)block fromAFBlock:(AFBlock *)afBlock
{
    // usually none. may be overwritten by presets.
    block.groupId = afBlock.groupId;
    
    // note: ignoring archived token property and just sticking with the one we
    //       got from blockProps ctor. this is guaranteed to be unique with other
    //       blocks that may get spawned. this means we won't be able to assume
    //       tokens are consistent between view and edit, may need to change.
    // TODO: come to think of it, this will probably break event scenarios where
    //       we need to be able to specify an event target in edit.
    if( [afBlock isMemberOfClass:[AFPresetBlockBase class]] )
    {
        AFPresetBlockBase *afPresetBlock = (AFPresetBlockBase *)afBlock;
        [WorldArchiveUtil setPropsForBlock:block fromPreset:afPresetBlock.preset];
    }
    else
    {
        block.props.canMoveFreely = afBlock.props.canMoveFreely;
        block.props.affectedByGravity = afBlock.props.affectedByGravity;
        block.props.affectedByFriction = afBlock.props.affectedByFriction;
        block.props.bounceDampFactor = afBlock.props.bounceDampFactor;    
        block.props.initialVelocity = EmuPointFromFlPoint( afBlock.props.initialVelocity );
    }
}


+(EmuPoint)getBlockDimsForPresetBlock:(AFPresetBlockBase *)presetBlock
{
    float wBl = presetBlock.rect.size.width;
    float hBl = presetBlock.rect.size.height;
    
    // read the value as grid units, then convert to worldEmu units on return.
    return EmuPointMake( GRID_SIZE_Emu * wBl, GRID_SIZE_Emu * hBl );
}


+(BOOL)isActor:(EBlockPreset)preset
{
    switch( preset )
    {
        // batch 1
        case EBlockPreset_TestMeanieB:
        case EBlockPreset_FaceBone:
        case EBlockPreset_Crumbles1:
            return YES;

        case EBlockPreset_PlayerStart:
            // player start is handled specially.
            return NO;
            
        // batch 2
        case EBlockPreset_tiny_crum:
        case EBlockPreset_tiny_autolift:
        case EBlockPreset_tiny_btn1:
        case EBlockPreset_tiny_creep_fuzz_l:
        case EBlockPreset_tiny_creep_fuzz_r:
        //case EBlockPreset_tiny_creep_martian:
        //case EBlockPreset_tiny_creep_mosquito:
        case EBlockPreset_tiny_creep_jelly_LR:
        case EBlockPreset_tiny_creep_jelly_UD:
            return YES;

        case EBlockPreset_tiny_playerStart:
            return NO;

        default:
            return NO;
    }
}


+(Actor *)createActorForPresetBlock:(AFPresetBlockBase *)block
{
    EmuPoint pStart = EmuPointMake( block.rect.origin.x * ONE_BLOCK_SIZE_Emu,
                                    block.rect.origin.y * ONE_BLOCK_SIZE_Emu );
    
    // afblock y-goes-down, world y-goes-up, so adjust yStart by height of actor
    // TODO: this assumes an actor is 4*block high. Should grab this value from the
    //       actor instead.
    pStart.y -= (4 * ONE_BLOCK_SIZE_Emu);

    EmuPoint blockSizeInUnits = EmuPointMake( block.rect.size.width, block.rect.size.height );

    switch( block.preset )
    {
        case EBlockPreset_TestMeanieB:            
            return [[[TestMeanieBActor alloc] initAtStartingPoint:pStart] autorelease];
        
        case EBlockPreset_FaceBone:
            return [[[FaceboneActor alloc] initAtStartingPoint:pStart] autorelease];
            
        case EBlockPreset_Crumbles1:
            return [[[Crumbles1Actor alloc] initAtStartingPoint:pStart] autorelease];
            
        case EBlockPreset_tiny_creep_fuzz_l:
            return [[[TinyFuzzActor alloc] initAtStartingPoint:pStart goingLeft:YES] autorelease];
        case EBlockPreset_tiny_creep_fuzz_r:
            return [[[TinyFuzzActor alloc] initAtStartingPoint:pStart goingLeft:NO] autorelease];
            
        case EBlockPreset_tiny_crum:
            return [[[TinyCrumActor alloc] initAtStartingPoint:pStart] autorelease];
            
        case EBlockPreset_tiny_autolift:
            return [[[TinyAutoLiftActor alloc] initAtStartingPoint:pStart withSizeInUnits:blockSizeInUnits] autorelease];
            
        case EBlockPreset_tiny_creep_jelly_LR:
            return [[[TinyJellyActor alloc] initAtStartingPoint:pStart onXAxis:YES] autorelease];
        case EBlockPreset_tiny_creep_jelly_UD:
            return [[[TinyJellyActor alloc] initAtStartingPoint:pStart onXAxis:NO] autorelease];
            
        case EBlockPreset_tiny_btn1:
            return [[[TinyBtn1Actor alloc] initAtStartingPoint:pStart] autorelease];
            
        default:
            NSLog( @"don't know how to create actor for preset." );
            return nil;
    }
}


// shifts the level back close to origin.
+(void)normalize:(AFLevel *)level
{
    float xMinValue, yMinValue;
    
    xMinValue = FLT_MAX;
    yMinValue = FLT_MAX;
    for( int i = 0; i < [level.blockList count]; ++i )
    {
        AFBlock *thisBlock = (AFBlock *)[level.blockList objectAtIndex:i];
        
        xMinValue = fminf( xMinValue, thisBlock.rect.origin.x );
        yMinValue = fminf( yMinValue, thisBlock.rect.origin.y );
    }
    
    for( int i = 0; i < [level.blockList count]; ++i )
    {
        AFBlock *thisBlock = (AFBlock *)[level.blockList objectAtIndex:i];
        thisBlock.rect = CGRectMake( thisBlock.rect.origin.x - xMinValue,
                                    thisBlock.rect.origin.y - yMinValue,
                                    thisBlock.rect.size.width,
                                    thisBlock.rect.size.height );
    }
    NSLog( @"readWorld: normalize offset was %f x %f", xMinValue, yMinValue );
}


+(void)readWorld:(World *)world fromAF:(AFLevel *)level
{
    // assume [world reset] was called already.
    
    EmuPoint playerStart = EmuPointMake( 0, 0 );
    EBlockPreset playerStartPreset;
    
    for( int i = 0; i < [level.blockList count]; ++i )
    {
        AFBlock *thisAFBlock = (AFBlock *)[level.blockList objectAtIndex:i];
        Block *thisBlock = nil;
        AFPresetBlockBase *thisActorPresetBlock = nil;
        
        if( [thisAFBlock isMemberOfClass:[AFSpriteBlock class]] )
        {
            NSAssert( NO, @"support for very old serialized-from-play-mode blocks has been removed." );
        }
        else if( [thisAFBlock isMemberOfClass:[AFPresetBlockBase class]] )
        {
            AFPresetBlockBase *thisAFPresetBlockBase = (AFPresetBlockBase *)thisAFBlock;
            
            if( [WorldArchiveUtil isActor:thisAFPresetBlockBase.preset] )
            {
                // set up an actor instead of a block
                thisBlock = nil;
                thisActorPresetBlock = thisAFPresetBlockBase;
            }
            else
            {
                // set up a block directly
                
                EmuPoint blockDims = [WorldArchiveUtil getBlockDimsForPresetBlock:thisAFPresetBlockBase];
                int x = thisAFPresetBlockBase.rect.origin.x * ONE_BLOCK_SIZE_Emu;
                int y = thisAFPresetBlockBase.rect.origin.y * ONE_BLOCK_SIZE_Emu - blockDims.y;  // late night y-flipped-ness correction.
                EmuRect thisRectEmu = EmuRectMake( x, y, blockDims.x, blockDims.y );
                
                if( thisAFPresetBlockBase.preset == EBlockPreset_PlayerStart || thisAFPresetBlockBase.preset == EBlockPreset_tiny_playerStart )
                {
                    playerStart = EmuPointMake( thisRectEmu.origin.x, thisRectEmu.origin.y );
                    playerStartPreset = thisAFPresetBlockBase.preset;
                    continue;
                }
                SpriteStateMap *spriteStateMap = [WorldArchiveUtil getSpriteStateMapForPresetBlock:thisAFPresetBlockBase];
                thisBlock = [[[SpriteBlock alloc] initWithRect:thisRectEmu spriteStateMap:spriteStateMap] autorelease];
            }
        }
        else
        {
            NSLog( @"readWorldFromAF: unrecognized block type in AFBlockList." );
            continue;
        }

        // TODO: WorldArchiveUtil has too much smarts. It shouldn't know how to create World blocks and actors for every preset.
        //       This should probably be a separate helper. Sort of academic for now.
        
        if( thisBlock != nil )
        {
            [WorldArchiveUtil setGroupAndPropsForBlock:thisBlock fromAFBlock:thisAFBlock];
            
            if( thisBlock.groupId == GROUPID_NONE )
            {
                [world addWorldBlock:thisBlock];
            }
            else
            {
                BlockGroup *thisGroup = [world ensureGroupForId:thisBlock.groupId];
                [world addBlock:thisBlock toGroup:thisGroup];
            }
        }
        
        if( thisActorPresetBlock != nil )
        {
            Actor *thisActor = [WorldArchiveUtil createActorForPresetBlock:thisActorPresetBlock];
            if( thisActor != nil )
            {
                [world addNPCActor:thisActor];
            }
        }
    }
    
    world.levelName = level.props.name;
    world.levelDescription = level.props.description;
    
    [world initPlayerAt:playerStart fromPreset:playerStartPreset];
    
    [world setupElbowRoom];
}


+(AFBlock *)getAFBlockForBlock:(Block *)thisBlock
{
    AFBlock *thisAFBlock;
    AFBlockProps *thisAFBlockProps = [WorldArchiveUtil readAFBlockPropsFromBlockProps:thisBlock.props];
    EmuRect thisRect = EmuRectMake( thisBlock.x, thisBlock.y, thisBlock.w, thisBlock.h );
    GroupId thisGroupId = thisBlock.groupId;
    
    // TODO: this should call a method on the block, so we don't have to do RTTI
    if( [thisBlock isMemberOfClass:[SpriteBlock class]] )
    {
        SpriteBlock *thisSpriteBlock = (SpriteBlock *)thisBlock;
        float animDur;
        if( [thisSpriteBlock.defaultSpriteState isMemberOfClass:[AnimSpriteState class]] )
        {
            AnimSpriteState *animSpriteState = (AnimSpriteState *)thisSpriteBlock.defaultSpriteState;
            animDur = animSpriteState.animDur;
        }
        else if( [thisSpriteBlock.defaultSpriteState isMemberOfClass:[StaticSpriteState class]] )
        {
            animDur = 0.f;  // not animating
        }
        else
        {
            NSLog( @"writeAFFromWorld: unrecognized spriteState type on SpriteBlock." );
            return nil;                
        }
        thisAFBlock = [[[AFSpriteBlock alloc] initWithProps:thisAFBlockProps rect:FlRectFromEmuRect(thisRect) groupId:thisGroupId resourceName:thisSpriteBlock.defaultSpriteState.resourceName animDur:animDur] autorelease];
    }
    else
    {
        NSLog( @"writeAFFromWorld: unrecognized block type in worldBlock list." );
        return nil;
    }
    return thisAFBlock;
}


+(AFLevel *)writeAFFromWorld:(World *)world
{
    NSMutableArray *afBlockList = [NSMutableArray arrayWithCapacity:[world worldSOCount]];
    for( int i = 0; i < [world worldSOCount]; ++i )
    {
        ASolidObject *thisSO = [world getWorldSO:i];
        if( [thisSO isGroup] )
        {
            BlockGroup *thisGroup = (BlockGroup *)thisSO;
            for( int j = 0; j < [thisGroup.blocks count]; ++j )
            {
                Block *thisBlock = (Block *)[thisGroup.blocks objectAtIndex:j];
                AFBlock *thisAFBlock = [WorldArchiveUtil getAFBlockForBlock:thisBlock];
                if( thisAFBlock != nil )
                {
                    [afBlockList addObject:thisAFBlock];
                }
            }
        }
        else
        {
            Block *thisBlock = (Block *)thisSO;
            AFBlock *thisAFBlock = [WorldArchiveUtil getAFBlockForBlock:thisBlock];
            if( thisAFBlock != nil )
            {
                [afBlockList addObject:thisAFBlock];
            }
        }
    }
    
    AFLevelProps *levelProps = [[[AFLevelProps alloc] init] autorelease];
    levelProps.name = world.levelName != nil ? world.levelName : @"Unnamed level";
    levelProps.description = world.levelDescription != nil ? world.levelDescription : @"No description.";
    
    return [[[AFLevel alloc] initWithProps:levelProps blockList:afBlockList] autorelease];
}


//#define LOG_BLOCK_DISK_ACTIVITY

+(void)loadWorld:(World *)world fromDiskForName:(NSString *)levelName
{
    NSString *path = [[LevelFileUtil instance] getPathForLevelName:levelName];
    NSLog( @"loading world from disk path: %@", path );
    NSDictionary *rootObject;
    
    // TODO: error handling
    rootObject = [NSKeyedUnarchiver unarchiveObjectWithFile:path];
    AFLevel *afLevel = (AFLevel *)[rootObject valueForKey:@"afLevel"];
    
#ifdef LOG_BLOCK_DISK_ACTIVITY    
    NSLog( @"WorldArchiveUtil loadWorld: reading %d blocks:", [afLevel.blockList count] );
    for( int i = 0; i < [afLevel.blockList count]; ++i )
    {
        AFBlock *thisAFBlock = (AFBlock *)[afLevel.blockList objectAtIndex:i];
        NSLog( @"  reading a block at %fx%f", thisAFBlock.rect.origin.x, thisAFBlock.rect.origin.y );
    }
#endif
    
    [WorldArchiveUtil normalize:afLevel];
    [WorldArchiveUtil readWorld:world fromAF:afLevel];
    
#ifdef LOG_BLOCK_DISK_ACTIVITY
    NSLog( @"WorldArchiveUtil loadWorld: finished reading AFLevel." );
    for( int i = 0; i < [world worldSOCount]; ++i )
    {
        Block *thisBlock = (Block *)[world getWorldSO:i];
        NSLog( @"  created a Block at %dx%d of type %@ ", thisBlock.x, thisBlock.y, [[thisBlock class] description] );
    }
#endif
}


// this method isn't typically used. It's only needed to get hardcoded levels onto disk.
+(void)saveToDisk:(World *)world
{
    if( world.levelName == nil )
    {
        NSLog( @"WorldArchiveUtil saveToDisk error: tried to save an unnamed level, aborted." );
        return;
    }
    
    NSString *path = [[LevelFileUtil instance] getPathForLevelName:world.levelName];
    
    // check for existing file.
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if( [fileManager fileExistsAtPath:path] )
    {
        if( [fileManager removeItemAtPath:path error:NULL] )
        {
            NSLog( @"WorldArchiveUtil saveToDisk: an item with path %@ already existed, so I deleted it first.", path );
        }
        else
        {
            NSLog( @"WorldArchiveUtil saveToDisk: I wanted to remove an existing item at path %@, but failed!", path );
        }
    }
    
    AFLevel *afLevel = [WorldArchiveUtil writeAFFromWorld:world];
    
    NSMutableDictionary * rootObject;
    rootObject = [NSMutableDictionary dictionary];    
    [rootObject setValue:afLevel forKey:@"afLevel"];
    [NSKeyedArchiver archiveRootObject:rootObject toFile:path];
}


@end
