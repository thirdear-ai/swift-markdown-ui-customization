//
//  SVGConverter.h
//
//  Created by tanghai on 2018/9/27.
//

/***
SDImageSVGCoder is a SVG image coder, which use the built-in UIKit/AppKit method to decode SVG images. The SVG was implemented in iOS 13/macOS 10.15 with Symbol Image format, which is subset of SVG 1.1 or SVG 2 spec. If you find your SVG ccould not rendered correctly, please convert it by checking https://developer.apple.com/documentation/xcode/creating_custom_symbol_images_for_your_app
**/

#import "UIKit/UIKit.h"

NS_ASSUME_NONNULL_BEGIN

@interface SVGConverter : NSObject

+ (instancetype)sharedConverter;

// 检查数据是否为SVG格式
+ (BOOL)isSVGFormatForData:(NSData *)data;

// 将SVG数据转换为UIImage
- (nullable UIImage *)convertSVGToImage:(NSData *)svgData
                            targetSize:(CGSize)targetSize
                  preserveAspectRatio:(BOOL)preserveAspectRatio;

// 将SVG数据转换为矢量图像(仅支持iOS 13+)
- (nullable UIImage *)convertSVGToVectorImage:(NSData *)svgData size:(CGSize)size;

// 检查是否支持矢量SVG图像
+ (BOOL)supportsVectorSVG;

@end

NS_ASSUME_NONNULL_END
