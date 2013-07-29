//
//  EBlockPaletteViewController.m
//  JumpProto
//
//  Created by gideong on 10/10/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "EBlockPaletteViewController.h"
#import "SpriteManager.h"
#import "EBlockPresetSpriteNames.h"

/////////////////////////////////////////////////////////////////////////////////////////////////////////// EBPPresetEntry
@implementation EBPPresetEntry

@synthesize preset = m_preset, presetName = m_presetName, presetDescription = m_presetDescription;

-(id)initWithPreset:(EBlockPreset)preset name:(NSString *)name description:(NSString *)description
{
    if( self = [super init] )
    {
        m_preset = preset;
        m_presetName = [name retain];
        m_presetDescription = [description retain];
        
    }
    return self;
}


-(void)dealloc
{
    [m_presetName release]; m_presetName = nil;
    [m_presetDescription release]; m_presetDescription = nil;
    [super dealloc];
}

@end


/////////////////////////////////////////////////////////////////////////////////////////////////////////// EBPPresetCategory
@implementation EBPPresetCategory

@synthesize name = m_name;

-(id)initWithName:(NSString *)name
{
    if( self = [super init] )
    {
        m_name = [name retain];
        m_presetList = [[NSMutableArray arrayWithCapacity:20] retain];
    }
    return self;    
}


-(void)dealloc
{
    [m_name release]; m_name = nil;
    [m_presetList release]; m_presetList = nil;
    [super dealloc];
}


-(NSArray *)getPresetList
{
    return m_presetList;
}


-(void)addPresetEntry:(EBPPresetEntry *)entry
{
    [m_presetList addObject:entry];
}


@end


/////////////////////////////////////////////////////////////////////////////////////////////////////////// EBlockPaletteViewController

@interface EBlockPaletteViewController (private)

-(void)initPresetCategoryList;

@end


@implementation EBlockPaletteViewController

@synthesize paletteTableView;


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        [self initPresetCategoryList];
        // Custom initialization
    }
    return self;
}

- (void)dealloc
{
    m_blockPresetStateHolder = nil;  // weak
    self.paletteTableView = nil;
    [m_presetCategoryList release]; m_presetCategoryList = nil;
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}


