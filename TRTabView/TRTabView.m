//
//  TRTabView.m
//  TRTabView
//
//  Created by Matthias Keiser on 29.07.13.
//  Copyright (c) 2013 Matthias Keiser. All rights reserved.
//	matthias@tristan-inc.com
//

#import "TRTabView.h"
#import "TRTab.h"
#import "UIImage+TRStretching.h"
#import <objc/runtime.h>
#import <objc/message.h>

// Checks if the delegate responds to the given selector and then calls it.
#define INFORM_DELEGATE(delegateSelector, ...) do { \
	if([self.delegate respondsToSelector:@selector(delegateSelector)]) { \
		objc_msgSend(self.delegate, @selector(delegateSelector), __VA_ARGS__); \
	} }\
	while (0)

// Checks if the delegate responds to the given selector and then calls it. For methods returning BOOL.
// If the delegate does not respond, the provided default value is returned.
#define ASK_DELEGATE(default, delegateSelector, ...) (\
	[self.delegate respondsToSelector:@selector(delegateSelector)] ? (BOOL)objc_msgSend(self.delegate, @selector(delegateSelector), __VA_ARGS__) : default \
)

// Duration of all animations.
static const NSTimeInterval kAnimationDuration = .2;

typedef NS_ENUM(NSUInteger, TRTabAnimationStartOffset) {
	
	TRTabAnimationStartOffsetNone,
	TRTabAnimationStartOffsetRight
};

static NSString * const kDefaultTabIdentifier = @"com.tristaninc.trtab.default";

// Overflow table view constants
static NSString * const kOverflowTableCell = @"OverflowTableCell";
static const NSUInteger kOverflowTabSection = 0;

#pragma mark - TRTabDragOperation
#pragma mark -

// The TRTabDragOperation helper object stores all kinds of useful information concerning a drag.

@interface TRTabDragOperation : NSObject

@property (nonatomic, strong) UITouch *touch;
@property (nonatomic, assign) CGPoint dragStartPosition;
@property (nonatomic, assign) NSUInteger visibleIndex;
@property (nonatomic, assign) NSUInteger hypotheticVisibleIndex;
@property (nonatomic, strong) TRTab *tab;
@property (nonatomic, assign) BOOL hasDragged;

@end

@implementation TRTabDragOperation

@end

// Declare private TRTab methods to silence the compiler.

@interface TRTab (TRTabViewPrivate)

- (void)setTabView:(TRTabView *)tabView;

@end

#pragma mark - TRTabView
#pragma mark -

@interface TRTabView () <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) NSMutableDictionary *tabTemplates;
@property (nonatomic, assign, readonly) BOOL overflows;
@property (nonatomic, assign) NSUInteger numberOfVisibleTabs;
@property (nonatomic, strong) NSMutableOrderedSet *tabViews;			// Using an ordered set so we can call indexOfObject: with a good conscience.
@property (nonatomic, assign) NSUInteger indexOfVisibleOverflowedTab;
@property (nonatomic, strong) UIButton *addButton;
@property (nonatomic, readonly, assign) BOOL isDragging;
@property (nonatomic, strong) TRTabDragOperation *currentDragOperation;
@property (nonatomic, assign, readwrite) NSUInteger numberOfTabs;
@property (nonatomic, strong) UITableView *overflowTable;
@property (nonatomic, strong) UIPopoverController *overflowPopover;

@end

@implementation TRTabView

#pragma mark - initialization and setup

- (id)initWithFrame:(CGRect)frame {
	
	if( !(self = [super initWithFrame:frame]) ) return nil;
	
	[self setupTRTabView];
	
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
	
	if( !(self = [super initWithCoder:aDecoder]) ) return nil;
	
	[self setupTRTabView];
	
    return self;
}

- (void)setupTRTabView {
	
	_tabViews = [NSMutableOrderedSet new];
	_tabTemplates = [NSMutableDictionary new];
	_allowTabReordering = YES;
	_deleteButtonMode = TRTabViewButtonModeSelectedExceptLast;
	
	[self registerClass:[TRTab class] forTabIdentifier:kDefaultTabIdentifier];
}

#pragma mark - Tabs

- (void)registerNib:(UINib *)nib forTabIdentifier:(NSString *)identifier {
	
	if (!nib) {
		
		[self.tabTemplates removeObjectForKey:identifier];
		return;
	}
	
	self.tabTemplates[identifier] = nib;
}

- (void)registerClass:(Class)tabClass forTabIdentifier:(NSString *)identifier {
	
	if (!tabClass) {
		
		[self.tabTemplates removeObjectForKey:identifier];
		return;
	}
	
	if (![tabClass isSubclassOfClass:[TRTab class]]) {
		
		[NSException raise:NSInvalidArgumentException format:@"must pass view that must be kind of class TRTab"];
	}
	
	NSString *className = [NSString stringWithUTF8String:class_getName(tabClass)];
	self.tabTemplates[identifier] = className;
}

