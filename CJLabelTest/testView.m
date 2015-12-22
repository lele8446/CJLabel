//
//  testView.m
//  CJLabelTest
//
//  Created by C.K.Lian on 15/12/22.
//  Copyright © 2015年 C.K.Lian. All rights reserved.
//

#import "testView.h"

@implementation testView

- (instancetype)init
{
    self = [[NSBundle mainBundle] loadNibNamed:[self.class description] owner:self options:nil][0];
    
    NSDictionary *dic = @{
                          NSFontAttributeName:[UIFont systemFontOfSize:20],/*(字体)*/
                          NSForegroundColorAttributeName:[UIColor blackColor],/*(字体颜色)*/
                          };
    //设置label text
    self.labelTitle = [CJLabel getLabelNSAttributedString:@"链接链接链接链接链接链接链接链接链接#www.baidu.com#链接链接链接链接" labelDict:dic];
    
    //设置点击link属性
    NSAttributedString *title2 = [CJLabel getLabelNSAttributedString:@"#www.baidu.com#" labelDict:dic];
    NSAttributedString *linkTitle = [CJLabel handleLinkString:title2];
    
    [_labelTitle addAttribute:NSForegroundColorAttributeName value:[UIColor colorWithRed:0.9873 green:0.1617 blue:0.1402 alpha:1.0] range:[[_labelTitle string] rangeOfString:[title2 string]]];
    [_labelTitle addAttribute:NSUnderlineStyleAttributeName value:@(NSUnderlineStyleSingle) range:[[_labelTitle string] rangeOfString:[title2 string]]];
    
    self.label.attributedText = _labelTitle;
    
    [self.label setTouchUpInsideLinkString:linkTitle withString:_labelTitle block:^(void){
        NSLog(@"点击了链接");
        
    }];
    
    self.label.backgroundColor = [UIColor clearColor];
    
    return self;
}

- (void)setTheFrame:(CGRect)frame
{
    self.frame = frame;
}

@end