-(NSArray *)getPresetCategoryList_batch1
{
    NSMutableArray *list = [NSMutableArray arrayWithCapacity:10];
    
    EBPPresetCategory *category;
    NSString *entryName;
    NSString *entryDescription;
    EBlockPreset entryPreset;
    
    category = [[[EBPPresetCategory alloc] initWithName:@"Ground"] autorelease];
    entryPreset =      EBlockPreset_Test0;
    entryName =        @"GrTest0";
    entryDescription = @"Basic test block 0.";
    [category addPresetEntry:[[[EBPPresetEntry alloc] initWithPreset:entryPreset name:entryName description:entryDescription] autorelease]];
    entryPreset =      EBlockPreset_GroundBrickAVTest;
    entryName =        @"GrBrickAV0";
    entryDescription = @"test autovariation code 2.";
    [category addPresetEntry:[[[EBPPresetEntry alloc] initWithPreset:entryPreset name:entryName description:entryDescription] autorelease]];
    entryPreset =      EBlockPreset_GroundColumn;
    entryName =        @"GrColumn0";
    entryDescription = @"column.";
    [category addPresetEntry:[[[EBPPresetEntry alloc] initWithPreset:entryPreset name:entryName description:entryDescription] autorelease]];
    entryPreset =      EBlockPreset_BLTurf;
    entryName =        @"GrTurf";
    entryDescription = @"turf.";
    [category addPresetEntry:[[[EBPPresetEntry alloc] initWithPreset:entryPreset name:entryName description:entryDescription] autorelease]];
    entryPreset =      EBlockPreset_GroundRusty;
    entryName =        @"GrRusty";
    entryDescription = @"rusty metal.";
    [category addPresetEntry:[[[EBPPresetEntry alloc] initWithPreset:entryPreset name:entryName description:entryDescription] autorelease]];
    entryPreset =      EBlockPreset_GroundWood;
    entryName =        @"GrWood";
    entryDescription = @"wood block.";
    [category addPresetEntry:[[[EBPPresetEntry alloc] initWithPreset:entryPreset name:entryName description:entryDescription] autorelease]];
    entryPreset =      EBlockPreset_GroundQuilt;
    entryName =        @"GrQuilt";
    entryDescription = @"my eyes!";
    [category addPresetEntry:[[[EBPPresetEntry alloc] initWithPreset:entryPreset name:entryName description:entryDescription] autorelease]];
    entryPreset =      EBlockPreset_Algae;
    entryName =        @"GrAlgae";
    entryDescription = @"looks cooler than it is.";
    [category addPresetEntry:[[[EBPPresetEntry alloc] initWithPreset:entryPreset name:entryName description:entryDescription] autorelease]];
    entryPreset =      EBlockPreset_Qik;
    entryName =        @"GrQik";
    entryDescription = @"I'm not even trying now.";
    [category addPresetEntry:[[[EBPPresetEntry alloc] initWithPreset:entryPreset name:entryName description:entryDescription] autorelease]];
    entryPreset =      EBlockPreset_RedBrick;
    entryName =        @"GrRedBrk";
    entryDescription = @"test non-unit sizes.";
    [category addPresetEntry:[[[EBPPresetEntry alloc] initWithPreset:entryPreset name:entryName description:entryDescription] autorelease]];
    entryPreset =      EBlockPreset_Lavender;
    entryName =        @"GrLavender";
    entryDescription = @"test pony colors.";
    [category addPresetEntry:[[[EBPPresetEntry alloc] initWithPreset:entryPreset name:entryName description:entryDescription] autorelease]];
    
    [list addObject:category];
    
    category = [[[EBPPresetCategory alloc] initWithName:@"GroundSp"] autorelease];
    entryPreset =      EBlockPreset_OneWayU;
    entryName =        @"OneWayUp";
    entryDescription = @"one way up";
    [category addPresetEntry:[[[EBPPresetEntry alloc] initWithPreset:entryPreset name:entryName description:entryDescription] autorelease]];
    entryPreset =      EBlockPreset_OneWayL;
    entryName =        @"OneWayLeft";
    entryDescription = @"one way left";
    [category addPresetEntry:[[[EBPPresetEntry alloc] initWithPreset:entryPreset name:entryName description:entryDescription] autorelease]];
    entryPreset =      EBlockPreset_OneWayR;
    entryName =        @"OneWayRight";
    entryDescription = @"one way right";
    [category addPresetEntry:[[[EBPPresetEntry alloc] initWithPreset:entryPreset name:entryName description:entryDescription] autorelease]];
    entryPreset =      EBlockPreset_OneWayD;
    entryName =        @"OneWayDown";
    entryDescription = @"one way down";
    [category addPresetEntry:[[[EBPPresetEntry alloc] initWithPreset:entryPreset name:entryName description:entryDescription] autorelease]];
    entryPreset =      EBlockPreset_ConveyorL;
    entryName =        @"ConveyorL";
    entryDescription = @"conveyor belt left";
    [category addPresetEntry:[[[EBPPresetEntry alloc] initWithPreset:entryPreset name:entryName description:entryDescription] autorelease]];
    entryPreset =      EBlockPreset_ConveyorR;
    entryName =        @"ConveyorR";
    entryDescription = @"conveyor belt right";
    [category addPresetEntry:[[[EBPPresetEntry alloc] initWithPreset:entryPreset name:entryName description:entryDescription] autorelease]];
    
    [list addObject:category];

    category = [[[EBPPresetCategory alloc] initWithName:@"Props"] autorelease];
    entryPreset =      EBlockPreset_TestCrate;
    entryName =        @"Crate";
    entryDescription = @"basic test crate.";
    [category addPresetEntry:[[[EBPPresetEntry alloc] initWithPreset:entryPreset name:entryName description:entryDescription] autorelease]];
    entryPreset =      EBlockPreset_PropFancyCrate;
    entryName =        @"FCrate";
    entryDescription = @"fancy test crate.";
    [category addPresetEntry:[[[EBPPresetEntry alloc] initWithPreset:entryPreset name:entryName description:entryDescription] autorelease]];
    entryPreset =      EBlockPreset_WoodCrate;
    entryName =        @"WCrate";
    entryDescription = @"wood-ish test crate.";
    [category addPresetEntry:[[[EBPPresetEntry alloc] initWithPreset:entryPreset name:entryName description:entryDescription] autorelease]];
    
    entryPreset =      EBlockPreset_MovingPlatformRightMedium;
    entryName =        @"MovingPlatformRM";
    entryDescription = @"Moving platform, right, medium speed.";
    [category addPresetEntry:[[[EBPPresetEntry alloc] initWithPreset:entryPreset name:entryName description:entryDescription] autorelease]];
    entryPreset =      EBlockPreset_PropSpring;
    entryName =        @"SpringTest";
    entryDescription = @"crummy test spring bouncer thingie.";
    [category addPresetEntry:[[[EBPPresetEntry alloc] initWithPreset:entryPreset name:entryName description:entryDescription] autorelease]];
    entryPreset =      EBlockPreset_Crumbles1;
    entryName =        @"Crumbles1";
    entryDescription = @"a block that crumbles away, then reappears after a while.";  // too long problem?
    [category addPresetEntry:[[[EBPPresetEntry alloc] initWithPreset:entryPreset name:entryName description:entryDescription] autorelease]];

    [list addObject:category];

    category = [[[EBPPresetCategory alloc] initWithName:@"Hurty"] autorelease];
    entryPreset =      EBlockPreset_PropSpikes;
    entryName =        @"Spikes";
    entryDescription = @"They kill you if you land on top.";
    [category addPresetEntry:[[[EBPPresetEntry alloc] initWithPreset:entryPreset name:entryName description:entryDescription] autorelease]];
    entryPreset =      EBlockPreset_PropSkull;
    entryName =        @"Skull";
    entryDescription = @"Land mine, do not touch.";
    [category addPresetEntry:[[[EBPPresetEntry alloc] initWithPreset:entryPreset name:entryName description:entryDescription] autorelease]];
    entryPreset =      EBlockPreset_TestMeanieB;
    entryName =        @"MeanieB";
    entryDescription = @"the first moving enemy.";
    [category addPresetEntry:[[[EBPPresetEntry alloc] initWithPreset:entryPreset name:entryName description:entryDescription] autorelease]];
    entryPreset =      EBlockPreset_MineFloat;
    entryName =        @"MineFloat";
    entryDescription = @"airborne mine.";
    [category addPresetEntry:[[[EBPPresetEntry alloc] initWithPreset:entryPreset name:entryName description:entryDescription] autorelease]];
    entryPreset =      EBlockPreset_MineCrate;
    entryName =        @"MineCrate";
    entryDescription = @"mine that is moveable like a crate.";
    [category addPresetEntry:[[[EBPPresetEntry alloc] initWithPreset:entryPreset name:entryName description:entryDescription] autorelease]];
    entryPreset =      EBlockPreset_FaceBone;
    entryName =        @"Facebone";
    entryDescription = @"jumping bad guy.";
    [category addPresetEntry:[[[EBPPresetEntry alloc] initWithPreset:entryPreset name:entryName description:entryDescription] autorelease]];
    
    [list addObject:category];
    
    category = [[[EBPPresetCategory alloc] initWithName:@"Special"] autorelease];
    entryPreset =      EBlockPreset_PlayerStart;
    entryName =        @"PlayerStart";
    entryDescription = @"Player's starting position.";
    [category addPresetEntry:[[[EBPPresetEntry alloc] initWithPreset:entryPreset name:entryName description:entryDescription] autorelease]];
    entryPreset =      EBlockPreset_PropGoal;
    entryName =        @"Goal";
    entryDescription = @"Exit goal.";
    [category addPresetEntry:[[[EBPPresetEntry alloc] initWithPreset:entryPreset name:entryName description:entryDescription] autorelease]];

    [list addObject:category];
    
    category = [[[EBPPresetCategory alloc] initWithName:@"Silly"] autorelease];
    entryPreset =      EBlockPreset_SillyEm0;
    entryName =        @"sillyEm0";
    entryDescription = @"a pic of Emily";
    [category addPresetEntry:[[[EBPPresetEntry alloc] initWithPreset:entryPreset name:entryName description:entryDescription] autorelease]];
    entryPreset =      EBlockPreset_SillyMax0;
    entryName =        @"sillyMax0";
    entryDescription = @"a pic of Max";
    [category addPresetEntry:[[[EBPPresetEntry alloc] initWithPreset:entryPreset name:entryName description:entryDescription] autorelease]];
    
    [list addObject:category];
    
    return list;
}

