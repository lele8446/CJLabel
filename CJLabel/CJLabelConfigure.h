//
//  CJLabelConfigure.h
//  CJLabelTest
//
//  Created by ChiJinLian on 2017/4/13.
//  Copyright © 2017年 ChiJinLian. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <CoreText/CoreText.h>
@class CJLabelLinkModel;

#define CJLabelIsNull(a) ((a)==nil || (a)==NULL || (NSNull *)(a)==[NSNull null])

typedef void (^CJLabelLinkModelBlock)(CJLabelLinkModel *linkModel);

/**
 当text bounds小于label bounds时，文本的垂直对齐方式
 */
typedef NS_ENUM(NSInteger, CJLabelVerticalAlignment) {
    CJVerticalAlignmentCenter   = 0,//垂直居中
    CJVerticalAlignmentTop      = 1,//居上
    CJVerticalAlignmentBottom   = 2,//靠下
};

/**
 当CTLine包含插入图片时，描述当前行文字在垂直方向的对齐方式
 */
struct CJCTLineVerticalLayout {
    CFIndex line;//第几行
    CGFloat maxRunHeight;//当前行run的最大高度（不包括图片）
    CGFloat lineHeight;//行高
    CGFloat maxImageHeight;//图片等最大高度
    CGRect  lineRect;//当前行对应的CGRect
    CJLabelVerticalAlignment verticalAlignment;//对齐方式（默认底部对齐）
};
typedef struct CJCTLineVerticalLayout CJCTLineVerticalLayout;

/**
 设置链点属性辅助类，可设置链点正常属性、点击高亮属性、链点自定义参数、点击回调以及长按回调
 */
@interface CJLabelConfigure : NSObject
/**
 设置链点的自定义属性
 */
@property (nonatomic, strong) NSDictionary<NSAttributedStringKey, id> *attributes;
/**
 是否为可点击链点，设置 isLink=YES 时，activeLinkAttributes、parameter、clickLinkBlock、longPressBlock才有效
 */
@property (nonatomic, assign) BOOL isLink;
/**
 设置链点点击高亮时候的自定义属性
 */
@property (nonatomic, strong) NSDictionary<NSAttributedStringKey, id> *activeLinkAttributes;
/**
 点击链点的自定义参数
 */
@property (nonatomic, strong) id parameter;
/**
 点击链点回调block
 */
@property (nonatomic, copy) CJLabelLinkModelBlock clickLinkBlock;
/**
 长按链点的回调block
 */
@property (nonatomic, copy) CJLabelLinkModelBlock longPressBlock;

/**
 初始化配置
 */
+ (instancetype)configureAttributes:(NSDictionary<NSAttributedStringKey, id> *)attributes
                             isLink:(BOOL)isLink
               activeLinkAttributes:(NSDictionary<NSAttributedStringKey, id> *)activeLinkAttributes
                          parameter:(id)parameter
                     clickLinkBlock:(CJLabelLinkModelBlock)clickLinkBlock
                     longPressBlock:(CJLabelLinkModelBlock)longPressBlock;

/**
 在指定位置插入图片链点！！！
 */
+ (NSMutableAttributedString *)configureLinkAttributedString:(NSAttributedString *)attrStr
                                                addImageName:(NSString *)imageName
                                                   imageSize:(CGSize)size
                                                     atIndex:(NSUInteger)loc
                                           verticalAlignment:(CJLabelVerticalAlignment)verticalAlignment
                                              linkAttributes:(NSDictionary *)linkAttributes
                                        activeLinkAttributes:(NSDictionary *)activeLinkAttributes
                                                   parameter:(id)parameter
                                              clickLinkBlock:(CJLabelLinkModelBlock)clickLinkBlock
                                              longPressBlock:(CJLabelLinkModelBlock)longPressBlock
                                                      islink:(BOOL)isLink;

/**
 根据指定NSRange配置富文本链点！！！
 */
