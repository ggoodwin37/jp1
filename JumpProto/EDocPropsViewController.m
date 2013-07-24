//
//  EDocPropsViewController.m
//  JumpProto
//
//  Created by Gideon Goodwin on 1/24/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "EDocPropsViewController.h"

@implementation EDocPropsViewController

@synthesize levelNameTextField, tagsTextField;
@synthesize packPickerView;
@synthesize doc;
@synthesize selectedManifestName;


-(id)initWithNibName:(NSString *)nibNameIn bundle:(NSBundle *)bundleIn doc:(EGridDocument *)docIn initialLevelPackName:(NSString *)levelPackName
{
    if( self = [super initWithNibName:nibNameIn bundle:bundleIn] )
    {
        self.selectedManifestName = levelPackName;
        m_manifestNameList = nil;
        self.doc = docIn;
    }
    return self;
}


-(void)dealloc
{
    [m_manifestNameList release]; m_manifestNameList = nil;
    self.selectedManifestName = nil;
    
    self.packPickerView = nil;
    
    self.levelNameTextField = nil;
    self.tagsTextField = nil;
    
    self.doc = nil;
    
    [super dealloc];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}


#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self updateValuesFromDoc];
    
    // not good if we want to edit the level name after the initial save.
    //self.levelNameTextField.clearsOnBeginEditing = YES;
    //self.tagsTextField.clearsOnBeginEditing = YES;
    
    // populate picker data source
    m_manifestNameList = [[NSMutableArray arrayWithCapacity:32] retain];
    [[LevelManifestManager instance] addManifestNamesTo:m_manifestNameList];
    
    // try to find the initial pack name we were given.
    int startingIndex = 0;
    if( self.selectedManifestName != nil )
    {
        for( int i = 0; i < [m_manifestNameList count]; ++i )
        {
            NSString *thisString = (NSString *)[m_manifestNameList objectAtIndex:i];
            if( [thisString isEqualToString:self.selectedManifestName] )
            {
                startingIndex = i;
                break;
            }
        }
    }
    startingIndex = MIN( startingIndex, [m_manifestNameList count] - 1 );
    [self.packPickerView selectRow:startingIndex inComponent:0 animated:NO];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
	return interfaceOrientation == UIInterfaceOrientationIsLandscape( interfaceOrientation );
}


-(void)updateValuesFromDoc
{
    self.levelNameTextField.text = self.doc.levelName;
    
    // TODO tags
}


// UIPickerViewDataSource

-(int)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    NSAssert( pickerView == self.packPickerView, @"what pickerView is talking to me?" );
    return 1;
}


-(int)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    NSAssert( pickerView == self.packPickerView, @"what pickerView is talking to me?" );
    NSAssert( component == 0, @"called with bad component number?" );
    return [m_manifestNameList count];
}


// UIPickerViewDelegate

-(void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
    NSAssert( pickerView == self.packPickerView, @"what pickerView is talking to me?" );
    NSAssert( component == 0, @"called with bad component number?" );

    NSAssert( row < [m_manifestNameList count], @"bad row?" );
    LevelManifest *oldManifest = [[LevelManifestManager instance] getOwningManifestForLevelName:self.doc.levelName];
    
    self.selectedManifestName = (NSString *)[m_manifestNameList objectAtIndex:row];
    
    // move to new manifest
    if( oldManifest != nil && ![oldManifest.name isEqualToString:self.selectedManifestName] )
    {
        [[LevelManifestManager instance] removeLevelName:self.doc.levelName fromManifest:oldManifest];
        [[LevelManifestManager instance] writeManifest:oldManifest];
    }

    LevelManifest *newManifest = [[LevelManifestManager instance] getExistingManifestNamed:self.selectedManifestName];
    if( newManifest != nil )
    {
        [[LevelManifestManager instance] addLevelName:self.doc.levelName toManifest:newManifest];
        [[LevelManifestManager instance] writeManifest:newManifest];
    }
}


-(NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    NSAssert( pickerView == self.packPickerView, @"what pickerView is talking to me?" );
    NSAssert( component == 0, @"called with bad component number?" );

    NSAssert( row < [m_manifestNameList count], @"bad row?" );
    return (NSString *)[m_manifestNameList objectAtIndex:row];
}


@end
