//
//  TRContentViewController.h
//  TRTabViewExample
//
//  Created by Matthias Keiser on 26.08.13.
//  Copyright (c) 2013 Matthias Keiser. All rights reserved.
//	matthias@tristan-inc.com
//

#import <UIKit/UIKit.h>

@interface TRContentViewController : UIViewController

@property (nonatomic, strong) id modelObject;

- (id)initWithModelObject:(id)modelObject;

@end
