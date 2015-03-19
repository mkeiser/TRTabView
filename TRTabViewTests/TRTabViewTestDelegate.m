//
//  TRTabViewTestDelegate.m
//  TRTabViewExample
//
//  Created by Francis Chong on 17/3/15.
//  Copyright (c) 2015 Matthias Keiser. All rights reserved.
//

#import "TRTabViewTestDelegate.h"
#import "TRTab.h"

@implementation TRTabViewTestDelegate

-(instancetype) init
{
    self = [super init];
    self.model = [NSMutableArray arrayWithArray:@[@"1", @"2", @"3"]];
    return self;
}

- (NSUInteger)numberOfTabsInTabView:(TRTabView *)tabView
{
    return self.model.count;
}

- (TRTab *)tabView:(TRTabView *)tabView tabForIndex:(NSUInteger)index
{
    TRTab *tab = [tabView dequeueDefaultTabForIndex:index];
    tab.titleLabel.text = [self.model objectAtIndex:index];
    return tab;
}

- (NSString *)overflowTitleForIndex:(NSUInteger)index
{
    return nil;
}

@end