#define PCL_CAT( __CAT_NAME ) category = [[[EBPPresetCategory alloc] initWithName:__CAT_NAME] autorelease]
#define PCL_ADD( __ENUM, __NAME, __DESC) [category addPresetEntry:[[[EBPPresetEntry alloc] initWithPreset:(__ENUM) name:(__NAME) description:(__DESC)] autorelease]]
#define PCL_CATDONE() [list addObject:category]

-(NSArray *)getPresetCategoryList_batch2
{
    NSMutableArray *list = [NSMutableArray arrayWithCapacity:10];
    EBPPresetCategory *category;

    PCL_CAT( @"start/end" );
    PCL_ADD( EBlockPreset_tiny_playerStart, @"pl-start", @"" );
    PCL_ADD( EBlockPreset_tiny_bl_exit, @"pl-end", @"" );
    PCL_CATDONE();

    PCL_CAT( @"solid" );
    PCL_ADD( EBlockPreset_tiny_bl_0, @"bl-0", @"" );
    PCL_ADD( EBlockPreset_tiny_bl_1, @"bl-1", @"" );
    PCL_ADD( EBlockPreset_tiny_bl_2, @"bl-2", @"" );
    PCL_ADD( EBlockPreset_tiny_bl_3, @"bl-3", @"" );
    PCL_ADD( EBlockPreset_tiny_bl_4, @"bl-4", @"" );
    PCL_ADD( EBlockPreset_tiny_bl_5, @"bl-5", @"" );
    PCL_ADD( EBlockPreset_tiny_bl_6, @"bl-6", @"" );
    PCL_ADD( EBlockPreset_tiny_bl_7, @"bl-7", @"" );
    PCL_ADD( EBlockPreset_tiny_bl_8, @"bl-8", @"" );
    PCL_ADD( EBlockPreset_tiny_bl_9, @"bl-9", @"" );
    PCL_ADD( EBlockPreset_tiny_col, @"col", @"" );
    PCL_ADD( EBlockPreset_tiny_bl_stretch, @"bl-stretch", @"" );
    PCL_ADD( EBlockPreset_tiny_bl_turf1, @"bl-turf1", @"" );
    PCL_ADD( EBlockPreset_tiny_bl_turf2, @"bl-turf2", @"" );
    PCL_CATDONE();
    
    PCL_CAT( @"crates" );
    PCL_ADD( EBlockPreset_tiny_cr_1, @"crate1", @"" );
    PCL_ADD( EBlockPreset_tiny_cr_2, @"crate2", @"" );
    PCL_ADD( EBlockPreset_tiny_bigcr, @"bigcrate", @"" );
    PCL_CATDONE();
    
    PCL_CAT( @"flow" );
    PCL_ADD( EBlockPreset_tiny_conveyor_l, @"conveyor-left", @"" );
    PCL_ADD( EBlockPreset_tiny_conveyor_r, @"conveyor-right", @"" );
    PCL_ADD( EBlockPreset_tiny_oneway_u, @"oneway-up", @"" );
    PCL_ADD( EBlockPreset_tiny_oneway_l, @"oneway-left", @"" );
    PCL_ADD( EBlockPreset_tiny_oneway_r, @"oneway-right", @"" );
    PCL_ADD( EBlockPreset_tiny_oneway_d, @"oneway-down", @"" );
    PCL_ADD( EBlockPreset_tiny_crum, @"crumble", @"" );
    PCL_ADD( EBlockPreset_tiny_bl_wallJump, @"walljump", @"" );
    PCL_ADD( EBlockPreset_tiny_lift, @"lift", @"" );
    PCL_ADD( EBlockPreset_tiny_mv_plat_l, @"mvplat-left", @"" );
    PCL_ADD( EBlockPreset_tiny_mv_plat_r, @"mvplat-right", @"" );
    PCL_ADD( EBlockPreset_tiny_bl_ice, @"ice", @"" );
    PCL_ADD( EBlockPreset_tiny_aiBounceHint, @"ai-bounce", @"" );
    PCL_CATDONE();
    
    PCL_CAT( @"creeps/ouch" );
    PCL_ADD( EBlockPreset_tiny_spikes_u, @"spikes-up", @"" );
    PCL_ADD( EBlockPreset_tiny_spikes_l, @"spikes-left", @"" );
    PCL_ADD( EBlockPreset_tiny_spikes_r, @"spikes-right", @"" );
    PCL_ADD( EBlockPreset_tiny_spikes_d, @"spikes-down", @"" );
    PCL_ADD( EBlockPreset_tiny_creep_fuzz_l, @"fuzz-left", @"" );
    PCL_ADD( EBlockPreset_tiny_creep_fuzz_r, @"fuzz-right", @"" );
    PCL_ADD( EBlockPreset_tiny_creep_martian, @"martian", @"" );
    PCL_ADD( EBlockPreset_tiny_creep_mosquito, @"mosquito", @"" );
    PCL_ADD( EBlockPreset_tiny_creep_jelly, @"jelly", @"" );
    
    // leave these out for now, useless without beam logic which is a long way off.
    //PCL_ADD( EBlockPreset_tiny_hbeam_emitter_l, @"hbeam-left", @"" );
    //PCL_ADD( EBlockPreset_tiny_hbeam_emitter_r, @"hbeam-right", @"" );
    PCL_CATDONE();

    PCL_CAT( @"tiny-er" );
    PCL_ADD( EBlockPreset_tiny_sprtiny_0, @"supertiny-0", @"" );
    PCL_ADD( EBlockPreset_tiny_sprtiny_1, @"supertiny-1", @"" );
    PCL_ADD( EBlockPreset_tiny_sprtiny_2, @"supertiny-2", @"" );
    PCL_ADD( EBlockPreset_tiny_sprtiny_3, @"supertiny-3", @"" );
    PCL_ADD( EBlockPreset_tiny_pipe, @"supertiny-pipe", @"" );
    PCL_ADD( EBlockPreset_tiny_pipe_bub, @"supertiny-bub", @"" );
    PCL_CATDONE();
    
    PCL_CAT( @"event-y" );
    PCL_ADD( EBlockPreset_tiny_btn1, @"btn1", @"" );
    PCL_ADD( EBlockPreset_tiny_redblu_red, @"redblu-red", @"" );
    PCL_ADD( EBlockPreset_tiny_redblu_blu, @"redblu-blu", @"" );
    PCL_CATDONE();
    
    return list;
}


