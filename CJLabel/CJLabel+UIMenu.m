//
//  CJLabel+UIMenu.m
//  CJLabelTest
//
//  Created by ChiJinLian on 2021/1/29.
//  Copyright © 2021 cjl. All rights reserved.
//

#import "CJLabel+UIMenu.h"
#import <objc/runtime.h>

#define UIMenuSELPrefix     @"CJLabel_Menu_"

@interface CJLabel ()
@property (nonatomic, strong) UIColor *selectTextBackColor;
@property (nonatomic, strong) NSMutableArray *menuItems;
@property (nonatomic, copy) void(^clickMenuCompletion)(NSString *menuTitle, CJLabel *label);
@end

@interface SelectMenuForwardingTarget : NSObject
@end
@implementation SelectMenuForwardingTarget

- (void)forwardingSelector:(NSString *)selectorName label:(CJLabel *)label {
    NSString *menuTitle = [selectorName stringByReplacingOccurrencesOfString:UIMenuSELPrefix withString:@""];
    if (label.clickMenuCompletion) {
        label.clickMenuCompletion(menuTitle, label);
    }
}
+ (BOOL)resolveInstanceMethod:(SEL)sel {
    NSString *selectorName = NSStringFromSelector(sel);
    if ([selectorName hasPrefix:UIMenuSELPrefix]) {
        class_addMethod([self class], sel, imp_implementationWithBlock(^(id self, NSString *str) {
//            NSLog(@"imp block, sel = %@", selectorName);
        }), "v@");
    }
    return [super resolveInstanceMethod:sel];
}
@end


@implementation CJLabel (UIMenu)

static char selectTextBackColorKey;
- (void)setSelectTextBackColor:(UIColor *)selectTextBackColor {
    objc_setAssociatedObject(self, &selectTextBackColorKey, selectTextBackColor, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
- (UIColor *)selectTextBackColor {
    UIColor *color = objc_getAssociatedObject(self, &selectTextBackColorKey);
    if (!color) {
        color = CJUIRGBColor(0,84,166,0.2);
    }
    return color;
}

static char menuItemsKey;
- (void)setMenuItems:(NSMutableArray *)menuItems {
    objc_setAssociatedObject(self, &menuItemsKey, menuItems, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
- (NSMutableArray *)menuItems {
    return objc_getAssociatedObject(self, &menuItemsKey);
}

static char clickMenuCompletionKey;
- (void)setClickMenuCompletion:(void (^)(NSString *, CJLabel *))clickMenuCompletion {
    objc_setAssociatedObject(self, &clickMenuCompletionKey, clickMenuCompletion, OBJC_ASSOCIATION_COPY_NONATOMIC);
}
- (void (^)(NSString *, CJLabel *))clickMenuCompletion {
    return objc_getAssociatedObject(self, &clickMenuCompletionKey);
}

- (void)showSelectAllTextWithMenus:(NSArray <NSString *>*)menus selectTextBackColor:(UIColor *)selectTextBackColor colorAlpha:(CGFloat)colorAlpha clickMenuCompletion:(void (^)(NSString *menuTitle, CJLabel *label))clickMenuCompletion {
    self.enableCopy = NO;
    self.clickMenuCompletion = clickMenuCompletion;
    
    if (colorAlpha == 0) {
        colorAlpha = 0.2;
    }
    self.selectTextBackColor = [selectTextBackColor colorWithAlphaComponent:colorAlpha];
    NSMutableArray *menuItems = [NSMutableArray array];
    for (NSString *str in menus) {
        NSString *selectorName = [NSString stringWithFormat:@"%@%@",UIMenuSELPrefix,str];
        UIMenuItem *menuItem = [[UIMenuItem alloc] initWithTitle:str action: NSSelectorFromString(selectorName)];
        [menuItems addObject:menuItem];
    }
    self.menuItems = menuItems;
}

#pragma mark - UIResponder
- (BOOL)canBecomeFirstResponder {
    return YES;
}

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender {
    // 需要有文字才能支持选择复制
    if (self.attributedText || self.text) {
        NSString *selectorName = NSStringFromSelector(action);
        if ([selectorName hasPrefix:UIMenuSELPrefix]) {
            return YES;
        }
    }
    return [super canPerformAction:action withSender:sender];
}

- (id)forwardingTargetForSelector:(SEL)aSelector {
    NSString *selectorName = NSStringFromSelector(aSelector);
    if ([selectorName hasPrefix:UIMenuSELPrefix]) {
        SelectMenuForwardingTarget *target = [SelectMenuForwardingTarget new];
        __weak typeof(self)wSelf = self;
        [target forwardingSelector:selectorName label:wSelf];
        return target;
    }
    else{
        return [super forwardingTargetForSelector:aSelector];
    }
}

- (void)menuItemClick {
    [self hideMenuItems];
}

- (void)hideMenuItems {
    if (self.menuItems.count > 0) {
        NSMutableArray *newMenuItems = [NSMutableArray array];
        NSArray *customMenuTitle = [self.menuItems valueForKeyPath:@"title"];
        for (UIMenuItem *menuItem in [UIMenuController sharedMenuController].menuItems) {
            if (![customMenuTitle containsObject:menuItem.title]) {
                [newMenuItems addObject:menuItem];
            }
        }
        [UIMenuController sharedMenuController].menuItems = newMenuItems;
    }
    UIView *allTextSelectBackView = [self viewWithTag:[@"allTextSelectBackView" hash]];
    [allTextSelectBackView removeFromSuperview];
    allTextSelectBackView = nil;
}
@end
