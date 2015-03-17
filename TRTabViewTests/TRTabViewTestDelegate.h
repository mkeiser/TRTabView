//
//  TRTabViewTestDelegate.h
//  TRTabViewExample
//
//  Created by Francis Chong on 17/3/15.
//  Copyright (c) 2015 Matthias Keiser. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TRTabView.h"

@interface TRTabViewTestDelegate : NSObject <TRTabViewDelegate>
@property (nonatomic, strong) NSMutableArray* model;
@end