-(void)initPresetCategoryList
{
    //m_presetCategoryList = [[self getPresetCategoryList_batch1] retain];
    m_presetCategoryList = [[self getPresetCategoryList_batch2] retain];
}


-(EBlockPreset)getDefaultPreset
{
    NSAssert( [m_presetCategoryList count] > 0, @"Assume categories already got populated." );
    EBPPresetCategory *defaultCategory = (EBPPresetCategory *)[m_presetCategoryList objectAtIndex:0];
    EBPPresetEntry *defaultEntry = (EBPPresetEntry *)[defaultCategory.presetList objectAtIndex:0];
    return defaultEntry.preset;
}


#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return UIInterfaceOrientationIsLandscape( interfaceOrientation );
}


#pragma mark UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [m_presetCategoryList count];
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    EBPPresetCategory *presetCategory = (EBPPresetCategory *)[m_presetCategoryList objectAtIndex:section];
    return [presetCategory.presetList count];
}


- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    EBPPresetCategory *presetCategory = (EBPPresetCategory *)[m_presetCategoryList objectAtIndex:section];
    return presetCategory.name;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	static NSString *CellIdentifier = @"PresetNameCellIdentifier";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
        cell.selectionStyle = UITableViewCellSelectionStyleBlue;
    }
    
    EBPPresetCategory *presetCategory = (EBPPresetCategory *)[m_presetCategoryList objectAtIndex:indexPath.section];
    EBPPresetEntry *presetEntry = (EBPPresetEntry *)[presetCategory.presetList objectAtIndex:indexPath.row];
    cell.textLabel.text = presetEntry.presetName;
    
    NSString *thisPresetSpriteName = [EBlockPresetSpriteNames getSpriteNameForPreset:presetEntry.preset];
    cell.imageView.image = [[SpriteManager instance] getImageForSpriteName:thisPresetSpriteName];

    return cell;
}


