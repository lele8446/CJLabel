//
//  CJLabel+UIMenu.h
//  CJLabelTest
//
//  Created by ChiJinLian on 2021/1/29.
//  Copyright © 2021 cjl. All rights reserved.
//

#import "CJLabel.h"

@interface CJLabel (UIMenu)
/**
 长按全选文本后弹出的UIMenu菜单（类似微信朋友圈全选复制功能）
 */
@property (nonatomic, strong, readonly) NSMutableArray <UIMenuItem *>*menuItems;
/**
长按全选文本的背景色
*/
@property (nonatomic, strong, readonly) UIColor *selectTextBackColor;

/// 长按全选文本后弹出自定义UIMenu菜单
/// @param menus 自定义UIMenu菜单
/// @param selectTextBackColor 全选文本背景色
/// @param colorAlpha 背景色透明度
/// @param clickMenuCompletion 点击自定义UIMenu菜单回调
- (void)showSelectAllTextWithMenus:(NSArray <NSString *>*)menus
               selectTextBackColor:(UIColor *)selectTextBackColor
                        colorAlpha:(CGFloat)colorAlpha
               clickMenuCompletion:(void (^)(NSString *menuTitle, CJLabel *label))clickMenuCompletion;
@end
