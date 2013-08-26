//
//  TRViewController.m
//  TRTabViewExample
//
//  Created by Matthias Keiser on 29.07.13.
//  Copyright (c) 2013 Matthias Keiser. All rights reserved.
//	info@tristan-inc.com
//

#import "TRViewController.h"
#import "TRContentViewController.h"
#import "TRTab.h"

static NSString * const kTabIdentifier = @"tab";

@interface TRViewController ()

@property (strong, nonatomic) NSMapTable *contentViewControllers;
@property (strong, nonatomic) TRContentViewController *selectedViewController;
@property (weak, nonatomic) IBOutlet UIView *contentEmbeddingView;

@end

@implementation TRViewController

- (BOOL)prefersStatusBarHidden {
	
	return YES;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
				
	self.tabView.showAddButton = YES;
	[self.tabView reloadTabs];
}

#pragma mark - TRTabViewDelegate methods

- (NSUInteger)numberOfTabsInTabView:(TRTabView *)tabView {
	
	return [self.model count];
}

- (TRTab *)tabView:(TRTabView *)tabView tabForIndex:(NSUInteger)index {
	
	TRTab *tab = [tabView dequeueDefaultTabForIndex:index];
	tab.titleLabel.text = [self.model objectAtIndex:index];
	tab.titleLabel.backgroundColor = [UIColor clearColor];

	return tab;
}

- (NSString *)overflowTitleForIndex:(NSUInteger)index {
	
	return [self.model objectAtIndex:index];
}

- (void)tabView:(TRTabView *)tabView didMoveTabAtIndex:(NSUInteger)source toIndex:(NSUInteger)destination {
	
	id modelObject = self.model[source];
	[self.model removeObjectAtIndex:source];
	[self.model insertObject:modelObject atIndex:destination];
}

- (void)tabViewCommitTabAddition:(TRTabView *)tabView {
	
	id modelObject = [NSString stringWithFormat:@"Tab %u", self.globalTabCount++];
	[self.model addObject:modelObject];
	
	[tabView addTabAtIndex:tabView.numberOfTabs animated:YES];
}

- (void)tabView:(TRTabView *)tabView commitTabDeletionAtIndex:(NSUInteger)index {
	
	id model = self.model[index];
	
	[self.contentViewControllers removeObjectForKey:model];
	[self.model removeObjectAtIndex:index];
	
	[self.tabView deleteTabAtIndex:index animated:YES];
}

- (void)tabView:(TRTabView *)tabView didSelectTabAtIndex:(NSUInteger)index {
	
	id modelObject = self.model[index];
	TRContentViewController *contentViewController = [self.contentViewControllers objectForKey:modelObject];
	
	if (!contentViewController) {
		
		contentViewController = [[TRContentViewController alloc] initWithModelObject:modelObject];
		[self.contentViewControllers setObject:contentViewController forKey:modelObject];
	}
	self.selectedViewController = contentViewController;
}

- (NSMutableArray *)model {
	
	if (!_model) {
		
		static const NSUInteger kNumberInitialTabs = 5;
		_model = [NSMutableArray new];
		
		for (NSUInteger i = 0; i < kNumberInitialTabs; i++) {
			
			[_model addObject:[NSString stringWithFormat:@"Tab %u", self.globalTabCount++]];
		}
	}
	
	return _model;
}

- (NSMapTable *)contentViewControllers {
	
	if (!_contentViewControllers) {
		
		_contentViewControllers = [NSMapTable mapTableWithKeyOptions:NSPointerFunctionsObjectPointerPersonality valueOptions:0];
	}
	
	return _contentViewControllers;
}

- (void)setSelectedViewController:(TRContentViewController *)selectedViewController {
	
	if (_selectedViewController.isViewLoaded)
		[_selectedViewController.view removeFromSuperview];
	
	_selectedViewController = selectedViewController;
	
	[self.contentEmbeddingView addSubview:_selectedViewController.view];
	
	UIView *theView = _selectedViewController.view;
	NSDictionary *viewsDictionary = NSDictionaryOfVariableBindings(theView);
	[theView setTranslatesAutoresizingMaskIntoConstraints:NO];
	[self.contentEmbeddingView removeConstraints:self.contentEmbeddingView.constraints];
	[self.contentEmbeddingView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|[theView]|" options:0 metrics:nil views:viewsDictionary]];
	[self.contentEmbeddingView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[theView]|" options:0 metrics:nil views:viewsDictionary]];

}
@end