- (TRTab *)dequeueDefaultTabForIndex:(NSUInteger)index {
	
	return [self dequeueTabWithIdentifier:kDefaultTabIdentifier forIndex:index];
}

- (TRTab *)dequeueTabWithIdentifier:(NSString *)identifier forIndex:(NSUInteger)index {
	
	id template = self.tabTemplates[identifier];
	
	if (!template)
		return nil;
	
	TRTab *tab;
	
	if ([template isKindOfClass:[UINib class]]) {
		
		NSArray *topLevelObjs = [template instantiateWithOwner:nil options:nil];
		
		if([topLevelObjs count] != 1 || ![[topLevelObjs objectAtIndex:0] isSubclassOfClass:[TRTab class]]) {
			
			[NSException raise:NSInvalidArgumentException format:@"Invalid nib registered for identifier %@ - nib must contain exactly one top level object which must be kind of class TRTab", identifier];
		}
		tab = [[template instantiateWithOwner:nil options:nil] objectAtIndex:0];
	}
	else {
		
		tab = [[NSClassFromString(template) alloc] initWithFrame:CGRectZero];
	}
	
	return tab;
}

- (TRTab *)loadTabFromDelegateAtIndex:(NSUInteger)index visibleIndex:(NSUInteger)visibleIndex insert:(BOOL)insert animationStartOffset:(TRTabAnimationStartOffset)animationOffset {
	
	BOOL animationsWereEnabled = [UIView areAnimationsEnabled];
	[UIView setAnimationsEnabled:NO];
	
	TRTab *tab = [self.delegate tabView:self tabForIndex:index];
	[tab setTabView:self];
	
	if (insert) {
		
		[self.tabViews insertObject:tab atIndex:visibleIndex];
	}
	else {
		
		if (visibleIndex < [self.tabViews count]) {
			
			[self.tabViews[visibleIndex] removeFromSuperview];
		}
		self.tabViews[visibleIndex] = tab;
	}

	CGRect frame = [self tabRectForTabAtVisibleIndex:visibleIndex addButtonVisible:self.showAddButton];

	switch (animationOffset) {
		case TRTabAnimationStartOffsetRight:
			frame.origin.x += CGRectGetWidth(frame);
			break;
		default:
			break;
	}
	
	tab.frame = frame;
	
	[tab setNeedsUpdateConstraints];
	[tab setNeedsLayout];
	[tab layoutIfNeeded];

	[UIView setAnimationsEnabled:animationsWereEnabled];

	if (self.showAddButton)
		[self insertSubview:tab aboveSubview:self.addButton];
	else
		[self addSubview:tab];

	return tab;
}

- (void)removeTabAtVisibleIndex:(NSUInteger)visibleIndex {
	
	[self.tabViews[visibleIndex] removeFromSuperview];
	[self.tabViews removeObjectAtIndex:visibleIndex];
}

- (void)reloadTabs {
	
	self.currentDragOperation = nil;
	self.indexOfVisibleOverflowedTab = NSNotFound;
	
	self.numberOfTabs = [self.delegate numberOfTabsInTabView:self];
		
	if (self.overflows && self.numberOfVisibleTabs)
		self.indexOfVisibleOverflowedTab = self.numberOfVisibleTabs - 1;
	
	for (TRTab *tab in self.tabViews)
		[tab removeFromSuperview];
	
	[self.tabViews removeAllObjects];
	
	for (NSUInteger i = 0; i < self.numberOfVisibleTabs; i++) {
		
		[self loadTabFromDelegateAtIndex:i visibleIndex:i insert:NO animationStartOffset:TRTabAnimationStartOffsetNone];
	}
	
	//Trying to keep selection
	if (self.numberOfTabs) {
		
		self.selectedTabIndex = self.selectedTabIndex >= self.numberOfTabs ? 0 : self.selectedTabIndex;
		INFORM_DELEGATE(tabView:didSelectTabAtIndex:, self, self.selectedTabIndex);
	}
	
	[self setNeedsLayout];
}

- (TRTab *)tabForIndex:(NSUInteger)index {
			
	return self.tabViews[[self visibleIndexForTabAtIndex:index]];
}

#pragma mark - Layout

- (CGRect)addButtonRect {
	
	static const CGFloat kMinAddButtonWidth = 44.0;
	static const CGFloat kVerticalInset = 1.0;
	
	CGRect rect;
	
	rect.size.height = CGRectGetHeight(self.bounds);
	rect.size.width = MAX(kMinAddButtonWidth, rect.size.height);
	rect.origin.x = CGRectGetMaxX(self.bounds) - rect.size.width;
	rect.origin.y = 0.0;
	
	rect = CGRectInset(rect, 0, kVerticalInset);
	
	return rect;
}

- (CGRect)visibleTabsRectVisibleAddButton:(BOOL)addButtonVisible {
	
	CGRect rect = self.bounds;
	
	if (addButtonVisible) {
		rect.size.width -= CGRectGetWidth(self.bounds) - CGRectGetMinX([self addButtonRect]);
	}
	
	return rect;
}