+ (NSMutableAttributedString *)configureLinkAttributedString:(NSAttributedString *)attrStr
                                                     atRange:(NSRange)range
                                              linkAttributes:(NSDictionary *)linkAttributes
                                        activeLinkAttributes:(NSDictionary *)activeLinkAttributes
                                                   parameter:(id)parameter
                                              clickLinkBlock:(CJLabelLinkModelBlock)clickLinkBlock
                                              longPressBlock:(CJLabelLinkModelBlock)longPressBlock
                                                      islink:(BOOL)isLink;


/**
 对文本中跟withString相同的文字配置富文本链点！！！
 */
+ (NSMutableAttributedString *)configureLinkAttributedString:(NSAttributedString *)attrStr
                                                  withString:(NSString *)withString
                                            sameStringEnable:(BOOL)sameStringEnable
                                              linkAttributes:(NSDictionary *)linkAttributes
                                        activeLinkAttributes:(NSDictionary *)activeLinkAttributes
                                                   parameter:(id)parameter
                                              clickLinkBlock:(CJLabelLinkModelBlock)clickLinkBlock
                                              longPressBlock:(CJLabelLinkModelBlock)longPressBlock
                                                      islink:(BOOL)isLink;

/**
 对文本中跟withAttString相同的富文本链点！！！
 */
+ (NSMutableAttributedString *)configureLinkAttributedString:(NSAttributedString *)attrStr
                                               withAttString:(NSAttributedString *)withAttString
                                            sameStringEnable:(BOOL)sameStringEnable
                                              linkAttributes:(NSDictionary *)linkAttributes
                                        activeLinkAttributes:(NSDictionary *)activeLinkAttributes
                                                   parameter:(id)parameter
                                              clickLinkBlock:(CJLabelLinkModelBlock)clickLinkBlock
                                              longPressBlock:(CJLabelLinkModelBlock)longPressBlock
                                                      islink:(BOOL)isLink;

/**
 生成string链点的NSAttributedString（请保证identifier的唯一性！！！）
 
 @param string 点击链点的string
 @param attrs 链点属性
 @param identifier 点击链点的唯一标识
 @return 返回点击链点的NSMutableAttributedString
 */
+ (NSMutableAttributedString *)linkAttStr:(NSString *)string
                               attributes:(NSDictionary <NSString *,id>*)attrs
                               identifier:(NSString *)identifier;

+ (NSArray <NSString *>*)getLinkStringRangeArray:(NSString *)linkString inAttString:(NSAttributedString *)attString;
+ (NSArray <NSString *>*)getLinkAttStringRangeArray:(NSAttributedString *)linkAttString inAttString:(NSAttributedString *)attString;

@end

/**
 点击链点model
 */
@interface CJLabelLinkModel : NSObject
/**
 链点文本
 */
@property (readonly, nonatomic, strong) NSAttributedString *attributedString;
/**
 链点自定义参数
 */
@property (readonly, nonatomic, strong) id parameter;
/**
 链点在整体文本中的range值
 */
@property (readonly, nonatomic, assign) NSRange linkRange;
/**
 链点图片Rect（相对于CJLabel坐标的rect)
 */
@property (readonly, nonatomic, assign) CGRect imageRect;
/**
 链点图片名称
 */
@property (readonly, nonatomic, copy) NSString *imageName;

- (instancetype)initWithAttributedString:(NSAttributedString *)attributedString
                               imageName:(NSString *)imageName
                               imageRect:(CGRect )imageRect
                               parameter:(id)parameter
                               linkRange:(NSRange)linkRange;
@end

/**
 响应点击以及指定区域绘制边框线辅助类
 */
@interface CJGlyphRunStrokeItem : NSObject

