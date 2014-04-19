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
@synthesize doc;


-(id)initWithNibName:(NSString *)nibNameIn bundle:(NSBundle *)bundleIn doc:(EGridDocument *)docIn
{
    if( self = [super initWithNibName:nibNameIn bundle:bundleIn] )
    {
        self.doc = docIn;
    }
    return self;
}


-(void)dealloc
{
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
}

- (void)viewDidUnload
{
    [super viewDidUnload];
}

- (BOOL)shouldAutorotate
{
    return YES;
}

-(void)updateValuesFromDoc
{
    self.levelNameTextField.text = self.doc.levelName;
    
    // TODO tags
}

@end