- (CGFloat)tabOverlapWidth {
	
	return 1.0;
}

static const CGFloat kOverflowButtonWidth = 30;

- (CGRect)tabRectForTabAtVisibleIndex:(NSUInteger)index addButtonVisible:(BOOL)addButtonVisible {
		
	CGRect visibleTabsRect = [self visibleTabsRectVisibleAddButton:addButtonVisible];
		
	CGFloat overflowWidth = self.overflows ? kOverflowButtonWidth : 0.0;
	
	CGFloat widthPerTab = (CGRectGetWidth(visibleTabsRect) - overflowWidth) / self.numberOfVisibleTabs;
	
	if(self.maximumTabWidth != 0)
		widthPerTab = MIN(widthPerTab, self.maximumTabWidth);

	CGRect rect;
	
	rect.origin.x = floor(CGRectGetMinX(visibleTabsRect) + index * widthPerTab);
	rect.origin.y = CGRectGetMinY(visibleTabsRect);
	rect.size.width = ceil(CGRectGetMinX(visibleTabsRect) + (index + 1) * widthPerTab) - rect.origin.x;
	rect.size.height = CGRectGetHeight(visibleTabsRect);
	
	if (index == (self.numberOfVisibleTabs - 1))
		rect.size.width += overflowWidth;
	else
		rect.size.width += [self tabOverlapWidth];
	
	return rect;
}

- (void)setNumberOfTabs:(NSUInteger)numberOfTabs {
	
	_numberOfTabs = numberOfTabs;
	[self updateLayoutVariables];
}

- (void)setNumberOfVisibleTabs:(NSUInteger)numberOfVisibleTabs {
	
	BOOL needsDisplay = _numberOfVisibleTabs != numberOfVisibleTabs;
	
	_numberOfVisibleTabs = numberOfVisibleTabs;
	
	if (self.overflows) {
		
		if (self.indexOfVisibleOverflowedTab == NSNotFound)
			self.indexOfVisibleOverflowedTab = self.numberOfVisibleTabs - 1;
		else if (self.indexOfVisibleOverflowedTab < self.numberOfVisibleTabs)
			self.indexOfVisibleOverflowedTab = self.numberOfVisibleTabs - 1;
	}
	
	if (needsDisplay)
		[[self.tabViews array] makeObjectsPerformSelector:@selector(setNeedsDisplay)];
}

/*This method computes the number and width of the tabs.

Note: You should avoid calling self.overflows in this method, since this method
sets the variables from which self.overflows is dynamically calculated.*/

- (void)updateLayoutVariables {
	
	static const CGFloat kDefaultMinTabWidth = 88.0;
	CGFloat effectiveMinTabWidth;
	
	if (self.maximumNumberVisibleTabs == 0 && self.minimumTabWidth == 0.0)
		effectiveMinTabWidth = kDefaultMinTabWidth;
	else
		effectiveMinTabWidth = self.minimumTabWidth;
	
	
	NSUInteger numVisibleTabs;
	
	if (self.maximumNumberVisibleTabs)
		numVisibleTabs = MIN(self.maximumNumberVisibleTabs, self.numberOfTabs);
	else
		numVisibleTabs = self.numberOfTabs;
	
	BOOL willOverflow;
	
	CGRect visibleTabsRect = [self visibleTabsRectVisibleAddButton:self.showAddButton];
	
	if (self.numberOfTabs) {
		
		CGFloat widthPerTab = floor(CGRectGetWidth(visibleTabsRect) / numVisibleTabs);
		
		if(effectiveMinTabWidth != 0.0 && widthPerTab < effectiveMinTabWidth) {
			willOverflow = YES;
		}
		else if (self.maximumNumberVisibleTabs && self.numberOfTabs > self.maximumNumberVisibleTabs) {
			willOverflow = YES;
		}
		else {
			willOverflow = NO;
			self.numberOfVisibleTabs = self.numberOfTabs;
		}
	}
	else {
		
		willOverflow = NO;
		self.numberOfVisibleTabs = 0;
	}
	
	if (willOverflow) {
		
		visibleTabsRect = [self visibleTabsRectVisibleAddButton:self.showAddButton];
		
		CGFloat widthPerTab = floor(CGRectGetWidth(visibleTabsRect) / numVisibleTabs);
		
		if (effectiveMinTabWidth != 0.0 && widthPerTab < effectiveMinTabWidth) {
			
			widthPerTab = effectiveMinTabWidth;
		}
		
		NSUInteger numVisible = floor(CGRectGetWidth(visibleTabsRect) / widthPerTab);
		
		if (self.maximumNumberVisibleTabs)
			numVisible = MIN(numVisible, self.maximumNumberVisibleTabs);
		
		self.numberOfVisibleTabs = numVisible;
	}
}