@property (nonatomic, strong) UIColor *fillCopyColor;//支持复制时选中字符的填充背景色
@property (nonatomic, strong) UIColor *fillColor;//填充背景色
@property (nonatomic, strong) UIColor *strokeColor;//描边边框色
@property (nonatomic, strong) UIColor *activeFillColor;//点击选中时候的填充背景色
@property (nonatomic, strong) UIColor *activeStrokeColor;//点击选中时候的描边边框色
@property (nonatomic, assign) CGFloat lineWidth;//描边边框粗细
@property (nonatomic, assign) CGFloat cornerRadius;//描边圆角
@property (nonatomic, assign) CGRect runBounds;//描边区域在系统坐标下的rect（原点在左下角）
@property (nonatomic, assign) CGRect locBounds;//描边区域在屏幕坐标下的rect（原点在左上角）
@property (nonatomic, copy) NSString *imageName;//插入图片名称
@property (nonatomic, assign) BOOL isImage;//插入图片
@property (nonatomic, assign) NSRange range;//链点在文本中的range
@property (nonatomic, strong) id parameter;//链点自定义参数
@property (nonatomic, assign) CJCTLineVerticalLayout lineVerticalLayout;//所在CTLine的信息结构体
@property (nonatomic, assign) BOOL isSelect;//是否被选中复制
@property (nonatomic, copy) CJLabelLinkModelBlock linkBlock;//点击链点回调
@property (nonatomic, copy) CJLabelLinkModelBlock longPressBlock;//长按点击链点回调


//判断是否为点击链点
@property (nonatomic, assign) BOOL isLink;
//标记点击该链点是否需要重绘文本
@property (nonatomic, assign) BOOL needRedrawn;


@end

extern NSString * const kCJImageAttributeName;
extern NSString * const kCJImageName;
extern NSString * const kCJImageHeight;
extern NSString * const kCJImageWidth;
extern NSString * const kCJImageLineVerticalAlignment;

extern NSString * const kCJLinkStringKeyAttributesName;

extern NSString * const kCJLinkAttributesName;
extern NSString * const kCJActiveLinkAttributesName;
extern NSString * const kCJIsLinkAttributesName;
extern NSString * const kCJLinkRangeAttributesName;
extern NSString * const kCJLinkParameterAttributesName;
extern NSString * const kCJClickLinkBlockAttributesName;
extern NSString * const kCJLongPressBlockAttributesName;
extern NSString * const kCJLinkNeedRedrawnAttributesName;

static CGFloat const CJFLOAT_MAX = 100000;

static inline CGFLOAT_TYPE CGFloat_ceil(CGFLOAT_TYPE cgfloat) {
#if CGFLOAT_IS_DOUBLE
    return ceil(cgfloat);
#else
    return ceilf(cgfloat);
#endif
}

static inline CGFLOAT_TYPE CGFloat_floor(CGFLOAT_TYPE cgfloat) {
#if CGFLOAT_IS_DOUBLE
    return floor(cgfloat);
#else
    return floorf(cgfloat);
#endif
}

static inline CGFloat CJFlushFactorForTextAlignment(NSTextAlignment textAlignment) {
    switch (textAlignment) {
        case NSTextAlignmentCenter:
            return 0.5f;
        case NSTextAlignmentRight:
            return 1.0f;
        case NSTextAlignmentLeft:
        default:
            return 0.0f;
    }
}

static inline CGColorRef CGColorRefFromColor(id color) {
    return [color isKindOfClass:[UIColor class]] ? [color CGColor] : (__bridge CGColorRef)color;
}

