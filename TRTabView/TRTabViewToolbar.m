//
//  TRTabViewToolbar.m
//  TRTabView
//
//  Created by Matthias Keiser on 20.08.13.
//  Copyright (c) 2013 Matthias Keiser. All rights reserved.
//	matthias@tristan-inc.com
//

#import "TRTabViewToolbar.h"
#import "UIImage+TRStretching.h"
#import "TRNamedImageProvider.h"

@interface TRTabViewToolbar () <TRNamedImageProviderClient>

@end

@implementation TRTabViewToolbar


- (void)drawRect:(CGRect)rect
{
    
	[[[self imageNamed:@"trtab_foreground_fill"] trImageWithStrechableCenterPixel] drawInRect:self.bounds];
}

- (CGSize)sizeThatFits:(CGSize)size {
	
	size = [super sizeThatFits:size];
	size.height = 54;
	
	return size;
}

- (CGSize)intrinsicContentSize {
	
	CGSize size = [super intrinsicContentSize];
	size.height = 54;
	
	return size;
}

#pragma mark - TRNamedImageProviderClient

- (UIImage *)imageNamed:(NSString *)name {

	return provideImageWithNameForClient(name, self);
}


@end