- (void)layoutSubviews {
	
	[self updateLayoutVariables];
	
	if (self.showAddButton) {
		self.addButton.frame = [self addButtonRect];
		
		if ([self.addButton superview] != self)
			[self addSubview:self.addButton];
	}
	else {
		
		[_addButton removeFromSuperview]; // avoid lazy loading
	}
		
	NSUInteger count = 0;
	
	for (TRTab *tab in self.tabViews) {
		
		NSUInteger visibleIndex = count++;
		
		if (tab != self.currentDragOperation.tab) {
			
			if (self.isDragging) {
				
				if (visibleIndex > self.currentDragOperation.visibleIndex && visibleIndex <= self.currentDragOperation.hypotheticVisibleIndex)
					visibleIndex--;
				
				else if (visibleIndex < self.currentDragOperation.visibleIndex && visibleIndex >= self.currentDragOperation.hypotheticVisibleIndex)
					visibleIndex++;
				
			}
			
			[tab setFrame:[self tabRectForTabAtVisibleIndex:visibleIndex addButtonVisible:self.showAddButton]];
			tab.showsOverflowButton = self.overflows && (visibleIndex == (self.numberOfVisibleTabs - 1));
		}
		
		if (self.deleteButtonMode == TRTabViewButtonModeAlways) {
			
			tab.showsDeleteButton = YES;
		}
		else if (self.deleteButtonMode == TRTabViewButtonModeSelected && [self tabForIndex:self.selectedTabIndex] == tab) {
			
			tab.showsDeleteButton = YES;
		}
		else if (self.deleteButtonMode == TRTabViewButtonModeSelectedExceptLast && [self tabForIndex:self.selectedTabIndex] == tab && self.numberOfTabs > 1) {
			
			tab.showsDeleteButton = YES;
		}
		else {
			tab.showsDeleteButton = NO;
		}
	}
}

- (BOOL)overflows {
	
	return (self.numberOfVisibleTabs < self.numberOfTabs);
}

- (void)setBounds:(CGRect)bounds {
	
	[super setBounds:bounds];
	
	[self reloadTabs];
}

- (void)setFrame:(CGRect)frame {
	
	[super setFrame:frame];
	
	[self reloadTabs];
}

#pragma mark - Properties

- (void)setShowAddButton:(BOOL)showAddButton {
	
	_showAddButton = showAddButton;
	
	[self setNeedsLayout];
	[self setNeedsDisplay];
}

- (void)setMaximumNumberVisibleTabs:(NSUInteger)maximumNumberVisibleTabs {
	
	_maximumNumberVisibleTabs = maximumNumberVisibleTabs;
	
	[self reloadTabs];
}

- (void)setMinimumTabWidth:(CGFloat)minimumTabWidth {
	
	_minimumTabWidth = minimumTabWidth;
	
	[self reloadTabs];
}

- (void)setMaximumTabWidth:(CGFloat)maximumTabWidth {
	
	_maximumTabWidth = maximumTabWidth;
	
	[self setNeedsLayout];
}

- (void)setSelectedTabIndex:(NSUInteger)selectedTabIndex {
	
	if (selectedTabIndex >= self.numberOfTabs) {
		
		[NSException raise:NSRangeException format:@"Selected index out of range"];
	}
	
	_selectedTabIndex = selectedTabIndex;
			
	if (self.overflows && self.selectedTabIndex >= (self.numberOfVisibleTabs - 1) && self.indexOfVisibleOverflowedTab != self.selectedTabIndex) {
		self.indexOfVisibleOverflowedTab = self.selectedTabIndex;
		TRTab * tab = [self loadTabFromDelegateAtIndex:self.indexOfVisibleOverflowedTab visibleIndex:(self.numberOfVisibleTabs - 1) insert:NO animationStartOffset:TRTabAnimationStartOffsetNone];
		tab.showsOverflowButton = YES;
	}
	
	NSUInteger visibleIndex = [self visibleIndexForTabAtIndex:selectedTabIndex];
	
	for (NSUInteger i = 0; i < [self.tabViews count]; i++) {
		
		TRTab *tab = self.tabViews[i];
		
		if (i == visibleIndex)
			tab.selected = YES;
		else if (tab.selected) //Only send message if necessary
			tab.selected = NO;
	}
	
	[self setNeedsLayout];
	[self setNeedsDisplay];
}

- (void)setDeleteButtonMode:(TRTabViewButtonMode)deleteButtonMode {
	
	_deleteButtonMode = deleteButtonMode;
	
	[self setNeedsLayout];
}

#pragma mark - Lazyily loaded subviews

- (UIButton *)addButton {
	
	if(!_addButton) {
		
		_addButton = [[UIButton alloc] initWithFrame:[self addButtonRect]];
		[_addButton setImage:[UIImage imageNamed:@"addButton"] forState:UIControlStateNormal];
		[_addButton addTarget:self action:@selector(userAddTab:) forControlEvents:UIControlEventTouchUpInside];
	}
	
	return _addButton;
}

- (UITableView *)overflowTable {
	
	if (!_overflowTable) {
		
		_overflowTable = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
		_overflowTable.dataSource = self;
		_overflowTable.delegate = self;
		[_overflowTable registerClass:[UITableViewCell class] forCellReuseIdentifier:kOverflowTableCell];
		_overflowTable.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
	}
	
	return _overflowTable;
}

