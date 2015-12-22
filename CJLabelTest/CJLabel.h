//
//  CJLabel.h
//  CJLabelTest
//
//  Created by C.K.Lian on 15/12/11.
//  Copyright © 2015年 C.K.Lian. All rights reserved.
//

#import <UIKit/UIKit.h>
typedef void (^CJLabelBlock)(void);

@interface CJLabel : UILabel
@property (nonatomic, copy)CJLabelBlock labelBlock;
@property (nonatomic, copy)NSAttributedString *linkString;
@property (nonatomic, copy)NSAttributedString *string;

/**
 *  return NSAttributedString height
 *
 *  @param string <#string description#>
 *  @param width  <#width description#>
 *
 *  @return height
 */
+ (CGFloat)getAttributedStringHeightWithString:(NSAttributedString *)string  width:(CGFloat)width;

/**
 *  return NSAttributedString Size
 *
 *  @param aString <#aString description#>
 *  @param width   <#width description#>
 *  @param height  <#height description#>
 *  @param font
 *
 *  @return <#return value description#>
 */
- (CGSize)getStringRect:(NSAttributedString *)aString width:(CGFloat)width height:(CGFloat)height labelFont:(UIFont *)font;

/**
 *  return NSMutableAttributedString
 *
 *  @param labelStr  label NSString
 *  @param labelDic  Attributes NSDictionary
 *
 *  @return NSMutableAttributedString
 */
+ (NSMutableAttributedString *)getLabelNSAttributedString:(NSString *)labelStr labelDict:(NSDictionary *)labelDic;

/**
 *  点击链接做处理（去除首字符）
 *
 *  @param linkString <#linkString description#>
 *
 *  @return <#return value description#>
 */
+ (NSAttributedString *)handleLinkString:(NSAttributedString *)linkString;

/**
 *  点击事件
 *
 *  @param linkString 点击链接对应字符
 *  @param string     文本
 *  @param labelBlock 点击回调block
 */
- (void)setTouchUpInsideLinkString:(NSAttributedString *)linkString withString:(NSAttributedString *)string block:(CJLabelBlock)labelBlock;
@end
