//
//  TRAppDelegate.h
//  TRTabViewExample
//
//  Created by Matthias Keiser on 29.07.13.
//  Copyright (c) 2013 Matthias Keiser. All rights reserved.
//	matthias@tristan-inc.com
//

#import <UIKit/UIKit.h>

@class TRViewController;

@interface TRAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (strong, nonatomic) TRViewController *viewController;

@end
