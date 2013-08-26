//
//  TRViewController.h
//  TRTabViewExample
//
//  Created by Matthias Keiser on 29.07.13.
//  Copyright (c) 2013 Matthias Keiser. All rights reserved.
//	matthias@tristan-inc.com
//

#import <UIKit/UIKit.h>
#import "TRTabView.h"

@class TRContentViewController;

@interface TRViewController : UIViewController

@property (weak, nonatomic) IBOutlet TRTabView *tabView;
@property (assign, nonatomic) NSUInteger globalTabCount;
@property (strong, nonatomic) NSMutableArray *model;

@end
