/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import "UIImage+Transform.h"
#import "NSImage+Compatibility.h"
#import "SDImageGraphics.h"
#import "SDGraphicsImageRenderer.h"
#import "NSBezierPath+RoundedCorners.h"
#import <Accelerate/Accelerate.h>
#if SD_UIKIT || SD_MAC
#import <CoreImage/CoreImage.h>
#endif

static inline CGRect SDCGRectFitWithScaleMode(CGRect rect, CGSize size, SDImageScaleMode scaleMode) {
    rect = CGRectStandardize(rect);
    size.width = size.width < 0 ? -size.width : size.width;
    size.height = size.height < 0 ? -size.height : size.height;
    CGPoint center = CGPointMake(CGRectGetMidX(rect), CGRectGetMidY(rect));
    switch (scaleMode) {
        case SDImageScaleModeAspectFit:
        case SDImageScaleModeAspectFill: {
            if (rect.size.width < 0.01 || rect.size.height < 0.01 ||
                size.width < 0.01 || size.height < 0.01) {
                rect.origin = center;
                rect.size = CGSizeZero;
            } else {
                CGFloat scale;
                if (scaleMode == SDImageScaleModeAspectFit) {
                    if (size.width / size.height < rect.size.width / rect.size.height) {
                        scale = rect.size.height / size.height;
                    } else {
                        scale = rect.size.width / size.width;
                    }
                } else {
                    if (size.width / size.height < rect.size.width / rect.size.height) {
                        scale = rect.size.width / size.width;
                    } else {
                        scale = rect.size.height / size.height;
                    }
                }
                size.width *= scale;
                size.height *= scale;
                rect.size = size;
                rect.origin = CGPointMake(center.x - size.width * 0.5, center.y - size.height * 0.5);
            }
        } break;
        case SDImageScaleModeFill:
        default: {
            rect = rect;
        }
    }
    return rect;
}

static inline UIColor * SDGetColorFromPixel(Pixel_8888 pixel, CGBitmapInfo bitmapInfo) {
    // Get alpha info, byteOrder info
    CGImageAlphaInfo alphaInfo = bitmapInfo & kCGBitmapAlphaInfoMask;
    CGBitmapInfo byteOrderInfo = bitmapInfo & kCGBitmapByteOrderMask;
    CGFloat r = 0, g = 0, b = 0, a = 1;
    
    BOOL byteOrderNormal = NO;
    switch (byteOrderInfo) {
        case kCGBitmapByteOrderDefault: {
            byteOrderNormal = YES;
        } break;
        case kCGBitmapByteOrder32Little: {
        } break;
        case kCGBitmapByteOrder32Big: {
            byteOrderNormal = YES;
        } break;
        default: break;
    }
    switch (alphaInfo) {
        case kCGImageAlphaPremultipliedFirst:
        case kCGImageAlphaFirst: {
            if (byteOrderNormal) {
                // ARGB8888
                a = pixel[0] / 255.0;
                r = pixel[1] / 255.0;
                g = pixel[2] / 255.0;
                b = pixel[3] / 255.0;
            } else {
                // BGRA8888
                b = pixel[0] / 255.0;
                g = pixel[1] / 255.0;
                r = pixel[2] / 255.0;
                a = pixel[3] / 255.0;
            }
        }
            break;
        case kCGImageAlphaPremultipliedLast:
        case kCGImageAlphaLast: {
            if (byteOrderNormal) {
                // RGBA8888
                r = pixel[0] / 255.0;
                g = pixel[1] / 255.0;
                b = pixel[2] / 255.0;
                a = pixel[3] / 255.0;
            } else {
                // ABGR8888
                a = pixel[0] / 255.0;
                b = pixel[1] / 255.0;
                g = pixel[2] / 255.0;
                r = pixel[3] / 255.0;
            }
        }
            break;
        case kCGImageAlphaNone: {
            if (byteOrderNormal) {
                // RGB
                r = pixel[0] / 255.0;
                g = pixel[1] / 255.0;
                b = pixel[2] / 255.0;
            } else {
                // BGR
                b = pixel[0] / 255.0;
                g = pixel[1] / 255.0;
                r = pixel[2] / 255.0;
            }
        }
            break;
        case kCGImageAlphaNoneSkipLast: {
            if (byteOrderNormal) {
                // RGBX
                r = pixel[0] / 255.0;
                g = pixel[1] / 255.0;
                b = pixel[2] / 255.0;
            } else {
                // XBGR
                b = pixel[1] / 255.0;
                g = pixel[2] / 255.0;
                r = pixel[3] / 255.0;
            }
        }
            break;
        case kCGImageAlphaNoneSkipFirst: {
            if (byteOrderNormal) {
                // XRGB
                r = pixel[1] / 255.0;
                g = pixel[2] / 255.0;
                b = pixel[3] / 255.0;
            } else {
                // BGRX
                b = pixel[0] / 255.0;
                g = pixel[1] / 255.0;
                r = pixel[2] / 255.0;
            }
        }
            break;
        case kCGImageAlphaOnly: {
            // A
            a = pixel[0] / 255.0;
        }
            break;
        default:
            break;
    }
    
    return [UIColor colorWithRed:r green:g blue:b alpha:a];
}

