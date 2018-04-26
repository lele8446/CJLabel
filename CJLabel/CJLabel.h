//
//  CJLabel.h
//  CJLabelTest
//
//  Created by ChiJinLian on 17/3/31.
//  Copyright © 2017年 ChiJinLian. All rights reserved.
//
/*
  ____       _   _               _              _
 / ___|     | | | |       __ _  | |__     ___  | |
| |      _  | | | |      / _` | | '_ \   / _ \ | |
| |___  | |_| | | |___  | (_| | | |_) | |  __/ | |
 \____|  \___/  |_____|  \__,_| |_.__/   \___| |_|
 */

#import <UIKit/UIKit.h>
#import <CoreText/CoreText.h>
#import "CJLabelConfigure.h"

@class CJLabel;
@class CJLabelLinkModel;

@protocol CJLabelLinkDelegate <NSObject>
@optional
/**
 点击链点回调

 @param label     CJLabel
 @param linkModel 链点model
 */
- (void)CJLable:(CJLabel *)label didClickLink:(CJLabelLinkModel *)linkModel;

/**
 长按点击链点回调

 @param label     CJLabel
 @param linkModel 链点model
 */
- (void)CJLable:(CJLabel *)label didLongPressLink:(CJLabelLinkModel *)linkModel;
@end


/**
 * CJLabel 继承自 UILabel，支持富文本展示、图文混排、添加自定义点击链点以及选择复制等功能。
 *
 *
 * CJLabel 与 UILabel 不同点：
 *
     1. 禁止使用`-init`初始化！！
     2. `enableCopy` 长按或双击可唤起`UIMenuController`进行选择、全选、复制文本操作
     3. `attributedText` 与 `text` 均可设置富文本
     4. 不支持`NSAttachmentAttributeName`,`NSTextAttachment`！！显示自定义view请调用:
         `+ initWithView:viewSize:lineAlignment:configure:`或者
         `+ insertViewAtAttrString:view:viewSize:atIndex:lineAlignment:configure:`方法初始化`NSAttributedString`后显示
     5. `extendsLinkTouchArea`设置是否扩大链点点击识别范围
     6. `shadowRadius`设置文本阴影模糊半径
     7. `textInsets` 设置文本内边距
     8. `verticalAlignment` 设置垂直方向的文本对齐方式。
         注意与显示图片时候的`imagelineAlignment`作区分，`self.verticalAlignment`对应的是整体文本在垂直方向的对齐方式，而`imagelineAlignment`只对图片所在行的垂直对齐方式有效
     9. `delegate` 点击链点代理
     10. `kCJBackgroundFillColorAttributeName` 背景填充颜色，属性优先级低于`NSBackgroundColorAttributeName`,如果设置`NSBackgroundColorAttributeName`会忽略`kCJBackgroundFillColorAttributeName`的设置
     11. `kCJBackgroundStrokeColorAttributeName ` 背景边框线颜色
     12. `kCJBackgroundLineWidthAttributeName ` 背景边框线宽度
     13. `kCJBackgroundLineCornerRadiusAttributeName ` 背景边框线圆角弧度
     14. `kCJActiveBackgroundFillColorAttributeName ` 点击时候的背景填充颜色属性优先级同
         `kCJBackgroundFillColorAttributeName`
     15. `kCJActiveBackgroundStrokeColorAttributeName ` 点击时候的背景边框线颜色
     16. 支持添加自定义样式、可点击（长按）的文本点击链点
 *
 *
 * CJLabel 已知bug：
 *
   `numberOfLines`大于0且小于实际`label.numberOfLines`，同时`verticalAlignment`不等于`CJContentVerticalAlignmentTop`时:
    文本显示位置有偏差
 *
 */
@interface CJLabel : UILabel

/**
 * 指定初始化函数为 -initWithFrame: 或 -initWithCoder:
 * 直接调用 init 会忽略相关属性的设置，所以不能直接调用 init 初始化.
 */
- (instancetype)init NS_UNAVAILABLE;

/**
 * 对应UILabel的attributedText属性
 */
@property (readwrite, nonatomic, copy) NSAttributedString *attributedText;
/**
 * 对应UILabel的text属性
 */
@property (readwrite, nonatomic, copy) id text;
/**
 * 是否加大点击响应范围，类似于UIWebView的链点点击效果，默认NO
 */
