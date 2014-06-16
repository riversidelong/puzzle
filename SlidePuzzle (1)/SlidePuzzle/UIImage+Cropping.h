//
//  UIImage+Cropping.h
//  SlidePuzzle
//
//  Created by Ryosuke Sasaki on 2013/02/16.
//  Copyright (c) 2013年 Ryosuke Sasaki. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImage (Cropping)
- (UIImage *)croppedImageInRect:(CGRect)rect;
@end
