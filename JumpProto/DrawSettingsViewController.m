//
//  DrawSettingsViewController.m
//  JumpProto
//
//  Created by Gideon Goodwin on 11/27/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "DrawSettingsViewController.h"

@interface DrawSettingsViewController ()

@end

@implementation DrawSettingsViewController

@synthesize segmentControl, snapSelectionDelegate;

@synthesize brushSizeDelegate;
@synthesize currentWidthTextField, currentHeightTextField, widthStepper, heightStepper;
@synthesize sizePresetButton_2x2, sizePresetButton_4x4, sizePresetButton_8x4;
@synthesize sizePresetButton_8x8, sizePresetButton_32x4;
@synthesize sizePresetButton_4x8, sizePresetButton_12x12, sizePresetButton_16x16, width4Stepper, height4Stepper;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.snapSelectionDelegate = nil;
        self.brushSizeDelegate = nil;
    }
    return self;
}


-(void)viewDidLoad
{
    [super viewDidLoad];

    [self.segmentControl removeAllSegments];
    [self.segmentControl insertSegmentWithTitle:@"1" atIndex:0 animated:NO];
    [self.segmentControl insertSegmentWithTitle:@"2" atIndex:1 animated:NO];
    [self.segmentControl insertSegmentWithTitle:@"4" atIndex:2 animated:NO];
    [self.segmentControl insertSegmentWithTitle:@"8" atIndex:3 animated:NO];
}


- (void)viewDidUnload
{
    [super viewDidUnload];

    self.segmentControl = nil;
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return UIInterfaceOrientationIsLandscape( interfaceOrientation );
}

-(IBAction)onSelectionChanged:(id)sender
{
    if( sender == self.segmentControl )
    {
        if( self.snapSelectionDelegate != nil )
        {
            [self.snapSelectionDelegate onSnapSelectionChanged:self.segmentControl.selectedSegmentIndex];
        }
    }
}

-(IBAction)valueChanged:(UIStepper *)sender
{
    int latestW = self.widthStepper.value;
    int latestH = self.heightStepper.value;
    int val = (int)floorf( [sender value] );
    if( sender == self.widthStepper )
    {
        latestW = val;
        EGridPoint *newSize = [[EGridPoint alloc] initAtXGrid:val yGrid:self.heightStepper.value];
        [self.brushSizeDelegate onBrushSizeChanged:newSize];
    }
    else if( sender == self.heightStepper )
    {
        latestH = val;
        EGridPoint *newSize = [[EGridPoint alloc] initAtXGrid:self.widthStepper.value yGrid:val];
        [self.brushSizeDelegate onBrushSizeChanged:newSize];
    }
    else if( sender == self.width4Stepper )
    {
        latestW = val;
        EGridPoint *newSize = [[EGridPoint alloc] initAtXGrid:val yGrid:self.heightStepper.value];
        [self.brushSizeDelegate onBrushSizeChanged:newSize];
    }
    else if( sender == self.height4Stepper )
    {
        latestH = val;
        EGridPoint *newSize = [[EGridPoint alloc] initAtXGrid:self.widthStepper.value yGrid:val];
        [self.brushSizeDelegate onBrushSizeChanged:newSize];
    }
    self.widthStepper.value = latestW;
    self.width4Stepper.value = latestW;
    self.heightStepper.value = latestH;
    self.height4Stepper.value = latestH;
    [self updateTextFields];
}


-(void)updateTextFields;
{
    self.currentWidthTextField.text = [NSString stringWithFormat:@"%i", (int)self.widthStepper.value];
    self.currentHeightTextField.text = [NSString stringWithFormat:@"%i", (int)self.heightStepper.value];
}


-(IBAction)onPresetButtonPressed:(id)sender
{
    EGridPoint *newSize = NULL;
         if( sender == self.sizePresetButton_2x2 )
    {
        newSize = [[EGridPoint alloc] initAtXGrid:2 yGrid:2];
    }
    else if( sender == self.sizePresetButton_4x4 )
    {
        newSize = [[EGridPoint alloc] initAtXGrid:4 yGrid:4];
    }
    else if( sender == self.sizePresetButton_8x4 )
    {
        newSize = [[EGridPoint alloc] initAtXGrid:8 yGrid:4];
    }
    else if( sender == self.sizePresetButton_8x8 )
    {
        newSize = [[EGridPoint alloc] initAtXGrid:8 yGrid:8];
    }
    else if( sender == self.sizePresetButton_32x4 )
    {
        newSize = [[EGridPoint alloc] initAtXGrid:32 yGrid:4];
    }
    else if( sender == self.sizePresetButton_4x8 )
    {
        newSize = [[EGridPoint alloc] initAtXGrid:4 yGrid:8];
    }
    else if( sender == self.sizePresetButton_12x12 )
    {
        newSize = [[EGridPoint alloc] initAtXGrid:12 yGrid:12];
    }
    else if( sender == sizePresetButton_16x16 )
    {
        newSize = [[EGridPoint alloc] initAtXGrid:16 yGrid:16];
    }
    else
    {
        newSize = [[EGridPoint alloc] initAtXGrid:4 yGrid:4];
    }
    self.widthStepper.value = newSize.xGrid;
    self.heightStepper.value = newSize.yGrid;
    self.width4Stepper.value = newSize.xGrid;
    self.height4Stepper.value = newSize.yGrid;
    [self.brushSizeDelegate onBrushSizeChanged:newSize];
    [self updateTextFields];
}

@end
