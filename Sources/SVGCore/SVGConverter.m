//
//  File.swift
//  swift-markdown-ui
//
//  Created by 唐海 on 11/5/24.
//

// SVGConverter.h
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

// SVGConverter.m
#import "SVGConverter.h"
#import <dlfcn.h>
#import <objc/runtime.h>

#define kSVGTagEnd @"</svg>"

typedef struct CF_BRIDGED_TYPE(id) CGSVGDocument *CGSVGDocumentRef;

// CoreSVG framework函数声明
static CGSVGDocumentRef (*SDCGSVGDocumentRetain)(CGSVGDocumentRef);
static void (*SDCGSVGDocumentRelease)(CGSVGDocumentRef);
static CGSVGDocumentRef (*SDCGSVGDocumentCreateFromData)(CFDataRef data, CFDictionaryRef options);
static void (*SDCGSVGDocumentWriteToData)(CGSVGDocumentRef document, CFDataRef data, CFDictionaryRef options);
static void (*SDCGContextDrawSVGDocument)(CGContextRef context, CGSVGDocumentRef document);
static CGSize (*SDCGSVGDocumentGetCanvasSize)(CGSVGDocumentRef document);

#if TARGET_OS_IOS || TARGET_OS_WATCH
static SEL SDImageWithCGSVGDocumentSEL = NULL;
static SEL SDCGSVGDocumentSEL = NULL;
#endif

@implementation SVGConverter

+ (instancetype)sharedConverter {
    static SVGConverter *converter = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        converter = [[SVGConverter alloc] init];
    });
    return converter;
}

+ (void)initialize {
    // 初始化CoreSVG框架函数
    SDCGSVGDocumentRetain = (CGSVGDocumentRef (*)(CGSVGDocumentRef))dlsym(RTLD_DEFAULT, "CGSVGDocumentRetain");
    SDCGSVGDocumentRelease = (void (*)(CGSVGDocumentRef))dlsym(RTLD_DEFAULT, "CGSVGDocumentRelease");
    SDCGSVGDocumentCreateFromData = (CGSVGDocumentRef (*)(CFDataRef, CFDictionaryRef))dlsym(RTLD_DEFAULT, "CGSVGDocumentCreateFromData");
    SDCGContextDrawSVGDocument = (void (*)(CGContextRef, CGSVGDocumentRef))dlsym(RTLD_DEFAULT, "CGContextDrawSVGDocument");
    SDCGSVGDocumentGetCanvasSize = (CGSize (*)(CGSVGDocumentRef))dlsym(RTLD_DEFAULT, "CGSVGDocumentGetCanvasSize");
    
#if TARGET_OS_IOS || TARGET_OS_WATCH
    SDImageWithCGSVGDocumentSEL = NSSelectorFromString(@"_imageWithCGSVGDocument:");
    SDCGSVGDocumentSEL = NSSelectorFromString(@"_CGSVGDocument");
#endif
}

+ (BOOL)isSVGFormatForData:(NSData *)data {
    if (!data) {
        return NO;
    }
    // 检查是否以SVG标签结尾
    NSData *endTag = [kSVGTagEnd dataUsingEncoding:NSUTF8StringEncoding];
    NSRange searchRange = NSMakeRange(data.length - MIN(100, data.length), MIN(100, data.length));
    return [data rangeOfData:endTag options:NSDataSearchBackwards range:searchRange].location != NSNotFound;
}