@implementation UIImage (Transform)

- (void)sd_drawInRect:(CGRect)rect context:(CGContextRef)context scaleMode:(SDImageScaleMode)scaleMode clipsToBounds:(BOOL)clips {
    CGRect drawRect = SDCGRectFitWithScaleMode(rect, self.size, scaleMode);
    if (drawRect.size.width == 0 || drawRect.size.height == 0) return;
    if (clips) {
        if (context) {
            CGContextSaveGState(context);
            CGContextAddRect(context, rect);
            CGContextClip(context);
            [self drawInRect:drawRect];
            CGContextRestoreGState(context);
        }
    } else {
        [self drawInRect:drawRect];
    }
}

- (nullable UIImage *)sd_resizedImageWithSize:(CGSize)size scaleMode:(SDImageScaleMode)scaleMode {
    if (size.width <= 0 || size.height <= 0) return nil;
    SDGraphicsImageRendererFormat *format = [[SDGraphicsImageRendererFormat alloc] init];
    format.scale = self.scale;
    SDGraphicsImageRenderer *renderer = [[SDGraphicsImageRenderer alloc] initWithSize:size format:format];
    UIImage *image = [renderer imageWithActions:^(CGContextRef  _Nonnull context) {
        [self sd_drawInRect:CGRectMake(0, 0, size.width, size.height) context:context scaleMode:scaleMode clipsToBounds:NO];
    }];
    return image;
}

- (nullable UIImage *)sd_croppedImageWithRect:(CGRect)rect {
    if (!self.CGImage) return nil;
    rect.origin.x *= self.scale;
    rect.origin.y *= self.scale;
    rect.size.width *= self.scale;
    rect.size.height *= self.scale;
    if (rect.size.width <= 0 || rect.size.height <= 0) return nil;
    CGImageRef imageRef = CGImageCreateWithImageInRect(self.CGImage, rect);
    if (!imageRef) {
        return nil;
    }
#if SD_UIKIT || SD_WATCH
    UIImage *image = [UIImage imageWithCGImage:imageRef scale:self.scale orientation:self.imageOrientation];
#else
    UIImage *image = [[UIImage alloc] initWithCGImage:imageRef scale:self.scale orientation:kCGImagePropertyOrientationUp];
#endif
    CGImageRelease(imageRef);
    return image;
}

