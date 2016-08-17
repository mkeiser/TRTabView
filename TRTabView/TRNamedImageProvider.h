//
//  TRNamedImageProvider.h
//  TRTabViewExample
//
//  Created by Matthias Keiser on 17.08.16.
//  Copyright © 2016 Matthias Keiser. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Availability.h>

// This provides an convenient way to access images in a backwards compatible way if we build a framework.

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 80000 /*__IPHONE_8_0*/
@protocol TRNamedImageProviderClient <UITraitEnvironment>
#else
@protocol TRNamedImageProviderClient <NSObject>
#endif

@required
- (UIImage *)imageNamed:(NSString *)name;

@end

static inline UIImage *provideImageWithNameForClient(NSString *name, id<TRNamedImageProviderClient>client) {

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 80000 /*__IPHONE_8_0*/
	return [UIImage imageNamed:name inBundle:[NSBundle bundleForClass:client.class] compatibleWithTraitCollection:client.traitCollection];
#else
	return [UIImage imageNamed:name];
#endif
}