- (UIPopoverController *)overflowPopover {
	
	if (!_overflowPopover) {
		
		UIViewController *viewController = [[UIViewController alloc] initWithNibName:nil bundle:nil];
		viewController.view = self.overflowTable;
		_overflowPopover = [[UIPopoverController alloc] initWithContentViewController:viewController];
	}
	
	return _overflowPopover;
}

#pragma mark - Event handling

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
	
	if (!self.numberOfVisibleTabs)
		return;
	
	if([touches count] != 1)
		return;
	
	UITouch *touch = [touches anyObject];
	
	if (touch.tapCount != 1)
		return;
	
	CGPoint touchLocation = [touch locationInView:self];
	
	for (NSUInteger i = 0; i < self.numberOfVisibleTabs; i++) {
		
		if (CGRectContainsPoint([self tabRectForTabAtVisibleIndex:i addButtonVisible:self.showAddButton], touchLocation)) {
			
			NSUInteger index = [self tabIndexForVisibleIndex:i];
			
			if(ASK_DELEGATE(YES, tabView:shouldSelectTabAtIndex:, self, index)) {
				
				self.selectedTabIndex = index;
				INFORM_DELEGATE(tabView:didSelectTabAtIndex:, self, self.selectedTabIndex);
				
				// We only initiate a drag operation if we can select the tab and reordering is allowed.
				if(self.allowTabReordering && ASK_DELEGATE(YES, tabView:shouldStartDraggingTabAtIndex:, self, index)) {
										
					TRTabDragOperation *dragOperation = [TRTabDragOperation new];
					dragOperation.tab = self.tabViews[i];
					dragOperation.dragStartPosition = touchLocation;
					dragOperation.visibleIndex = i;
					dragOperation.hypotheticVisibleIndex = i;
					dragOperation.touch = touch;
					
					self.currentDragOperation = dragOperation;
					
					[self bringSubviewToFront:self.currentDragOperation.tab];
				}
			}
			
			break;
		}
	}
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
	
	if (self.isDragging && [touches containsObject:self.currentDragOperation.touch]) {
		
		CGFloat deltaX = [self.currentDragOperation.touch locationInView:self].x - self.currentDragOperation.dragStartPosition.x;
		
		if (!self.currentDragOperation.hasDragged && fabs(deltaX) > 1) {
			self.currentDragOperation.hasDragged = YES;
			[[self.tabViews array] makeObjectsPerformSelector:@selector(setNeedsDisplay)];
		}
		
		// Using the original visible index to calculate the position
		CGRect frame = [self tabRectForTabAtVisibleIndex:self.currentDragOperation.visibleIndex addButtonVisible:self.showAddButton];
		frame.origin.x += deltaX;
		
		NSUInteger hypotheticVisibleIndex = NSNotFound; //Silence analyzer
		CGFloat minCenterDistance = CGFLOAT_MAX;
		CGFloat draggedCenterX = CGRectGetMidX(frame);
		
		for (NSUInteger i = 0; i < self.numberOfVisibleTabs; i++) {
			
			CGRect tabFrame = [self tabRectForTabAtVisibleIndex:i addButtonVisible:self.showAddButton];
			CGFloat distanceX = fabs(CGRectGetMidX(tabFrame) - draggedCenterX);
			
			if(distanceX < minCenterDistance) {
				
				minCenterDistance = distanceX;
				hypotheticVisibleIndex = i;
			}
		}
		
		if ([self.delegate respondsToSelector:@selector(tabView:targetIndexForMoveFromIndex:toProposedIndex:)]) {
			
			NSUInteger hypotheticIndex = [self.delegate tabView:self targetIndexForMoveFromIndex:[self tabIndexForVisibleIndex:self.currentDragOperation.visibleIndex] toProposedIndex:[self tabIndexForVisibleIndex:hypotheticVisibleIndex]];
			hypotheticVisibleIndex = [self visibleIndexForTabAtIndex:hypotheticIndex];//TODO: check for nsnotfound
		}
		
		// Using the momentary visible index to update the size (might change because of overflow button)
		frame.size = [self tabRectForTabAtVisibleIndex:hypotheticVisibleIndex addButtonVisible:self.showAddButton].size;
					
			self.currentDragOperation.tab.frame = frame;
			self.currentDragOperation.tab.showsOverflowButton = self.overflows && (hypotheticVisibleIndex == (self.numberOfVisibleTabs - 1));
			
			if(hypotheticVisibleIndex != self.currentDragOperation.hypotheticVisibleIndex) {
				
				self.currentDragOperation.hypotheticVisibleIndex = hypotheticVisibleIndex;
				
				[UIView animateWithDuration:kAnimationDuration delay:0.0 options:UIViewAnimationOptionOverrideInheritedDuration animations:^{
					
					[self setNeedsLayout];
					[self layoutIfNeeded];
					[[self.tabViews array] makeObjectsPerformSelector:@selector(setNeedsDisplay)];
				} completion:NULL];
			}
	}
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
	
	if (self.isDragging && [touches containsObject:self.currentDragOperation.touch]) {
						
		self.currentDragOperation = nil;
		
		[UIView animateWithDuration:kAnimationDuration animations:^{
			
			[self setNeedsLayout];
			[self layoutIfNeeded];
			[[self.tabViews array] makeObjectsPerformSelector:@selector(setNeedsDisplay)];
		}];
	}
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
	
	if (self.isDragging && [touches containsObject:self.currentDragOperation.touch]) {
		
		if ([self.delegate respondsToSelector:@selector(tabView:didMoveTabAtIndex:toIndex:)])
			[self.delegate tabView:self didMoveTabAtIndex:[self tabIndexForVisibleIndex:self.currentDragOperation.visibleIndex] toIndex:[self tabIndexForVisibleIndex:self.currentDragOperation.hypotheticVisibleIndex]];
		
		TRTab *tab = self.tabViews[self.currentDragOperation.visibleIndex];
		[self.tabViews removeObjectAtIndex:self.currentDragOperation.visibleIndex];
		[self.tabViews insertObject:tab atIndex:self.currentDragOperation.hypotheticVisibleIndex];

		self.selectedTabIndex = self.currentDragOperation.hypotheticVisibleIndex;
		self.currentDragOperation = nil;
	
		[UIView animateWithDuration:kAnimationDuration animations:^{
			
			[self setNeedsLayout];
			[self layoutIfNeeded];
			[[self.tabViews array] makeObjectsPerformSelector:@selector(setNeedsDisplay)];
		}];
	}
}