- (nullable UIImage *)sd_roundedCornerImageWithRadius:(CGFloat)cornerRadius corners:(SDRectCorner)corners borderWidth:(CGFloat)borderWidth borderColor:(nullable UIColor *)borderColor {
    if (!self.CGImage) return nil;
    SDGraphicsImageRendererFormat *format = [[SDGraphicsImageRendererFormat alloc] init];
    format.scale = self.scale;
    SDGraphicsImageRenderer *renderer = [[SDGraphicsImageRenderer alloc] initWithSize:self.size format:format];
    UIImage *image = [renderer imageWithActions:^(CGContextRef  _Nonnull context) {
        CGRect rect = CGRectMake(0, 0, self.size.width, self.size.height);
        
        CGFloat minSize = MIN(self.size.width, self.size.height);
        if (borderWidth < minSize / 2) {
#if SD_UIKIT || SD_WATCH
            UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:CGRectInset(rect, borderWidth, borderWidth) byRoundingCorners:corners cornerRadii:CGSizeMake(cornerRadius, cornerRadius)];
#else
            NSBezierPath *path = [NSBezierPath sd_bezierPathWithRoundedRect:CGRectInset(rect, borderWidth, borderWidth) byRoundingCorners:corners cornerRadius:cornerRadius];
#endif
            [path closePath];
            
            CGContextSaveGState(context);
            [path addClip];
            [self drawInRect:rect];
            CGContextRestoreGState(context);
        }
        
        if (borderColor && borderWidth < minSize / 2 && borderWidth > 0) {
            CGFloat strokeInset = (floor(borderWidth * self.scale) + 0.5) / self.scale;
            CGRect strokeRect = CGRectInset(rect, strokeInset, strokeInset);
            CGFloat strokeRadius = cornerRadius > self.scale / 2 ? cornerRadius - self.scale / 2 : 0;
#if SD_UIKIT || SD_WATCH
            UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:strokeRect byRoundingCorners:corners cornerRadii:CGSizeMake(strokeRadius, strokeRadius)];
#else
            NSBezierPath *path = [NSBezierPath sd_bezierPathWithRoundedRect:strokeRect byRoundingCorners:corners cornerRadius:strokeRadius];
#endif
            [path closePath];
            
            path.lineWidth = borderWidth;
            [borderColor setStroke];
            [path stroke];
        }
    }];
    return image;
}

- (nullable UIImage *)sd_rotatedImageWithAngle:(CGFloat)angle fitSize:(BOOL)fitSize {
    if (!self.CGImage) return nil;
    size_t width = self.size.width;
    size_t height = self.size.height;
    CGRect newRect = CGRectApplyAffineTransform(CGRectMake(0, 0, width, height),
                                                fitSize ? CGAffineTransformMakeRotation(angle) : CGAffineTransformIdentity);
    
    SDGraphicsImageRendererFormat *format = [[SDGraphicsImageRendererFormat alloc] init];
    format.scale = self.scale;
    SDGraphicsImageRenderer *renderer = [[SDGraphicsImageRenderer alloc] initWithSize:newRect.size format:format];
    UIImage *image = [renderer imageWithActions:^(CGContextRef  _Nonnull context) {
        CGContextSetShouldAntialias(context, true);
        CGContextSetAllowsAntialiasing(context, true);
        CGContextSetInterpolationQuality(context, kCGInterpolationHigh);
        CGContextTranslateCTM(context, +(newRect.size.width * 0.5), +(newRect.size.height * 0.5));
#if SD_UIKIT
        // Use UIKit coordinate system counterclockwise (???)
        CGContextRotateCTM(context, -angle);
#else
        CGContextRotateCTM(context, angle);
#endif
        
        [self drawInRect:CGRectMake(-(width * 0.5), -(height * 0.5), width, height)];
    }];
    return image;
}

