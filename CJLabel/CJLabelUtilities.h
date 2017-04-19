//
//  CJLabelUtilities.h
//  CJLabelTest
//
//  Created by ChiJinLian on 2017/4/13.
//  Copyright © 2017年 ChiJinLian. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <CoreText/CoreText.h>

#define CJLabelIsNull(a) ((a)==nil || (a)==NULL || (NSNull *)(a)==[NSNull null])

extern NSString * const kCJImageAttributeName;
extern NSString * const kCJLinkAttributesName;
extern NSString * const kCJActiveLinkAttributesName;
extern NSString * const kCJIsLinkAttributesName;
extern NSString * const kCJLinkRangeAttributesName;
extern NSString * const kCJLinkParameterAttributesName;
extern NSString * const kCJClickLinkBlockAttributesName;
extern NSString * const kCJLongPressBlockAttributesName;

extern NSString * const kCJLinkNeedRedrawnAttributesName;


/**
 链点回调block
 
 @param attributedString 链点富文本
 @param image 链点图片
 @param parameter 链点自定义参数
 @param range 链点文本在整体文本中的NSRange
 */
typedef void (^CJLabelLinkModelBlock)(NSAttributedString *attributedString, UIImage *image, id parameter, NSRange range);


/**
 CJLabel工具类，提供NSMutableAttributedString封装方法
 */
@interface CJLabelUtilities : NSObject

+ (NSRange)getFirstRangeWithAttString:(NSAttributedString *)withAttString inAttString:(NSAttributedString *)attString;
+ (NSArray <NSString *>*)getRangeArrayWithAttString:(NSAttributedString *)withAttString inAttString:(NSAttributedString *)attString;


/**
 在指定位置插入图片，并返回插入图片后的NSMutableAttributedString（图片占位符所占的NSRange，length=1）
 
 @param attrStr 需要插入图片的NSAttributedString
 @param imageName 图片名称
 @param size 图片大小
 @param loc 图片插入位置
 @param attributes 图片文本属性
 
 @return 插入图片后的NSMutableAttributedString
 */
+ (NSMutableAttributedString *)configureAttributedString:(NSAttributedString *)attrStr
                                            addImageName:(NSString *)imageName
                                               imageSize:(CGSize)size
                                                 atIndex:(NSUInteger)loc
                                              attributes:(NSDictionary *)attributes;

/**
 在指定位置插入图片，图片是点击的链点！！！
 
 @param attrStr 需要插入图片的NSAttributedString
 @param imageName 图片名称
 @param size 图片大小
 @param loc 图片插入位置
 @param linkAttributes 图片链点属性
 @param activeLinkAttributes 点击状态下的图片链点属性
 @param parameter 链点自定义参数
 @param clickLinkBlock 链点点击回调
 @param longPressBlock 长按点击链点回调
 
 @return 插入图片后的NSMutableAttributedString
 */
+ (NSMutableAttributedString *)configureLinkAttributedString:(NSAttributedString *)attrStr
                                                addImageName:(NSString *)imageName
                                                   imageSize:(CGSize)size
                                                     atIndex:(NSUInteger)loc
                                              linkAttributes:(NSDictionary *)linkAttributes
                                        activeLinkAttributes:(NSDictionary *)activeLinkAttributes
                                                   parameter:(id)parameter
                                              clickLinkBlock:(CJLabelLinkModelBlock)clickLinkBlock
                                              longPressBlock:(CJLabelLinkModelBlock)longPressBlock;

/**
 根据指定NSRange配置富文本
 
 @param attrStr NSAttributedString源
 @param range 指定NSRange
 @param attributes 文本属性
 
 @return 返回新的NSMutableAttributedString
 */
+ (NSMutableAttributedString *)configureAttributedString:(NSAttributedString *)attrStr
                                                 atRange:(NSRange)range
                                              attributes:(NSDictionary *)attributes;

/**
 根据指定NSRange配置富文本，指定NSRange文本为可点击链点！！！
 
 @param attrStr NSAttributedString源
 @param range 指定NSRange
 @param linkAttributes 链点文本属性
 @param activeLinkAttributes 点击状态下的链点文本属性
 @param parameter 链点自定义参数
 @param clickLinkBlock 链点点击回调
 @param longPressBlock 长按点击链点回调
 
 @return 返回新的NSMutableAttributedString
 */
+ (NSMutableAttributedString *)configureLinkAttributedString:(NSAttributedString *)attrStr
                                                     atRange:(NSRange)range
                                              linkAttributes:(NSDictionary *)linkAttributes
                                        activeLinkAttributes:(NSDictionary *)activeLinkAttributes
                                                   parameter:(id)parameter
                                              clickLinkBlock:(CJLabelLinkModelBlock)clickLinkBlock
                                              longPressBlock:(CJLabelLinkModelBlock)longPressBlock;

/**
 对文本中跟withAttString相同的文字配置富文本
 
 @param attrStr NSAttributedString源
 @param withAttString 需要设置的富文本
 @param sameStringEnable 文本中所有与withAttString的文字是否同步设置属性，sameStringEnable=NO 时取文本中首次匹配的String
 @param attributes 文本属性
 
 @return 返回新的NSMutableAttributedString
 */
+ (NSMutableAttributedString *)configureAttributedString:(NSAttributedString *)attrStr
                                           withAttString:(NSAttributedString *)withAttString
                                        sameStringEnable:(BOOL)sameStringEnable
                                              attributes:(NSDictionary *)attributes;

/**
 对文本中跟withAttString相同的文字配置富文本，指定的文字为可点击链点！！！
 
 @param attrStr NSAttributedString源
 @param withAttString 需要设置的富文本
 @param sameStringEnable 文本中所有与withAttString的文字是否同步设置属性，sameStringEnable=NO 时取文本中首次匹配的String
 @param linkAttributes 链点文本属性
 @param activeLinkAttributes 点击状态下的链点文本属性
 @param parameter 链点自定义参数
 @param clickLinkBlock 链点点击回调
 @param longPressBlock 长按点击链点回调
 
 @return 返回新的NSMutableAttributedString
 */
+ (NSMutableAttributedString *)configureLinkAttributedString:(NSAttributedString *)attrStr
                                               withAttString:(NSAttributedString *)withAttString
                                            sameStringEnable:(BOOL)sameStringEnable
                                              linkAttributes:(NSDictionary *)linkAttributes
                                        activeLinkAttributes:(NSDictionary *)activeLinkAttributes
                                                   parameter:(id)parameter
                                              clickLinkBlock:(CJLabelLinkModelBlock)clickLinkBlock
                                              longPressBlock:(CJLabelLinkModelBlock)longPressBlock;

@end
