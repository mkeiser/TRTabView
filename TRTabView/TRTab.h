//
//  TRTab.h
//  TRTabView
//
//  Created by Matthias Keiser on 31.07.13.
//  Copyright (c) 2013 Matthias Keiser. All rights reserved.
//	matthias@tristan-inc.com
//

#import <UIKit/UIKit.h>
#import "TRTabView.h"

@interface TRTab : UIView

@property (nonatomic, readonly, strong) UILabel *titleLabel;
@property (nonatomic, readonly, strong) UIButton *deleteButton;
@property (nonatomic, readonly, strong) UIButton *overflowButton;
@property (nonatomic, assign) BOOL selected;
@property (nonatomic, assign) BOOL showsDeleteButton;
@property (nonatomic, assign) BOOL showsOverflowButton;

@end