#pragma mark UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    EBPPresetCategory *presetCategory = (EBPPresetCategory *)[m_presetCategoryList objectAtIndex:indexPath.section];
    EBPPresetEntry *presetEntry = (EBPPresetEntry *)[presetCategory.presetList objectAtIndex:indexPath.row];
    [m_blockPresetStateHolder currentBlockPresetUpdated:presetEntry.preset];
}


-(void)setPresetStateHolder:(id<ICurrentBlockPresetStateHolder>)holder
{
    m_blockPresetStateHolder = holder;  // weak;
}


-(void)selectPreset:(EBlockPreset)preset
{
    for( int iSection = 0; iSection < [m_presetCategoryList count]; ++iSection )
    {
        EBPPresetCategory *thisCat = (EBPPresetCategory *)[m_presetCategoryList objectAtIndex:iSection];
        for( int iRow = 0; iRow < [thisCat.presetList count]; ++iRow )
        {
            EBPPresetEntry *thisEntry = (EBPPresetEntry *)[thisCat.presetList objectAtIndex:iRow];
            if( thisEntry.preset == preset )
            {
                NSIndexPath *indexPath = [NSIndexPath indexPathForRow:iRow inSection:iSection];
                [self.paletteTableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionMiddle];
                return;
            }
        }
    }
    NSLog( @"selectPreset: failed to find requested preset." );
}


@end