@property (readwrite, nonatomic, assign) IBInspectable BOOL extendsLinkTouchArea;
/**
 * 阴影模糊半径，值为0表示没有模糊，值越大越模糊，该值不能为负， 默认值为0。
 * 可与 `shadowColor`、`shadowOffset` 配合设置
 */
@property (readwrite, nonatomic, assign) CGFloat shadowRadius;
/**
 * 绘制文本的内边距，默认UIEdgeInsetsZero
 */
@property (readwrite, nonatomic, assign) UIEdgeInsets textInsets;
/**
 * 当text rect 小于 label frame 时文本在垂直方向的对齐方式，默认 CJVerticalAlignmentCenter
 */
@property (readwrite, nonatomic, assign) CJLabelVerticalAlignment verticalAlignment;
/**
 点击链点代理对象
 */
@property (readwrite, nonatomic, weak) id<CJLabelLinkDelegate> delegate;
/**
 是否支持选择复制，默认NO
 */
@property (readwrite, nonatomic, assign) IBInspectable BOOL enableCopy;

/**
 设置`self.lineBreakMode`时候的自定义字符，默认值为"…"
 只针对`self.lineBreakMode`的以下三种值有效
 NSLineBreakByTruncatingHead,    // Truncate at head of line: "…wxyz"
 NSLineBreakByTruncatingTail,    // Truncate at tail of line: "abcd…"
 NSLineBreakByTruncatingMiddle   // Truncate middle of line:  "ab…yz"
 */
@property (readwrite, nonatomic, strong) NSAttributedString *attributedTruncationToken;

/**
 根据NSAttributedString计算CJLabel的size大小

 @param attributedString NSAttributedString字符串
 @param size             预计大小（比如：CGSizeMake(320, CGFLOAT_MAX)）
 @param numberOfLines    指定行数（0表示不限制）
 @return                 结果size
 */
+ (CGSize)sizeWithAttributedString:(NSAttributedString *)attributedString
                   withConstraints:(CGSize)size
            limitedToNumberOfLines:(NSUInteger)numberOfLines;


/**
 根据NSAttributedString计算CJLabel的size大小

 @param attributedString NSAttributedString字符串
 @param size             预计大小（比如：CGSizeMake(320, CGFLOAT_MAX)）
 @param numberOfLines    指定行数（0表示不限制）
 @param textInsets       CJLabel的内边距
 @return                 结果size
 */
+ (CGSize)sizeWithAttributedString:(NSAttributedString *)attributedString
                   withConstraints:(CGSize)size
            limitedToNumberOfLines:(NSUInteger)numberOfLines
                        textInsets:(UIEdgeInsets)textInsets;

/**
 初始化配置实例

 @param attributes           普通属性
 @param isLink               是否是点击链点
 @param activeLinkAttributes 点击高亮属性
 @param parameter            链点参数
 @param clickLinkBlock       链点点击block
 @param longPressBlock       链点长按block
 @return CJLabelConfigure实例
 */
+ (CJLabelConfigure *)configureAttributes:(NSDictionary<NSString *, id> *)attributes
                                   isLink:(BOOL)isLink
                     activeLinkAttributes:(NSDictionary<NSString *, id> *)activeLinkAttributes
                                parameter:(id)parameter
                           clickLinkBlock:(CJLabelLinkModelBlock)clickLinkBlock
                           longPressBlock:(CJLabelLinkModelBlock)longPressBlock;

/**
 根据图片名或UIImage初始化NSAttributedString
 （废弃原因：该方法显示图片只能是UIViewContentModeScaleToFill模式，而且不能更改）
 */
+ (NSMutableAttributedString *)initWithImage:(id)image
                                   imageSize:(CGSize)size
                          imagelineAlignment:(CJLabelVerticalAlignment)lineAlignment
                                   configure:(CJLabelConfigure *)configure __deprecated_msg("Use + initWithView:viewSize:lineAlignment:configure: instead");

/**
 根据自定义View初始化NSAttributedString

 @param view          需要插入的view（包括UIImage，NSString图片名称，UIView）
 @param size          view的显示区域大小
 @param lineAlignment 插入view所在行，与文字在垂直方向的对齐方式（只针对当前行）
 @param configure     链点配置
 @return              NSAttributedString
 */
