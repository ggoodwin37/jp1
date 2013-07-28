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


-(NSArray *)getPresetCategoryList_batch2
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
    
    [list addObject:category];
    
    return list;
}


-(void)initPresetCategoryList
{
    m_presetCategoryList = [[self getPresetCategoryList_batch1] retain];
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