- (UIImage *)convertSVGToImage:(NSData *)svgData targetSize:(CGSize)targetSize preserveAspectRatio:(BOOL)preserveAspectRatio {
    if (!svgData) {
        return nil;
    }
    
    // 如果目标大小都未指定且支持矢量图,使用矢量渲染
    if ([SVGConverter supportsVectorSVG]) {
        UIImage *image = [self convertSVGToVectorImage:svgData size:targetSize];
        if (image != nil) {
            return image;
        }
    }
    
    // 创建SVG文档
    CGSVGDocumentRef document = SDCGSVGDocumentCreateFromData((__bridge CFDataRef)svgData, NULL);
    if (!document) {
        return nil;
    }
    
    // 获取原始大小
    CGSize originalSize = SDCGSVGDocumentGetCanvasSize(document);
    if (originalSize.width == 0 || originalSize.height == 0) {
        SDCGSVGDocumentRelease(document);
        return nil;
    }
    
    // 计算缩放比例
    CGSize finalSize = [self calculateTargetSize:originalSize
                                    targetSize:targetSize
                           preserveAspectRatio:preserveAspectRatio];
    
    // 创建绘制上下文
    UIGraphicsBeginImageContextWithOptions(finalSize, NO, 0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    // 调整坐标系
    CGContextTranslateCTM(context, 0, finalSize.height);
    CGContextScaleCTM(context, 1, -1);
    
    // 计算缩放转换
    CGFloat scaleX = finalSize.width / originalSize.width;
    CGFloat scaleY = finalSize.height / originalSize.height;
    CGContextScaleCTM(context, scaleX, scaleY);
    
    // 绘制SVG
    SDCGContextDrawSVGDocument(context, document);
    
    // 获取结果图片
    UIImage *result = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    SDCGSVGDocumentRelease(document);
    return result;
}

- (UIImage *)convertSVGToVectorImage:(NSData *)svgData size:(CGSize)size {
    if (!svgData || ![SVGConverter supportsVectorSVG]) {
        return nil;
    }
    
    CGSVGDocumentRef document = SDCGSVGDocumentCreateFromData((__bridge CFDataRef)svgData, NULL);
    if (!document) {
        return nil;
    }
   
    UIImage *image;
#if TARGET_OS_IOS || TARGET_OS_WATCH
    if ([UIImage respondsToSelector:SDImageWithCGSVGDocumentSEL]) {
        image = ((UIImage *(*)(id,SEL,CGSVGDocumentRef))[UIImage.class methodForSelector:SDImageWithCGSVGDocumentSEL])(UIImage.class, SDImageWithCGSVGDocumentSEL, document);
    }
#endif
    
    SDCGSVGDocumentRelease(document);
    
    // 验证图像是否可以正常渲染
    @try {
        UIGraphicsBeginImageContextWithOptions(size, NO, 0);
        [image drawInRect:CGRectMake(0, 0, size.width, size.height)];
        UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        return newImage;
    } @catch (...) {
        return nil;
    }
    
    return image;
}

+ (BOOL)supportsVectorSVG {
    static dispatch_once_t onceToken;
    static BOOL supports;
    dispatch_once(&onceToken, ^{
#if TARGET_OS_IOS || TARGET_OS_WATCH
        supports = [UIImage respondsToSelector:SDImageWithCGSVGDocumentSEL];
#else
        supports = NO;
#endif
    });
    return supports;
}

#pragma mark - Helper Methods

- (CGSize)calculateTargetSize:(CGSize)originalSize
                  targetSize:(CGSize)targetSize
         preserveAspectRatio:(BOOL)preserveAspectRatio {
    // 如果没有指定目标大小,使用原始大小
    if (CGSizeEqualToSize(targetSize, CGSizeZero)) {
        return originalSize;
    }
    
    CGFloat scaleX = targetSize.width / originalSize.width;
    CGFloat scaleY = targetSize.height / originalSize.height;
    
    if (preserveAspectRatio) {
        // 保持宽高比
        if (targetSize.width <= 0) {
            scaleX = scaleY;
            targetSize.width = originalSize.width * scaleX;
        } else if (targetSize.height <= 0) {
            scaleY = scaleX;
            targetSize.height = originalSize.height * scaleY;
        } else {
            CGFloat scale = MIN(scaleX, scaleY);
            targetSize.width = originalSize.width * scale;
            targetSize.height = originalSize.height * scale;
        }
    } else {
        // 不保持宽高比
        if (targetSize.width <= 0) {
            targetSize.width = originalSize.width;
        }
        if (targetSize.height <= 0) {
            targetSize.height = originalSize.height;
        }
    }
    
    return targetSize;
}

@end
