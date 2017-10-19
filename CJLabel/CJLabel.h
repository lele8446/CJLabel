//
//  CJLabel.h
//  CJLabelTest
//
//  Created by ChiJinLian on 17/3/31.
//  Copyright © 2017年 ChiJinLian. All rights reserved.
//

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
 * CJLabel 继承自 UILabel，其文本绘制基于NSAttributedString实现，同时增加了图文混排、富文本展示以及添加自定义点击链点并设置点击链点文本属性的功能。
 *
 *
 * CJLabel 与 UILabel 不同点：
 *
   1. `- init` 不可直接调用init初始化，请使用`initWithFrame:` 或 `initWithCoder:`，以便完成相关初始属性设置
 
   2. `attributedText` 与 `text` 均可设置文本，注意 [self setText:text]中 text类型只能是NSAttributedString或NSString
 
   3. `NSAttributedString`不再通过`NSTextAttachment`显示图片（使用`NSTextAttachment`不会起效），请调用
      `+ initWithImageName:imageSize:imagelineAlignment:configure:`或者
      `+ insertImageAtAttrString:imageName:imageSize:imagelineAlignment:atIndex:configure:`方法添加图片
 
   4. 新增`extendsLinkTouchArea`， 设置是否加大点击响应范围，类似于UIWebView的链点点击效果
 
   5. 新增`shadowRadius`， 设置文本阴影模糊半径，可与 `shadowColor`、`shadowOffset` 配合设置，注意改设置将对全局文本起效
 
   6. 新增`textInsets` 设置文本内边距
 
   7. 新增`verticalAlignment` 设置垂直方向的文本对齐方式
 
   8. 新增`delegate` 点击链点代理
 *
 *
 * CJLabel 已知bug：
 *
   `numberOfLines`大于0且小于实际`label.numberOfLines`，同时`verticalAlignment`不等于`CJContentVerticalAlignmentTop`时:
    1.文本显示位置有偏差
    2.链点点击相应位置以及选择复制位置有偏差
    （！！！推荐解决方案：使用AutoLayout布局，或者手动设置frame时请确保self.frame与文本区域大小相等）
 *
 */
@interface CJLabel : UILabel

/**
 * 指定初始化函数为 initWithFrame: 或 initWithCoder:
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
 是否支持复制，默认NO
 */
@property (readwrite, nonatomic, assign) IBInspectable BOOL enableCopy;

/**
 计算NSAttributedString字符串的size大小

 @param attributedString NSAttributedString字符串
 @param size             预计大小（比如：CGSizeMake(320, CGFLOAT_MAX)）
 @param numberOfLines    指定行数（0表示不限制）
 @return                 结果size
 */
+ (CGSize)sizeWithAttributedString:(NSAttributedString *)attributedString
                   withConstraints:(CGSize)size
            limitedToNumberOfLines:(NSUInteger)numberOfLines;

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
 根据图片名初始化NSAttributedString

 @param image         图片名称，或者UIImage
 @param size          图片大小（这里是指显示图片等区域大小）
 @param lineAlignment 图片所在行，图片与文字在垂直方向的对齐方式（只针对当前行）
 @param configure     链点配置
 @return              NSAttributedString
 */
+ (NSMutableAttributedString *)initWithImage:(id)image
                                   imageSize:(CGSize)size
                          imagelineAlignment:(CJLabelVerticalAlignment)lineAlignment
                                   configure:(CJLabelConfigure *)configure;

/**
 在指定位置插入图片，并设置图片链点属性
 注意！！！插入图片， 如果设置 NSParagraphStyleAttributeName 属性，
 请保证 paragraph.lineBreakMode = NSLineBreakByCharWrapping，不然当Label的宽度不够显示内容或图片时，不会自动换行, 部分图片将会看不见
 默认 paragraph.lineBreakMode = NSLineBreakByCharWrapping
 */
+ (NSMutableAttributedString *)insertImageAtAttrString:(NSAttributedString *)attrStr
                                                 image:(id)image
                                             imageSize:(CGSize)size
                                               atIndex:(NSUInteger)loc
                                    imagelineAlignment:(CJLabelVerticalAlignment)lineAlignment
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
 对跟attributedString相同的文本设置链点属性
 
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
 获取指定NSAttributedString中跟linkString相同的NSRange数组
 
 @param linkString 需要寻找的string
 @param attString 指定NSAttributedString
 @return NSRange的数组
 */
+ (NSArray <NSString *>*)sameLinkStringRangeArray:(NSString *)linkString inAttString:(NSAttributedString *)attString;

/**
 获取指定NSAttributedString中跟linkAttString相同的NSRange数组
 
 @param linkAttString 需要寻找的NSAttributedString
 @param strIdentifier 链点标识
 @param attString 指定NSAttributedString
 @return NSRange的数组
 */
+ (NSArray <NSString *>*)samelinkAttStringRangeArray:(NSAttributedString *)linkAttString strIdentifier:(NSString *)strIdentifier inAttString:(NSAttributedString *)attString;


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
