//
//  UIImage+Cropping.m
//  SlidePuzzle
//
//  Created by Ryosuke Sasaki on 2013/02/16.
//  Copyright (c) 2013年 Ryosuke Sasaki. All rights reserved.
//

#import "UIImage+Cropping.h"

@implementation UIImage (Cropping)

- (UIImage *)croppedImageInRect:(CGRect)rect
{
    CGImageRef imageRef = CGImageCreateWithImageInRect(self.CGImage, rect);
    UIImage *croppedImage = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);
    
    return croppedImage;
}

@end
