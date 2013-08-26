//
//  TRContentViewController.m
//  TRTabViewExample
//
//  Created by Matthias Keiser on 26.08.13.
//  Copyright (c) 2013 Matthias Keiser. All rights reserved.
//	info@tristan-inc.com
//

#import "TRContentViewController.h"

@interface TRContentViewController ()

@property (weak, nonatomic) IBOutlet UILabel *label;

@end

@implementation TRContentViewController

- (id)initWithModelObject:(id)modelObject {
	
	if( !(self = [super initWithNibName:@"TRContentViewController" bundle:nil]) ) return nil;
	
	self.modelObject = modelObject;
	
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	self.label.text = [self.modelObject description];
}

- (void)setModelObject:(id)modelObject {
	
	_modelObject = modelObject;
	self.label.text = [self.modelObject description];
}
@end