- (nullable UIImage *)sd_flippedImageWithHorizontal:(BOOL)horizontal vertical:(BOOL)vertical {
    if (!self.CGImage) return nil;
    size_t width = self.size.width;
    size_t height = self.size.height;
    
    SDGraphicsImageRendererFormat *format = [[SDGraphicsImageRendererFormat alloc] init];
    format.scale = self.scale;
    SDGraphicsImageRenderer *renderer = [[SDGraphicsImageRenderer alloc] initWithSize:self.size format:format];
    UIImage *image = [renderer imageWithActions:^(CGContextRef  _Nonnull context) {
        // Use UIKit coordinate system
        if (horizontal) {
            CGAffineTransform flipHorizontal = CGAffineTransformMake(-1, 0, 0, 1, width, 0);
            CGContextConcatCTM(context, flipHorizontal);
        }
        if (vertical) {
            CGAffineTransform flipVertical = CGAffineTransformMake(1, 0, 0, -1, 0, height);
            CGContextConcatCTM(context, flipVertical);
        }
        [self drawInRect:CGRectMake(0, 0, width, height)];
    }];
    return image;
}

#pragma mark - Image Blending

- (nullable UIImage *)sd_tintedImageWithColor:(nonnull UIColor *)tintColor {
    if (!self.CGImage) return nil;
    if (!tintColor.CGColor) return nil;
    
    BOOL hasTint = CGColorGetAlpha(tintColor.CGColor) > __FLT_EPSILON__;
    if (!hasTint) {
#if SD_UIKIT || SD_WATCH
        return [UIImage imageWithCGImage:self.CGImage scale:self.scale orientation:self.imageOrientation];
#else
        return [[UIImage alloc] initWithCGImage:self.CGImage scale:self.scale orientation:kCGImagePropertyOrientationUp];
#endif
    }
    
    CGSize size = self.size;
    CGRect rect = { CGPointZero, size };
    CGFloat scale = self.scale;
    
    // blend mode, see https://en.wikipedia.org/wiki/Alpha_compositing
    CGBlendMode blendMode = kCGBlendModeSourceAtop;
    
    SDGraphicsImageRendererFormat *format = [[SDGraphicsImageRendererFormat alloc] init];
    format.scale = scale;
    SDGraphicsImageRenderer *renderer = [[SDGraphicsImageRenderer alloc] initWithSize:size format:format];
    UIImage *image = [renderer imageWithActions:^(CGContextRef  _Nonnull context) {
        [self drawInRect:rect];
        CGContextSetBlendMode(context, blendMode);
        CGContextSetFillColorWithColor(context, tintColor.CGColor);
        CGContextFillRect(context, rect);
    }];
    return image;
}

- (nullable UIColor *)sd_colorAtPoint:(CGPoint)point {
    if (!self) {
        return nil;
    }
    CGImageRef imageRef = self.CGImage;
    if (!imageRef) {
        return nil;
    }
    
    // Check point
    CGFloat width = CGImageGetWidth(imageRef);
    CGFloat height = CGImageGetHeight(imageRef);
    if (point.x < 0 || point.y < 0 || point.x >= width || point.y >= height) {
        return nil;
    }
    
    // Get pixels
    CGDataProviderRef provider = CGImageGetDataProvider(imageRef);
    if (!provider) {
        return nil;
    }
    CFDataRef data = CGDataProviderCopyData(provider);
    if (!data) {
        return nil;
    }
    
    // Get pixel at point
    size_t bytesPerRow = CGImageGetBytesPerRow(imageRef);
    size_t components = CGImageGetBitsPerPixel(imageRef) / CGImageGetBitsPerComponent(imageRef);
    
    CFRange range = CFRangeMake(bytesPerRow * point.y + components * point.x, 4);
    if (CFDataGetLength(data) < range.location + range.length) {
        CFRelease(data);
        return nil;
    }
    Pixel_8888 pixel = {0};
    CFDataGetBytes(data, range, pixel);
    CFRelease(data);
    
    // Convert to color
    CGBitmapInfo bitmapInfo = CGImageGetBitmapInfo(imageRef);
    return SDGetColorFromPixel(pixel, bitmapInfo);
}

