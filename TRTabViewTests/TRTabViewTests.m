//
//  TRTabViewTests.m
//  TRTabViewTests
//
//  Created by Francis Chong on 17/3/15.
//  Copyright (c) 2015 Matthias Keiser. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>

#import "TRTabView.h"
#import "TRTab.h"
#import "TRTabViewTestDelegate.h"

@interface TRTabViewTests : XCTestCase {
    TRTabView* tabView;
    TRTabViewTestDelegate* delegate;
}
@end

@implementation TRTabViewTests

- (void)setUp {
    [super setUp];
    delegate = [[TRTabViewTestDelegate alloc] init];
    tabView = [[TRTabView alloc] initWithFrame:CGRectMake(0, 0, 320, 640)];
    tabView.delegate = delegate;
    [tabView reloadTabs];
}

- (void)tearDown {
    [super tearDown];
}

- (void)testRemoveTabBeforeCurrentTab {
    XCTAssertEqual(3, tabView.numberOfTabs);
    [tabView setSelectedTabIndex:1];

    [delegate.model removeObjectAtIndex:0];
    [tabView deleteTabAtIndex:0 animated:NO];
    XCTAssertEqual(2, tabView.numberOfTabs);
    XCTAssertEqual(tabView.selectedTabIndex, 0);
}

- (void)testRemoveTabAtCurrentTab {
    XCTAssertEqual(3, tabView.numberOfTabs);
    [tabView setSelectedTabIndex:1];
    
    [delegate.model removeObjectAtIndex:1];
    [tabView deleteTabAtIndex:1 animated:NO];
    XCTAssertEqual(2, tabView.numberOfTabs);
    XCTAssertEqual(tabView.selectedTabIndex, 1);
}

- (void)testRemoveTabAfterCurrentTab {
    XCTAssertEqual(3, tabView.numberOfTabs);
    [tabView setSelectedTabIndex:1];
    
    [delegate.model removeObjectAtIndex:2];
    [tabView deleteTabAtIndex:2 animated:NO];
    XCTAssertEqual(2, tabView.numberOfTabs);
    XCTAssertEqual(tabView.selectedTabIndex, 1);
}

@end
