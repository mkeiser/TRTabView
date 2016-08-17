//
//  TRTab.m
//  TRTabView
//
//  Created by Matthias Keiser on 31.07.13.
//  Copyright (c) 2013 Matthias Keiser. All rights reserved.
//	matthias@tristan-inc.com
//

#import "TRTab.h"
#import "UIImage+TRStretching.h"
#import "TRNamedImageProvider.h"

@interface TRTabView (TRTabPrivate)

- (void)userDeleteTab:(TRTab *)tab;
- (void)overflowAction:(TRTab *)tab;

@end

@interface TRTab () <TRNamedImageProviderClient>

@property (nonatomic, weak) TRTabView *tabView;

@end

@implementation TRTab

- (id)initWithFrame:(CGRect)frame {

	if( !(self = [super initWithFrame:frame]) ) return nil;
	
	[self setupTRTab];
	
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
	
	if( !(self = [super initWithCoder:aDecoder]) ) return nil;
	
	[self setupTRTab];

    return self;
}

- (void)setupTRTab {
				
	self.contentMode = UIViewContentModeRedraw;
	
	_titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
	_titleLabel.textAlignment = NSTextAlignmentCenter;
	_titleLabel.backgroundColor = [UIColor clearColor];
	_titleLabel.textColor = [UIColor grayColor];
	_titleLabel.font = [UIFont systemFontOfSize:12];
	_titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    _titleLabel.backgroundColor = [UIColor clearColor];
	[self addSubview:_titleLabel];
	
	_deleteButton = [[UIButton alloc] initWithFrame:CGRectZero];
	[_deleteButton setImage:[self imageNamed:@"deleteButton"] forState:UIControlStateNormal];
	[_deleteButton addTarget:self action:@selector(delete:) forControlEvents:UIControlEventTouchUpInside];
	_deleteButton.translatesAutoresizingMaskIntoConstraints = NO;
	_deleteButton.showsTouchWhenHighlighted = YES;
	_deleteButton.hidden = YES;
	[self addSubview:_deleteButton];
	
	_overflowButton = [UIButton buttonWithType:UIButtonTypeCustom];
	[_overflowButton setImage:[self imageNamed:@"overflowButton"] forState:UIControlStateNormal];
	[_overflowButton addTarget:self action:@selector(overflowAction:) forControlEvents:UIControlEventTouchUpInside];
	_overflowButton.translatesAutoresizingMaskIntoConstraints = NO;
	_overflowButton.showsTouchWhenHighlighted = YES;
	
	_overflowButton.hidden = YES;
	[self addSubview:_overflowButton];

}

+ (BOOL)requiresConstraintBasedLayout {
	
	return YES;
}

static const CGFloat kTitleLabelHeight = 20;
static const CGFloat kDeleteButtonWidth = 30;
static const CGFloat kOverflowButtonWidth = 30;
static const CGFloat kTitleLabelHorizontalMargin = 15;