- (nullable NSArray<UIColor *> *)sd_colorsWithRect:(CGRect)rect {
    if (!self) {
        return nil;
    }
    CGImageRef imageRef = self.CGImage;
    if (!imageRef) {
        return nil;
    }
    
    // Check rect
    CGFloat width = CGImageGetWidth(imageRef);
    CGFloat height = CGImageGetHeight(imageRef);
    if (CGRectGetWidth(rect) <= 0 || CGRectGetHeight(rect) <= 0 || CGRectGetMinX(rect) < 0 || CGRectGetMinY(rect) < 0 || CGRectGetMaxX(rect) > width || CGRectGetMaxY(rect) > height) {
        return nil;
    }
    
    // Get pixels
    CGDataProviderRef provider = CGImageGetDataProvider(imageRef);
    if (!provider) {
        return nil;
    }
    CFDataRef data = CGDataProviderCopyData(provider);
    if (!data) {
        return nil;
    }
    
    // Get pixels with rect
    size_t bytesPerRow = CGImageGetBytesPerRow(imageRef);
    size_t components = CGImageGetBitsPerPixel(imageRef) / CGImageGetBitsPerComponent(imageRef);
    
    size_t start = bytesPerRow * CGRectGetMinY(rect) + components * CGRectGetMinX(rect);
    size_t end = bytesPerRow * (CGRectGetMaxY(rect) - 1) + components * CGRectGetMaxX(rect);
    if (CFDataGetLength(data) < (CFIndex)end) {
        CFRelease(data);
        return nil;
    }
    
    const UInt8 *pixels = CFDataGetBytePtr(data);
    size_t row = CGRectGetMinY(rect);
    size_t col = CGRectGetMaxX(rect);
    
    // Convert to color
    CGBitmapInfo bitmapInfo = CGImageGetBitmapInfo(imageRef);
    NSMutableArray<UIColor *> *colors = [NSMutableArray arrayWithCapacity:CGRectGetWidth(rect) * CGRectGetHeight(rect)];
    for (size_t index = start; index < end; index += 4) {
        if (index >= row * bytesPerRow + col * components) {
            // Index beyond the end of current row, go next row
            row++;
            index = row * bytesPerRow + CGRectGetMinX(rect) * components;
            index -= 4;
            continue;
        }
        Pixel_8888 pixel = {pixels[index], pixels[index+1], pixels[index+2], pixels[index+3]};
        UIColor *color = SDGetColorFromPixel(pixel, bitmapInfo);
        [colors addObject:color];
    }
    CFRelease(data);
    
    return [colors copy];
}

#pragma mark - Image Effect

