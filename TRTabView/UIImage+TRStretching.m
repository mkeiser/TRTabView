//
//  UIImage+TRStretching.m
//  TRTabViewExample
//
//  Created by Matthias Keiser on 20.08.13.
//  Copyright (c) 2013 Matthias Keiser. All rights reserved.
//	matthias@tristan-inc.com
//

#import "UIImage+TRStretching.h"

@implementation UIImage (TRStretching)

- (UIImage *)trImageWithStrechableCenterPixel {
	
	CGSize origSize = self.size;
	UIEdgeInsets insets;
	insets.left = floor(origSize.width / 2);
	insets.right = origSize.width - (insets.left + 1);
	
	insets.top = floor(origSize.height / 2);
	insets.bottom = origSize.height - (insets.top + 1);
	
	return [self resizableImageWithCapInsets:insets];
}

@end