- (BOOL)isDragging {
		
	return !!self.currentDragOperation;
}

#pragma mark - Visible index

- (NSUInteger)visibleIndexForTabAtIndex:(NSUInteger)index {
	
	if (index >= self.numberOfTabs) {
		
		[NSException raise:NSRangeException format:@"Provided index >= self.numberOfTabs."];
	}
	if (self.overflows && index == self.indexOfVisibleOverflowedTab)
		return (self.numberOfVisibleTabs - 1);
	
	if (index >= self.numberOfVisibleTabs)
		return NSNotFound;
	
	return index;
}

- (NSUInteger)tabIndexForVisibleIndex:(NSUInteger)visibleIndex {
	
	if (visibleIndex >= self.numberOfVisibleTabs) {
		
		[NSException raise:NSRangeException format:@"Provided visible index >= self.numberOfVisibleTabs."];
	}
	
	if (self.overflows && (visibleIndex + 1) == self.numberOfVisibleTabs)
		return self.indexOfVisibleOverflowedTab;
	
	return visibleIndex;
}

- (NSUInteger)indexOfVisibleOverflowedTab {
	
	// This frees us of having to constantly worry about this var being invalidated
	if (!self.overflows || !self.numberOfTabs)
		return NSNotFound;
	
	return _indexOfVisibleOverflowedTab;
}

- (NSUInteger)positionOfTab:(TRTab *)tab {
	
	NSUInteger arrayIndex = [self.tabViews indexOfObject:tab];
	
	if (arrayIndex == NSNotFound) {
		return NSNotFound;
	}
	
	if (!self.currentDragOperation)
		return arrayIndex;
	
	if (self.currentDragOperation.tab == tab) {
		return self.currentDragOperation.hypotheticVisibleIndex;
	}
	
	if (arrayIndex > self.currentDragOperation.visibleIndex && arrayIndex <= self.currentDragOperation.hypotheticVisibleIndex)
		arrayIndex--;
	
	else if (arrayIndex < self.currentDragOperation.visibleIndex && arrayIndex >= self.currentDragOperation.hypotheticVisibleIndex)
		arrayIndex++;

	return arrayIndex;
}

- (NSUInteger)positionOfDraggedTab {
	
	return (self.currentDragOperation.hasDragged ? self.currentDragOperation.hypotheticVisibleIndex : NSNotFound);
}

- (NSUInteger)indexOfTab:(TRTab *)tab {
	
	NSUInteger arrayIndex = [self.tabViews indexOfObject:tab];
	
	if (arrayIndex == NSNotFound) {
		return NSNotFound;
	}

	return [self tabIndexForVisibleIndex:arrayIndex];
}

#pragma mark - actions


- (IBAction)userAddTab:(id)sender {
	
	INFORM_DELEGATE(tabViewCommitTabAddition:, self);
}

// Sent from TRTab
- (IBAction)userDeleteTab:(TRTab *)tab {
	
	NSUInteger visibleIndex = [self.tabViews indexOfObject:tab];
	
	if(visibleIndex == NSNotFound) {
		
		[NSException raise:NSInvalidArgumentException format:@"Trying to delete tab that is not in use by this tab view."];
	}
	
	NSUInteger index = [self tabIndexForVisibleIndex:visibleIndex];
	
	INFORM_DELEGATE(tabView:commitTabDeletionAtIndex:, self, index);
}