+ (NSMutableAttributedString *)initWithView:(id)view
                                   viewSize:(CGSize)size
                              lineAlignment:(CJLabelVerticalAlignment)lineAlignment
                                  configure:(CJLabelConfigure *)configure;

/**
 在指定位置插入图片，并设置图片链点属性（已废弃，废弃原因：该方法显示图片只能是UIViewContentModeScaleToFill模式，而且不能更改）
 注意！！！插入图片， 如果设置 NSParagraphStyleAttributeName 属性，
 请保证 paragraph.lineBreakMode = NSLineBreakByCharWrapping，不然当Label的宽度不够显示内容或图片时，不会自动换行, 部分图片将会看不见
 默认 paragraph.lineBreakMode = NSLineBreakByCharWrapping
 */
+ (NSMutableAttributedString *)insertImageAtAttrString:(NSAttributedString *)attrStr
                                                 image:(id)image
                                             imageSize:(CGSize)size
                                               atIndex:(NSUInteger)loc
                                    imagelineAlignment:(CJLabelVerticalAlignment)lineAlignment
                                             configure:(CJLabelConfigure *)configure __deprecated_msg("Use + insertViewAtAttrString:view:viewSize:atIndex:imagelineAlignment:configure: instead");

/**
 在指定位置插入任意UIView

 注意！！！
 1、插入任意View， 如果设置 NSParagraphStyleAttributeName 属性，
    请保证 paragraph.lineBreakMode = NSLineBreakByCharWrapping，不然当Label的宽度不够显示内容或view时，不会自动换行, 部分view将会看不见
    默认 paragraph.lineBreakMode = NSLineBreakByCharWrapping
 2、插入任意View，如果 configure.isLink = YES，那么将优先响应CJLabel的点击响应
 
 @param attrStr       源字符串
 @param view          需要插入的view（包括UIImage，NSString图片名称，UIView）
 @param size          view的显示区域大小
 @param loc           插入位置
 @param lineAlignment 插入view所在行，与文字在垂直方向的对齐方式（只针对当前行）
 @param configure     链点配置
 @return              NSAttributedString
 */
+ (NSMutableAttributedString *)insertViewAtAttrString:(NSAttributedString *)attrStr
                                                 view:(id)view
                                             viewSize:(CGSize)size
                                              atIndex:(NSUInteger)loc
                                        lineAlignment:(CJLabelVerticalAlignment)lineAlignment
                                            configure:(CJLabelConfigure *)configure;

/**
 设置指定NSRange属性
 
 @param attrStr       需要设置的源NSAttributedString
 @param range         指定NSRange
 @param configure     链点配置
 @return              NSAttributedString
 */
+ (NSMutableAttributedString *)configureAttrString:(NSAttributedString *)attrStr
                                           atRange:(NSRange)range
                                         configure:(CJLabelConfigure *)configure;

/**
 根据NSString初始化NSAttributedString
 */
+ (NSMutableAttributedString *)initWithString:(NSString *)string configure:(CJLabelConfigure *)configure;


/**
 根据NSString初始化NSAttributedString

 @param string        指定的NSString
 @param strIdentifier 设置链点的唯一标识（用来区分不同的NSString，比如重名的 "@王小明" ,此时代表了不同的用户，不应该设置相同属性）
 @param configure     链点配置
 @return              NSAttributedString
 */
+ (NSMutableAttributedString *)initWithNSString:(NSString *)string
                                  strIdentifier:(NSString *)strIdentifier
                                      configure:(CJLabelConfigure *)configure;

/**
 对跟string相同的文本设置链点属性

 @param attrStr          需要设置的源NSAttributedString
 @param string           指定字符串
 @param configure        链点配置
 @param sameStringEnable 文本中所有与string相同的文本是否同步设置属性，sameStringEnable=NO 时取文本中首次匹配的NSAttributedString
 @return                 NSAttributedString
 */
+ (NSMutableAttributedString *)configureAttrString:(NSAttributedString *)attrStr
                                        withString:(NSString *)string
                                  sameStringEnable:(BOOL)sameStringEnable
                                         configure:(CJLabelConfigure *)configure;

/**
 根据NSAttributedString初始化NSAttributedString
 
 @param attributedString    指定的NSAttributedString
 @param configure           链点配置
 @param strIdentifier       设置链点的唯一标识（用来区分不同的NSAttributedString，比如重名的 "@王小明" ,此时代表了不同的用户，不应该设置相同属性）
 @return                    NSAttributedString
 */
