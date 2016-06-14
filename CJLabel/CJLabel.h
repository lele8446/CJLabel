//
//  CJLabel.h
//  CJLabelTest
//
//  Created by C.K.Lian on 15/12/11.
//  Copyright © 2015年 C.K.Lian. All rights reserved.
//

#import <UIKit/UIKit.h>
@class CJLinkLabelModel;
typedef void (^CJLinkLabelModelBlock)(CJLinkLabelModel *linkModel);

@interface CJLabel : UILabel
/**
 *  是否加大点击响应范围，类似于UIWebView的链点点击效果，默认NO
 */
@property (nonatomic, assign) IBInspectable BOOL extendsLinkTouchArea;

/**
 *  文本中内容相同的链点是否都能够响应点击，
 *  必须在设置self.attributedText前赋值，
 *  如果值为NO，则取文本中首次出现的链点，
 *  默认YES
 */
@property (nonatomic, assign) IBInspectable BOOL sameLinkEnable;

/**
 *  增加点击链点
 *
 *  @param linkString 响应点击的字符串
 *  @param linkDic    响应点击的字符串的Attribute值
 *  @param linkBlock  点击回调
 */
- (void)addLinkString:(NSString *)linkString linkAddAttribute:(NSDictionary *)linkDic block:(CJLinkLabelModelBlock)linkBlock;

/**
 *  增加点击链点
 *
 *  @param linkString 响应点击的字符串
 *  @param linkDic    响应点击的字符串的Attribute值
 *  @param parameter  响应点击的字符串的相关参数：id，色值，字体大小等
 *  @param linkBlock  点击回调
 */
- (void)addLinkString:(NSString *)linkString linkAddAttribute:(NSDictionary *)linkDic linkParameter:(id)parameter block:(CJLinkLabelModelBlock)linkBlock;

/**
 *  取消点击链点
 *
 *  @param linkString 取消点击的字符串
 */
- (void)removeLinkString:(NSString *)linkString;

/**
 *  移除所有点击链点
 */
- (void)removeAllLink;
@end

/**
 *  点击链点model
 */
@interface CJLinkLabelModel : NSObject
@property (nonatomic, copy) CJLinkLabelModelBlock linkBlock;
@property (nonatomic, copy) NSString *linkString;
@property (nonatomic, assign) NSRange range;
@property (nonatomic, strong) id parameter;//点击链点的相关参数：id，色值，字体大小等

- (instancetype)initLinkLabelModelWithString:(NSString *)linkString range:(NSRange)range linkParameter:(id)parameter block:(CJLinkLabelModelBlock)linkBlock;
@end