- (IBAction)overflowAction:(TRTab *)tab {
	
	[self.overflowTable reloadData];
	self.overflowPopover.popoverContentSize = CGSizeMake(320, [self.overflowTable numberOfRowsInSection:kOverflowTabSection] * self.overflowTable.rowHeight);
	[self.overflowPopover presentPopoverFromRect:tab.overflowButton.frame inView:tab permittedArrowDirections:UIPopoverArrowDirectionUp animated:YES];
	[self.overflowTable flashScrollIndicators];
}

#pragma mark - Tab addition and deletion

- (void)deleteTabAtIndex:(NSUInteger)index animated:(BOOL)animated {
	
	if (index >= self.numberOfTabs)
		[NSException raise:NSRangeException format:@"Index out of range"];
	
	
	NSUInteger updatedNumberOfTabs = [self.delegate numberOfTabsInTabView:self];
	
	if (updatedNumberOfTabs != (self.numberOfTabs - 1))
		[NSException raise:NSGenericException format:@"Invalid number of tabs (%lu): was %lu before, should be %lu after calling deleteTabAtIndex:animated:", (unsigned long)updatedNumberOfTabs, (unsigned long)self.numberOfTabs, (unsigned long)(self.numberOfTabs - 1)];


	NSUInteger oldVisibleOverflowedIndex = self.indexOfVisibleOverflowedTab;
	NSUInteger newIndex, newVisibleIndex = NSNotFound;

	if (self.overflows) {
		
		NSRange regularTabs = NSMakeRange(0, self.numberOfVisibleTabs - 1);
		NSRange tabsStackedBelow = NSMakeRange(NSMaxRange(regularTabs), self.indexOfVisibleOverflowedTab - regularTabs.length);
		NSRange tabsStackedAbove = NSMakeRange(self.indexOfVisibleOverflowedTab + 1, self.numberOfTabs);

		if (NSLocationInRange(index, regularTabs)) {
			
			regularTabs.length--;
			tabsStackedBelow.location--;
			self.indexOfVisibleOverflowedTab--;
			tabsStackedAbove.location--;
			
			[self removeTabAtVisibleIndex:index]; // index == visibleIndex in this case
			
			if (tabsStackedBelow.length) {
				
				newIndex = tabsStackedBelow.location; // First one of the tabs "stacked below".
				newVisibleIndex = NSMaxRange(regularTabs);
			}
			else if (tabsStackedAbove.length) {
				
				newIndex = tabsStackedAbove.location; // First one of the tabs "stacked above"
				newVisibleIndex = NSMaxRange(regularTabs) + 1; // +1 because we just decremented it
			}
		}
		else if (NSLocationInRange(index, tabsStackedBelow)) {
			
			tabsStackedBelow.length--;
			self.indexOfVisibleOverflowedTab--;
			tabsStackedAbove.location--;
		}
		else if (index == self.indexOfVisibleOverflowedTab) {
			
			[self removeTabAtVisibleIndex:self.numberOfVisibleTabs - 1]; // Remove visible overflow tab
			
			if (tabsStackedBelow.length) {
				
				tabsStackedBelow.length--;
				self.indexOfVisibleOverflowedTab--;
				tabsStackedAbove.location--;

				newIndex = NSMaxRange(tabsStackedBelow);
				newVisibleIndex = NSMaxRange(regularTabs);
			}
			else if (tabsStackedAbove.length) {
				
				tabsStackedAbove.location--;
				tabsStackedAbove.length--;
				self.indexOfVisibleOverflowedTab = self.indexOfVisibleOverflowedTab; // Same index, but different logical tab. Reassign in case we ever override the setter.
				
				newIndex = tabsStackedAbove.location;
				newVisibleIndex = NSMaxRange(regularTabs);
			}
		}
	}
	else {
		
		[self removeTabAtVisibleIndex:index]; // index == visibleIndex in this case
		self.indexOfVisibleOverflowedTab = NSNotFound;
	}
	
	self.numberOfTabs--;
	
	if (newVisibleIndex != NSNotFound) {
		
		[self loadTabFromDelegateAtIndex:newIndex visibleIndex:newVisibleIndex insert:YES animationStartOffset:TRTabAnimationStartOffsetRight];
	}

			
	// In case we deleted the selected tab, figure out which one should be selected instead.
	if (self.selectedTabIndex == index) {
		
		[self updateLayoutVariables];
		
		if (self.selectedTabIndex == oldVisibleOverflowedIndex) {
			
			if (self.overflows)
				self.selectedTabIndex = self.indexOfVisibleOverflowedTab;
			else
				self.selectedTabIndex = self.numberOfVisibleTabs - 1;
		}
		else if (self.selectedTabIndex < self.numberOfTabs) {
			
			self.selectedTabIndex = self.selectedTabIndex; //reassign
		}
		else if (self.selectedTabIndex > 0) {
			
			self.selectedTabIndex--;
		}
		
		INFORM_DELEGATE(tabView:didSelectTabAtIndex:, self, self.selectedTabIndex);
	}

	[UIView animateWithDuration:kAnimationDuration animations:^{
		
		BOOL animationWereEnabled = [UIView areAnimationsEnabled];
		[UIView setAnimationsEnabled:animated];
		
		[self setNeedsLayout];
		[self layoutIfNeeded];
		
		[UIView setAnimationsEnabled:animationWereEnabled];
		
		[[self.tabViews array] makeObjectsPerformSelector:@selector(setNeedsDisplay)];
	}];
}