static inline NSAttributedString * NSAttributedStringByScalingFontSize(NSAttributedString *attributedString, CGFloat scale) {
    NSMutableAttributedString *mutableAttributedString = [attributedString mutableCopy];
    [mutableAttributedString enumerateAttribute:(NSString *)kCTFontAttributeName inRange:NSMakeRange(0, [mutableAttributedString length]) options:0 usingBlock:^(id value, NSRange range, BOOL * __unused stop) {
        UIFont *font = (UIFont *)value;
        if (font) {
            NSString *fontName;
            CGFloat pointSize;
            
            if ([font isKindOfClass:[UIFont class]]) {
                fontName = font.fontName;
                pointSize = font.pointSize;
            } else {
                fontName = (NSString *)CFBridgingRelease(CTFontCopyName((__bridge CTFontRef)font, kCTFontPostScriptNameKey));
                pointSize = CTFontGetSize((__bridge CTFontRef)font);
            }
            
            [mutableAttributedString removeAttribute:(NSString *)kCTFontAttributeName range:range];
            CTFontRef fontRef = CTFontCreateWithName((__bridge CFStringRef)fontName, CGFloat_floor(pointSize * scale), NULL);
            [mutableAttributedString addAttribute:(NSString *)kCTFontAttributeName value:(__bridge id)fontRef range:range];
            CFRelease(fontRef);
        }
    }];
    
    return mutableAttributedString;
}

static inline CGSize CTFramesetterSuggestFrameSizeForAttributedStringWithConstraints(CTFramesetterRef framesetter, NSAttributedString *attributedString, CGSize size, NSUInteger numberOfLines) {
    CFRange rangeToSize = CFRangeMake(0, (CFIndex)[attributedString length]);
    CGSize constraints = CGSizeMake(size.width, CJFLOAT_MAX);
    
    if (numberOfLines == 1) {
        constraints = CGSizeMake(CJFLOAT_MAX, CJFLOAT_MAX);
    } else if (numberOfLines > 0) {
        CGMutablePathRef path = CGPathCreateMutable();
        CGPathAddRect(path, NULL, CGRectMake(0.0f, 0.0f, constraints.width, CJFLOAT_MAX));
        CTFrameRef frame = CTFramesetterCreateFrame(framesetter, CFRangeMake(0, 0), path, NULL);
        CFArrayRef lines = CTFrameGetLines(frame);
        
        if (CFArrayGetCount(lines) > 0) {
            NSInteger lastVisibleLineIndex = MIN((CFIndex)numberOfLines, CFArrayGetCount(lines)) - 1;
            CTLineRef lastVisibleLine = CFArrayGetValueAtIndex(lines, lastVisibleLineIndex);
            
            CFRange rangeToLayout = CTLineGetStringRange(lastVisibleLine);
            rangeToSize = CFRangeMake(0, rangeToLayout.location + rangeToLayout.length);
        }
        
        CFRelease(frame);
        CGPathRelease(path);
    }
    
    CGSize suggestedSize = CTFramesetterSuggestFrameSizeWithConstraints(framesetter, rangeToSize, NULL, constraints, NULL);
    
    return CGSizeMake(CGFloat_ceil(suggestedSize.width), CGFloat_ceil(suggestedSize.height));
};

static inline CGFloat compareMaxNum(CGFloat firstNum, CGFloat secondNum, BOOL max){
    CGFloat result = firstNum;
    if (max) {
        result = (firstNum >= secondNum)?firstNum:secondNum;
    }else{
        result = (firstNum <= secondNum)?firstNum:secondNum;
    }
    return result;
}

static inline UIColor * colorWithAttributeName(NSDictionary *dic, NSString *key){
    UIColor *color = nil;
    if (dic[key] && nil != dic[key]) {
        color = dic[key];
    }
    return color;
}

static inline BOOL isNotClearColor(UIColor *color){
    if (CJLabelIsNull(color)) {
        return NO;
    }
    BOOL notClearColor = YES;
    if (CGColorEqualToColor(color.CGColor, [UIColor clearColor].CGColor)) {
        notClearColor = NO;
    }
    return notClearColor;
}

static inline BOOL isSameColor(UIColor *color1, UIColor *color2){
    BOOL same = YES;
    if (!CGColorEqualToColor(color1.CGColor, color2.CGColor)) {
        same = NO;
    }
    return same;
}