- (void)updateConstraints {
	
	[self removeConstraints:self.constraints];
		
	CGFloat leftLabelMargin = self.showsDeleteButton ? kDeleteButtonWidth : kTitleLabelHorizontalMargin;
	
#define OBJ_STR(s) (@#s)
	
	NSDictionary *metrics = @{OBJ_STR(kTitleLabelHeight): @(kTitleLabelHeight), OBJ_STR(kDeleteButtonWidth): @(kDeleteButtonWidth), OBJ_STR(kTitleLabelHorizontalMargin): @(kTitleLabelHorizontalMargin), OBJ_STR(leftLabelMargin): @(leftLabelMargin), OBJ_STR(kOverflowButtonWidth) : @(kOverflowButtonWidth)};
	
	NSDictionary *viewsDictionary = NSDictionaryOfVariableBindings(_titleLabel, _deleteButton, _overflowButton,self);
	
	[self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[_titleLabel(kTitleLabelHeight)]" options:0 metrics:metrics views:viewsDictionary]];
	[self addConstraint:[NSLayoutConstraint constraintWithItem:_titleLabel attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeCenterY multiplier:1 constant:0]];
	NSLayoutConstraint *centerConstraint = [NSLayoutConstraint constraintWithItem:_titleLabel attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeCenterX multiplier:1 constant:0];
	centerConstraint.priority = UILayoutPriorityDefaultHigh-1;
	[self addConstraint:centerConstraint];
	[self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-(>=leftLabelMargin@900)-[_titleLabel]-(>=kTitleLabelHorizontalMargin@900)-|" options:0 metrics:metrics views:viewsDictionary]];
	
	[self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|[_deleteButton(kDeleteButtonWidth)]" options:0 metrics:metrics views:viewsDictionary]];
	[self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[_deleteButton]|" options:0 metrics:metrics views:viewsDictionary]];

	[self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"[_overflowButton(kOverflowButtonWidth)]|" options:0 metrics:metrics views:viewsDictionary]];
	[self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[_overflowButton]|" options:0 metrics:metrics views:viewsDictionary]];

	[super updateConstraints];
}

- (void)delete:(id)sender {
	
	[self.tabView userDeleteTab:self];
}

- (void)overflowAction:(id)sender {
	
	[self.tabView overflowAction:self];
}

- (void)setSelected:(BOOL)selected {
	
	_selected = selected;
	self.titleLabel.textColor = selected ? [UIColor blackColor] : [UIColor grayColor];
	[self setNeedsDisplay];
}

- (void)setShowsDeleteButton:(BOOL)showDeleteButton {
	
	BOOL updateConstraints = _showsDeleteButton != showDeleteButton;
	
	_showsDeleteButton = showDeleteButton;
	self.deleteButton.hidden = !showDeleteButton;
	
	if (updateConstraints)
		[self setNeedsUpdateConstraints];
}

- (void)setShowsOverflowButton:(BOOL)showsOverflowButton {
	
	BOOL updateConstraints = _showsOverflowButton != showsOverflowButton;
	
	_showsOverflowButton = showsOverflowButton;
	
	self.overflowButton.hidden = !showsOverflowButton;
	
	if (updateConstraints)
		[self setNeedsUpdateConstraints];
}

- (void)setNeedsDisplay {
	
	[super setNeedsDisplay];
}

// If you modify the border thickness of the tabs (default 1.0), you might have to override the
// tabOverlapWidth method of TRTabView to make it look good.

- (void)drawRect:(CGRect)rect
{
		
	if (!self.tabView)
		return;
	
	NSUInteger position = [self.tabView positionOfTab:self];
	
	if (position == NSNotFound)
		return;
	
	NSUInteger draggedPosition = [self.tabView positionOfDraggedTab];

	//Background
	UIImage *backgroundImage = self.selected ? [self imageNamed:@"trtab_foreground_fill"] : [self imageNamed:@"trtab_background_fill"];
	[[backgroundImage trImageWithStrechableCenterPixel] drawInRect:self.bounds];
		
	//Bottom edge
	UIImage *bottomEdgeImage = [[self imageNamed:@"trtab_bottom_edge"] trImageWithStrechableCenterPixel];
	[bottomEdgeImage drawInRect:CGRectMake(0, self.bounds.size.height - bottomEdgeImage.size.height, self.bounds.size.width, bottomEdgeImage.size.height)];
	
	//Top edge
	if (!self.selected) {
		UIImage *topEdgeImage = [[self imageNamed:@"trtab_top_edge"] trImageWithStrechableCenterPixel];
		[topEdgeImage drawInRect:CGRectMake(0, 0, self.bounds.size.width, topEdgeImage.size.height)];
	}
	
	//Left edge
	if (position > 0 || position == draggedPosition) {
		
		UIImage *verticalEdgeImage = [[self imageNamed:@"trtab_vertical_edge"] trImageWithStrechableCenterPixel];
		[verticalEdgeImage drawInRect:CGRectMake(0, 0, verticalEdgeImage.size.width, self.bounds.size.height)];
	}
	
	//Right edge
	if (CGRectGetMaxX(self.frame) < CGRectGetMaxX(self.tabView.bounds)) {
		UIImage *verticalEdgeImage = [[self imageNamed:@"trtab_vertical_edge"] trImageWithStrechableCenterPixel];
		[verticalEdgeImage drawInRect:CGRectMake(self.bounds.size.width - verticalEdgeImage.size.width, 0, verticalEdgeImage.size.width, self.bounds.size.height)];
	}
}

#pragma mark - TRNamedImageProviderClient

- (UIImage *)imageNamed:(NSString *)name {

	return provideImageWithNameForClient(name, self);
}

@end
