//
//  NSString+CJString.h
//  CJLabelTest
//
//  Created by C.K.Lian on 16/4/5.
//  Copyright © 2016年 C.K.Lian. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

static CGFloat const CJFLOAT_MAX = 100000;

@interface NSString (CJString)
/**
 *  返回UILabel自适应后的size
 *
 *  @param aString 字符串
 *  @param width   指定宽度
 *  @param height  指定高度
 *
 *  @return <#return value description#>
 */
+ (CGSize)sizeLabelToFit:(NSAttributedString *)aString width:(CGFloat)width height:(CGFloat)height;

/**
 *  return 动态返回字符串size大小
 *
 *  @param aString 字符串
 *  @param width   指定宽度
 *  @param height  指定宽度
 *
 *  @return <#return value description#>
 */
+ (CGSize)getStringRect:(NSAttributedString *)aString width:(CGFloat)width height:(CGFloat)height;

/**
 *  return 返回封装后的NSMutableAttributedString,添加了默认NSParagraphStyleAttributeName与NSFontAttributeName属性
 *
 *  @param labelStr  NSString
 *  @param labelDic  属性字典
 @{
 NSFontAttributeName://(字体)
 NSBackgroundColorAttributeName://(字体背景色)
 NSForegroundColorAttributeName://(字体颜色)
 NSParagraphStyleAttributeName://(段落)
 NSLigatureAttributeName://(连字符)
 NSKernAttributeName://(字间距)
 NSStrikethroughStyleAttributeName://NSUnderlinePatternSolid(实线) | NSUnderlineStyleSingle(删除线)
 NSUnderlineStyleAttributeName://(下划线)
 NSStrokeColorAttributeName://(边线颜色)
 NSStrokeWidthAttributeName://(边线宽度)
 NSShadowAttributeName://(阴影)
 NSVerticalGlyphFormAttributeName://(横竖排版)
 };
 *
 *  @return NSMutableAttributedString
 */
+ (NSMutableAttributedString *)getNSAttributedString:(NSString *)labelStr labelDict:(NSDictionary *)labelDic;
@end
