//
//  CJLabel.h
//  CJLabelTest
//
//  Created by ChiJinLian on 17/3/31.
//  Copyright © 2017年 ChiJinLian. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreText/CoreText.h>
#import "CJLabelUtilities.h"

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


IB_DESIGNABLE

@interface CJLabel : UILabel

/**
 * 指定初始化函数为 initWithFrame: 与 initWithCoder:.
 * 直接调用 init 会忽略相关属性的设置，所以不能直接调用 init 初始化.
 */
- (instancetype)init NS_UNAVAILABLE;


/**
 * 对应UILabel的attributedText属性
 */
@property (readwrite, nonatomic, copy) NSAttributedString *attributedText;

/**
 * 是否加大点击响应范围，类似于UIWebView的链点点击效果，默认NO
 */
@property (nonatomic, assign) BOOL extendsLinkTouchArea;

/**
 * 阴影模糊半径，值为0表示没有模糊，值越大越模糊，该值不能为负， 默认值为0。
 */
@property (nonatomic, assign) IBInspectable CGFloat shadowRadius;


/**
 * 绘制文本的内边距，默认UIEdgeInsetsZero
 */
@property (nonatomic, assign) IBInspectable UIEdgeInsets textInsets;

/**
 * 当text rect 小于 label frame 时文本在垂直方向的对齐方式，默认 CJContentVerticalAlignmentCenter
 */
@property (nonatomic, assign) IBInspectable CJAttributedLabelVerticalAlignment verticalAlignment;


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
 在指定位置插入图片，插入图片为点击的链点！！！
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

@end





/**
 响应点击以及指定区域绘制边框线辅助类
 */
@interface CJGlyphRunStrokeItem : NSObject

@property (nonatomic, strong) UIColor *fillColor;//填充背景色
@property (nonatomic, strong) UIColor *strokeColor;//描边边框色
@property (nonatomic, strong) UIColor *activeFillColor;//点击选中时候的填充背景色
@property (nonatomic, strong) UIColor *activeStrokeColor;//点击选中时候的描边边框色
@property (nonatomic, assign) CGFloat lineWidth;//描边边框大小
@property (nonatomic, assign) CGFloat cornerRadius;//描边圆角
@property (nonatomic, assign) CGRect runBounds;//描边区域在系统坐标下的rect（原点在左下角）
@property (nonatomic, assign) CGRect locBounds;//描边区域在屏幕坐标下的rect（原点在左上角）
@property (nonatomic, strong) UIImage *image;//插入的图片
@property (nonatomic, assign) NSRange range;//链点在文本中的range
@property (nonatomic, strong) id parameter;//链点自定义参数
@property (nonatomic, copy) CJLabelLinkModelBlock linkBlock;//点击链点回调
@property (nonatomic, copy) CJLabelLinkModelBlock longPressBlock;//长按点击链点回调

//判断是否为点击链点
@property (nonatomic, assign) BOOL isLink;
//标记点击该链点是否需要重绘文本
@property (nonatomic, assign) BOOL needRedrawn;


@end
