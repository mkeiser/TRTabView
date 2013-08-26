//
//  TRTabView.h
//  TRTabViewExample
//
//  Created by Matthias Keiser on 29.07.13.
//  Copyright (c) 2013 Matthias Keiser. All rights reserved.
//	matthias@tristan-inc.com
//

#import <UIKit/UIKit.h>

@class TRTab;
@protocol TRTabViewDelegate;

typedef NS_ENUM(NSUInteger, TRTabViewButtonMode) {
	
	TRTabViewButtonModeNever,
	TRTabViewButtonModeSelected,
	TRTabViewButtonModeSelectedExceptLast,
	TRTabViewButtonModeAlways
};

@interface TRTabView : UIView

@property (nonatomic, assign, readonly) NSUInteger numberOfTabs;
@property (nonatomic, assign, readonly) NSUInteger numberOfVisibleTabs;
@property (nonatomic, assign) NSUInteger selectedTabIndex;
@property (nonatomic, weak) IBOutlet id <TRTabViewDelegate> delegate;
@property (nonatomic, assign) BOOL showAddButton;
@property (nonatomic, assign) BOOL allowTabReordering;
@property (nonatomic, assign) TRTabViewButtonMode deleteButtonMode;

// Both maximumNumberVisibleTabs and minimumTabWidth are used to determine if the tabs overflow.
// 0 means no constraint. If both are 0, the default minimum tab width is used.

@property (nonatomic, assign) NSUInteger maximumNumberVisibleTabs;
@property (nonatomic, assign) CGFloat minimumTabWidth;

// 0 means as wide as possible (i.e. use the whole available width).

@property (nonatomic, assign) CGFloat maximumTabWidth;

- (void)reloadTabs;

// Mapping taps to indexes

- (TRTab *)tabForIndex:(NSUInteger)index;	// Returns nil if not currently visible.
- (NSUInteger)indexOfTab:(TRTab *)tab;		// Represented index.

// These two methods might be useful during tab drawing (e.g. to decide which borders to draw). The position refers to the currently displayed tab order.

- (NSUInteger)positionOfTab:(TRTab *)tab;	// Currently visible position. If this is the tab currently being dragged, returns the position of the empty slot the tab would snap into when dragging would end now.
- (NSUInteger)positionOfDraggedTab;			// Returns the position of the empty slot the tab would snap into when dragging would end now. Returns NSNotFound is there is no drag operation going on.

// When you call these methods, the delegate must be prepared to return the correct number of tabs.

- (void)addTabAtIndex:(NSUInteger)index animated:(BOOL)animated;
- (void)deleteTabAtIndex:(NSUInteger)index animated:(BOOL)animated;

// Returns a default tab.

- (TRTab *)dequeueDefaultTabForIndex:(NSUInteger)index;

// Support for custom TRTab subclasses. You can use dequeueDefaultTabForIndex: to avoid having to call these methods.

- (void)registerNib:(UINib *)nib forTabIdentifier:(NSString *)identifier;
- (void)registerClass:(Class)tabClass forTabIdentifier:(NSString *)identifier;
- (TRTab *)dequeueTabWithIdentifier:(NSString *)identifier forIndex:(NSUInteger)index;

@end


@protocol TRTabViewDelegate <NSObject>

- (NSUInteger)numberOfTabsInTabView:(TRTabView *)tabView;
- (TRTab *)tabView:(TRTabView *)tabView tabForIndex:(NSUInteger)index;
- (NSString *)overflowTitleForIndex:(NSUInteger)index; // Used in the overflow popover.

@optional

- (BOOL)tabView:(TRTabView *)tabView shouldSelectTabAtIndex:(NSUInteger)index;
- (void)tabView:(TRTabView *)tabView didSelectTabAtIndex:(NSUInteger)index;

- (BOOL)tabView:(TRTabView *)tabView shouldStartDraggingTabAtIndex:(NSUInteger)index; // Posibility to opt out even when allowTabReordering == YES.
- (NSUInteger)tabView:(TRTabView *)tabView targetIndexForMoveFromIndex:(NSUInteger)sourceIndex toProposedIndex:(NSUInteger)proposedIndex;
- (void)tabView:(TRTabView *)tabView didMoveTabAtIndex:(NSUInteger)source toIndex:(NSUInteger)destination; // Update model when this function is called.

- (void)tabView:(TRTabView *)tabView commitTabDeletionAtIndex:(NSUInteger)index; // Typically you update the model here and then call addTabAtIndex:animated:
- (void)tabViewCommitTabAddition:(TRTabView *)tabView; // Typically you update the model here and then call deleteTabAtIndex:animated:

@end
