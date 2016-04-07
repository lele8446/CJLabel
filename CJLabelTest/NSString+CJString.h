//
//  NSString+CJString.h
//  CJLabelTest
//
//  Created by C.K.Lian on 16/4/5.
//  Copyright © 2016年 C.K.Lian. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

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
 *
 *  @return NSMutableAttributedString
 */
+ (NSMutableAttributedString *)getNSAttributedString:(NSString *)labelStr labelDict:(NSDictionary *)labelDic;

+ (CGFloat)getAttributedStringHeightWithString:(NSAttributedString *)string width:(CGFloat)width;
@end