- (void)addTabAtIndex:(NSUInteger)index animated:(BOOL)animated {
		
	if (index > self.numberOfTabs)
		[NSException raise:NSRangeException format:@"Index out of range"];
	
	
	NSUInteger updatedNumberOfTabs = [self.delegate numberOfTabsInTabView:self];
	
	if (updatedNumberOfTabs != (self.numberOfTabs + 1))
		[NSException raise:NSGenericException format:@"Invalid number of tabs (%lu): was %lu before, should be %lu after calling deleteTabAtIndex:animated:", (unsigned long)updatedNumberOfTabs, (unsigned long)self.numberOfTabs, (unsigned long)(self.numberOfTabs + 1)];

	
	self.numberOfTabs++;
	TRTab *tab;
	
	BOOL rightmostTabAnimateOut = NO;
	
	if ((index + 1) >= self.numberOfVisibleTabs) {
		
		tab = [self loadTabFromDelegateAtIndex:index visibleIndex:(self.numberOfVisibleTabs - 1) insert:NO animationStartOffset:TRTabAnimationStartOffsetRight];
		self.indexOfVisibleOverflowedTab = index;
	}
	else {
		
		tab = [self loadTabFromDelegateAtIndex:index visibleIndex:index insert:YES animationStartOffset:TRTabAnimationStartOffsetNone];
		tab.alpha = 0.0;
		
		if (self.numberOfVisibleTabs < self.numberOfTabs)
			rightmostTabAnimateOut = YES;
	}
	
	self.selectedTabIndex = index;
	tab.selected = YES;
	
	[UIView animateWithDuration:kAnimationDuration animations:^{
		
		BOOL animationWereEnabled = [UIView areAnimationsEnabled];
		[UIView setAnimationsEnabled:animated];
		
		[self setNeedsLayout];
		[self layoutIfNeeded];
		tab.alpha = 1.0;
		[[self.tabViews array] makeObjectsPerformSelector:@selector(setNeedsDisplay)];
				
		[UIView setAnimationsEnabled:animationWereEnabled];
	} completion:^(BOOL finished) {
		
		if (rightmostTabAnimateOut) {
			
			[self removeTabAtVisibleIndex:[self.tabViews count] - 1];
		}
		
		INFORM_DELEGATE(tabView:didSelectTabAtIndex:, self, self.selectedTabIndex);
	}];
}

#pragma mark - UITableViewDataSource (overflow table)

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	
	if (section == kOverflowTabSection) {
		
		return (self.numberOfTabs - self.numberOfVisibleTabs) + 1;
	}
	
	return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	
	UITableViewCell *cell = nil;
	
	if (indexPath.section == kOverflowTabSection) {
		
		NSUInteger tabIndex = (self.numberOfVisibleTabs + indexPath.row) - 1;
	
		cell = [tableView dequeueReusableCellWithIdentifier:kOverflowTableCell forIndexPath:indexPath];
		cell.textLabel.text = [self.delegate overflowTitleForIndex:tabIndex];
	
		cell.accessoryType = tabIndex == self.indexOfVisibleOverflowedTab ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
	}
	
	return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	
	if (indexPath.section == kOverflowTabSection) {
		
		self.indexOfVisibleOverflowedTab = (self.numberOfVisibleTabs + indexPath.row) - 1;
		
		[self loadTabFromDelegateAtIndex:self.indexOfVisibleOverflowedTab visibleIndex:self.numberOfVisibleTabs - 1 insert:NO animationStartOffset:TRTabAnimationStartOffsetNone];
		self.selectedTabIndex = self.indexOfVisibleOverflowedTab;
		[self setNeedsLayout];
		INFORM_DELEGATE(tabView:didSelectTabAtIndex:, self, self.selectedTabIndex);
	}
	
	[self.overflowPopover dismissPopoverAnimated:YES];
}

#pragma mark - drawing

- (void)drawRect:(CGRect)rect {
	
	[[[UIImage imageNamed:@"trtabview_background"] trImageWithStrechableCenterPixel] drawInRect:self.bounds];
	
	UIImage *topEdge = [[UIImage imageNamed:@"trtab_top_edge"] trImageWithStrechableCenterPixel];
	[topEdge drawInRect:CGRectMake(0, 0, self.bounds.size.width, topEdge.size.height)];

	UIImage *bottomEdge = [[UIImage imageNamed:@"trtabview_bottom_edge"] trImageWithStrechableCenterPixel];
	[bottomEdge drawInRect:CGRectMake(0, self.bounds.size.height - bottomEdge.size.height, self.bounds.size.width, bottomEdge.size.height)];
}

@end

