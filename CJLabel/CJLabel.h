//
//  CJLabel.h
//  CJLabelTest
//
//  Created by ChiJinLian on 17/3/31.
//  Copyright © 2017年 ChiJinLian. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreText/CoreText.h>

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
 当text bounds小于label bounds时，文本的垂直对齐方式
 */
typedef NS_ENUM(NSInteger, CJAttributedLabelVerticalAlignment) {
    CJContentVerticalAlignmentCenter   = 0,//垂直居中
    CJContentVerticalAlignmentTop      = 1,//居上
    CJContentVerticalAlignmentBottom   = 2,//靠下
};


/**
 链点回调block
 
 @param attributedString 链点富文本
 @param image 链点图片
 @param parameter 链点自定义参数
 @param range 链点文本在整体文本中的NSRange
 */
typedef void (^CJLabelLinkModelBlock)(NSAttributedString *attributedString, UIImage *image, id parameter, NSRange range);


IB_DESIGNABLE

/**
 * CJLabel 继承自 UILabel，其文本绘制基于NSAttributedString实现，同时增加了图文混排、富文本展示以及添加自定义点击链点并设置点击链点文本属性的功能。
 *
 *
 * CJLabel 与 UILabel 不同点：
 *
   1. `- init` 不可直接调用init初始化，请使用`initWithFrame:` 或 `initWithCoder:`，以便完成相关初始属性设置
 
   2. `attributedText` 与 `text` 均可设置文本，注意 [self setText:text]中 text类型只能是NSAttributedString或NSString
 
   3. `NSAttributedString`不再通过`NSTextAttachment`显示图片（使用`NSTextAttachment`不会起效），请调用
      `- configureAttributedString: addImageName: imageSize: atIndex: attributes:`或者
      `- configureLinkAttributedString: addImageName: imageSize: atIndex: linkAttributes: activeLinkAttributes: parameter: clickLinkBlock: longPressBlock:`方法添加图片
 
   4. 新增`extendsLinkTouchArea`， 设置是否加大点击响应范围，类似于UIWebView的链点点击效果
 
   5. 新增`shadowRadius`， 设置文本阴影模糊半径，可与 `shadowColor`、`shadowOffset` 配合设置，注意改设置将对全局文本起效
 
   6. 新增`textInsets` 设置文本内边距
 
   7. 新增`verticalAlignment` 设置垂直方向的文本对齐方式
 *
 *
 * CJLabel 已知bug：
 *
   `numberOfLines`大于0且小于实际`label.numberOfLines`，同时`verticalAlignment`不等于`CJContentVerticalAlignmentTop`时，文本显示位置有偏差
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
@property (readwrite, nonatomic, copy) IBInspectable NSAttributedString *attributedText;
/**
 * 对应UILabel的text属性
 */
@property (readwrite, nonatomic, copy) IBInspectable id text;
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
 * 当text rect 小于 label frame 时文本在垂直方向的对齐方式，默认 CJContentVerticalAlignmentCenter
 */
@property (readwrite, nonatomic, assign) CJAttributedLabelVerticalAlignment verticalAlignment;


/**
 *  return 计算NSAttributedString字符串的size大小
 *
 *  @param aString NSAttributedString字符串
 *  @param width   指定宽度
 *  @param height  指定宽度
 *
 *  @return 结果size
 */
+ (CGSize)getStringRect:(NSAttributedString *)aString width:(CGFloat)width height:(CGFloat)height;

/**
 在指定位置插入图片，并返回插入图片后的NSMutableAttributedString（图片占位符所占的NSRange={loc,1}）
 
 注意！！！插入图片， 如果设置 NSParagraphStyleAttributeName 属性，例如:
 NSMutableParagraphStyle *paragraph = [[NSMutableParagraphStyle alloc] init];
 paragraph.lineBreakMode = NSLineBreakByWordWrapping;
 [attrStr addAttribute:NSParagraphStyleAttributeName value:paragraph range:range];
 请保证 paragraph.lineBreakMode = NSLineBreakByWordWrapping，不然当Label的宽度不够显示内容或图片时，不会自动换行, 部分图片将会看不见
    
 默认 paragraph.lineBreakMode = NSLineBreakByWordWrapping
 
 @param attrStr 需要插入图片的NSAttributedString
 @param imageName 图片名称
 @param size 图片大小
 @param loc 图片插入位置
 @param attributes 图片文本属性
 
 @return 插入图片后的NSMutableAttributedString
 */
- (NSMutableAttributedString *)configureAttributedString:(NSAttributedString *)attrStr
                                            addImageName:(NSString *)imageName
                                               imageSize:(CGSize)size
                                                 atIndex:(NSUInteger)loc
                                              attributes:(NSDictionary *)attributes;

/**
 在指定位置插入图片，插入图片为可点击的链点！！！
 返回插入图片后的NSMutableAttributedString（图片占位符所占的NSRange={loc,1}）
 
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
- (NSMutableAttributedString *)configureLinkAttributedString:(NSAttributedString *)attrStr
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
- (NSMutableAttributedString *)configureAttributedString:(NSAttributedString *)attrStr
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
- (NSMutableAttributedString *)configureLinkAttributedString:(NSAttributedString *)attrStr
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
 @param sameStringEnable 文本中所有与withAttString相同的文字是否同步设置属性，sameStringEnable=NO 时取文本中首次匹配的NSAttributedString
 @param attributes 文本属性
 
 @return 返回新的NSMutableAttributedString
 */
- (NSMutableAttributedString *)configureAttributedString:(NSAttributedString *)attrStr
                                           withAttString:(NSAttributedString *)withAttString
                                        sameStringEnable:(BOOL)sameStringEnable
                                              attributes:(NSDictionary *)attributes;

/**
 对文本中跟withAttString相同的文字配置富文本，指定的文字为可点击链点！！！
 
 @param attrStr NSAttributedString源
 @param withAttString 需要设置的富文本
 @param sameStringEnable 文本中所有与withAttString相同的文字是否同步设置属性，sameStringEnable=NO 时取文本中首次匹配的NSAttributedString
 @param linkAttributes 链点文本属性
 @param activeLinkAttributes 点击状态下的链点文本属性
 @param parameter 链点自定义参数
 @param clickLinkBlock 链点点击回调
 @param longPressBlock 长按点击链点回调
 
 @return 返回新的NSMutableAttributedString
 */
- (NSMutableAttributedString *)configureLinkAttributedString:(NSAttributedString *)attrStr
                                               withAttString:(NSAttributedString *)withAttString
                                            sameStringEnable:(BOOL)sameStringEnable
                                              linkAttributes:(NSDictionary *)linkAttributes
                                        activeLinkAttributes:(NSDictionary *)activeLinkAttributes
                                                   parameter:(id)parameter
                                              clickLinkBlock:(CJLabelLinkModelBlock)clickLinkBlock
                                              longPressBlock:(CJLabelLinkModelBlock)longPressBlock;

/**
 *  移除制定range的点击链点
 *
 *  @param range 移除链点位置
 */
- (void)removeLinkAtRange:(NSRange)range;

/**
 *  移除所有点击链点
 */
- (void)removeAllLink;

@end






