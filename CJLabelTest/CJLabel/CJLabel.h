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
 *  增加点击链点
 *
 *  @param linkString 响应点击的字符串
 *  @param linkBlock  点击回调
 */
- (void)addLinkString:(NSAttributedString *)linkString block:(CJLinkLabelModelBlock)linkBlock;

/**
 *  取消点击链点
 *
 *  @param linkString 取消点击的字符串
 */
- (void)removeLinkString:(NSAttributedString *)linkString;
@end

/**
 *  点击链点model
 */
@interface CJLinkLabelModel : NSObject
@property (nonatomic, copy) CJLinkLabelModelBlock linkBlock;
@property (nonatomic, copy) NSAttributedString *linkString;
@property (nonatomic, assign) NSRange range;

- (instancetype)initLinkLabelModelWithString:(NSAttributedString *)linkString range:(NSRange)range block:(CJLinkLabelModelBlock)linkBlock;
@end