// We use vImage to do box convolve for performance and support for watchOS. However, you can just use `CIFilter.CIBoxBlur`. For other blur effect, use any filter in `CICategoryBlur`
- (nullable UIImage *)sd_blurredImageWithRadius:(CGFloat)blurRadius {
    if (self.size.width < 1 || self.size.height < 1) {
        return nil;
    }
    if (!self.CGImage) {
        return nil;
    }
    
    BOOL hasBlur = blurRadius > __FLT_EPSILON__;
    if (!hasBlur) {
        return self;
    }
    
    CGFloat scale = self.scale;
    CGImageRef imageRef = self.CGImage;
    
    vImage_Buffer effect = {}, scratch = {};
    vImage_Buffer *input = NULL, *output = NULL;
    
    vImage_CGImageFormat format = {
        .bitsPerComponent = 8,
        .bitsPerPixel = 32,
        .colorSpace = NULL,
        .bitmapInfo = kCGImageAlphaPremultipliedFirst | kCGBitmapByteOrder32Little, //requests a BGRA buffer.
        .version = 0,
        .decode = NULL,
        .renderingIntent = kCGRenderingIntentDefault
    };
    
    vImage_Error err;
    err = vImageBuffer_InitWithCGImage(&effect, &format, NULL, imageRef, kvImagePrintDiagnosticsToConsole);
    if (err != kvImageNoError) {
        NSLog(@"UIImage+Transform error: vImageBuffer_InitWithCGImage returned error code %zi for inputImage: %@", err, self);
        return nil;
    }
    err = vImageBuffer_Init(&scratch, effect.height, effect.width, format.bitsPerPixel, kvImageNoFlags);
    if (err != kvImageNoError) {
        NSLog(@"UIImage+Transform error: vImageBuffer_Init returned error code %zi for inputImage: %@", err, self);
        return nil;
    }
    
    input = &effect;
    output = &scratch;
    
    if (hasBlur) {
        // A description of how to compute the box kernel width from the Gaussian
        // radius (aka standard deviation) appears in the SVG spec:
        // http://www.w3.org/TR/SVG/filters.html#feGaussianBlurElement
        //
        // For larger values of 's' (s >= 2.0), an approximation can be used: Three
        // successive box-blurs build a piece-wise quadratic convolution kernel, which
        // approximates the Gaussian kernel to within roughly 3%.
        //
        // let d = floor(s * 3*sqrt(2*pi)/4 + 0.5)
        //
        // ... if d is odd, use three box-blurs of size 'd', centered on the output pixel.
        //
        CGFloat inputRadius = blurRadius * scale;
        if (inputRadius - 2.0 < __FLT_EPSILON__) inputRadius = 2.0;
        uint32_t radius = floor((inputRadius * 3.0 * sqrt(2 * M_PI) / 4 + 0.5) / 2);
        radius |= 1; // force radius to be odd so that the three box-blur methodology works.
        int iterations;
        if (blurRadius * scale < 0.5) iterations = 1;
        else if (blurRadius * scale < 1.5) iterations = 2;
        else iterations = 3;
        NSInteger tempSize = vImageBoxConvolve_ARGB8888(input, output, NULL, 0, 0, radius, radius, NULL, kvImageGetTempBufferSize | kvImageEdgeExtend);
        void *temp = malloc(tempSize);
        for (int i = 0; i < iterations; i++) {
            vImageBoxConvolve_ARGB8888(input, output, temp, 0, 0, radius, radius, NULL, kvImageEdgeExtend);
            vImage_Buffer *tmp = input;
            input = output;
            output = tmp;
        }
        free(temp);
    }
    
    CGImageRef effectCGImage = NULL;
    effectCGImage = vImageCreateCGImageFromBuffer(input, &format, NULL, NULL, kvImageNoAllocate, NULL);
    if (effectCGImage == NULL) {
        effectCGImage = vImageCreateCGImageFromBuffer(input, &format, NULL, NULL, kvImageNoFlags, NULL);
        free(input->data);
    }
    free(output->data);
#if SD_UIKIT || SD_WATCH
    UIImage *outputImage = [UIImage imageWithCGImage:effectCGImage scale:self.scale orientation:self.imageOrientation];
#else
    UIImage *outputImage = [[UIImage alloc] initWithCGImage:effectCGImage scale:self.scale orientation:kCGImagePropertyOrientationUp];
#endif
    CGImageRelease(effectCGImage);
    
    return outputImage;
}

#if SD_UIKIT || SD_MAC
- (nullable UIImage *)sd_filteredImageWithFilter:(nonnull CIFilter *)filter {
    if (!self.CGImage) return nil;
    
    CIContext *context = [CIContext context];
    CIImage *inputImage = [CIImage imageWithCGImage:self.CGImage];
    if (!inputImage) return nil;
    
    [filter setValue:inputImage forKey:kCIInputImageKey];
    CIImage *outputImage = filter.outputImage;
    if (!outputImage) return nil;
    
    CGImageRef imageRef = [context createCGImage:outputImage fromRect:outputImage.extent];
    if (!imageRef) return nil;
    
#if SD_UIKIT
    UIImage *image = [UIImage imageWithCGImage:imageRef scale:self.scale orientation:self.imageOrientation];
#else
    UIImage *image = [[UIImage alloc] initWithCGImage:imageRef scale:self.scale orientation:kCGImagePropertyOrientationUp];
#endif
    CGImageRelease(imageRef);
    
    return image;
}
#endif

@end