+ (NSMutableAttributedString *)initWithAttributedString:(NSAttributedString *)attributedString
                                          strIdentifier:(NSString *)strIdentifier
                                              configure:(CJLabelConfigure *)configure;

/**
 对指定strIdentifier标识的attributedString设置链点属性，如果存在多个相同的文本，可以同时设置
 
 @param attrString          需要设置的源NSAttributedString
 @param attributedString    指定的NSAttributedString
 @param strIdentifier       设置链点的唯一标识（用来区分不同的NSAttributedString，比如重名的 "@王小明" ,此时代表了不同的用户，不应该设置相同属性）
 @param sameStringEnable    文本中相同的NSAttributedString是否同步设置属性，sameStringEnable=NO 时取文本中首次匹配的NSAttributedString
 @return                    NSAttributedString
 */
+ (NSMutableAttributedString *)configureAttrString:(NSAttributedString *)attrString
                              withAttributedString:(NSAttributedString *)attributedString
                                     strIdentifier:(NSString *)strIdentifier
                                  sameStringEnable:(BOOL)sameStringEnable
                                         configure:(CJLabelConfigure *)configure;

/**
 获取指定NSAttributedString中跟linkString相同的NSValue数组，NSValue值为对应的NSRange
 
 @param linkString 需要寻找的string
 @param attString 指定NSAttributedString
 @return NSRange的数组
 */
+ (NSArray <NSValue *>*)sameLinkStringRangeArray:(NSString *)linkString inAttString:(NSAttributedString *)attString;

/**
 获取指定NSAttributedString中跟linkAttString相同的NSRange数组，NSValue值为对应的NSRange
 
 @param linkAttString 需要寻找的NSAttributedString
 @param strIdentifier 链点标识
 @param attString 指定NSAttributedString
 @return NSRange的数组
 */
+ (NSArray <NSValue *>*)samelinkAttStringRangeArray:(NSAttributedString *)linkAttString strIdentifier:(NSString *)strIdentifier inAttString:(NSAttributedString *)attString;


/**
 *  移除指定range的点击链点
 *
 *  @param range 移除链点位置
 *
 *  @return 返回新的NSAttributedString
 */
- (NSAttributedString *)removeLinkAtRange:(NSRange)range;

/**
 *  移除所有点击链点
 *
 *  @return 返回新的NSAttributedString
 */
- (NSAttributedString *)removeAllLink;

/**
 刷新文本
 */
- (void)flushText;

@end


/**
 背景填充颜色。值为UIColor。默认 `nil`。
 该属性优先级低于NSBackgroundColorAttributeName，如果设置NSBackgroundColorAttributeName会覆盖kCJBackgroundFillColorAttributeName
 */
extern NSString * const kCJBackgroundFillColorAttributeName;

/**
 背景边框线颜色。值为UIColor。默认 `nil`
 */
extern NSString * const kCJBackgroundStrokeColorAttributeName;

/**
 背景边框线宽度。值为NSNumber。默认 `1.0f`
 */
extern NSString * const kCJBackgroundLineWidthAttributeName;

/**
 背景边框线圆角角度。值为NSNumber。默认 `5.0f`
 */
extern NSString * const kCJBackgroundLineCornerRadiusAttributeName;

/**
 点击时候的背景填充颜色。值为UIColor。默认 `nil`。
 该属性优先级低于NSBackgroundColorAttributeName，如果设置NSBackgroundColorAttributeName会覆盖kCJActiveBackgroundFillColorAttributeName
 */
extern NSString * const kCJActiveBackgroundFillColorAttributeName;

/**
 点击时候的背景边框线颜色。值为UIColor。默认 `nil`
 */
extern NSString * const kCJActiveBackgroundStrokeColorAttributeName;

/**
 删除线宽度。值为NSNumber。默认 `0.0f`，表示无删除线
 */
extern NSString * const kCJStrikethroughStyleAttributeName;

/**
 删除线颜色。值为UIColor。默认 `[UIColor blackColor]`。
 */
extern NSString * const kCJStrikethroughColorAttributeName;

/**
 对NSAttributedString文本设置链点属性时候的唯一标识
 */
extern NSString * const kCJLinkStringIdentifierAttributesName;
