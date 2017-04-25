//
//  ViewController.m
//  CJLabelTest
//
//  Created by ChiJinLian on 17/3/31.
//  Copyright © 2017年 ChiJinLian. All rights reserved.
//

#import "ViewController.h"
#import <CoreText/CoreText.h>

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.label.extendsLinkTouchArea = YES;
//    self.label.userInteractionEnabled = NO;
//    self.label.shadowRadius = 0;
//    self.label.shadowColor = [UIColor blackColor];
//    self.label.shadowOffset = CGSizeMake(0, -1);
//    self.label.highlighted = YES;
//    self.label.highlightedTextColor = [UIColor blueColor];
    self.label.verticalAlignment = CJContentVerticalAlignmentTop;
//    self.label.textInsets = UIEdgeInsetsMake(10, 4, 10, 4);
    self.label.extendsLinkTouchArea = YES;
    [self labelContent];
    
}

- (IBAction)clear:(id)sender {
    [self.label removeLinkAtRange:NSMakeRange(13, 7)];
}

- (IBAction)clearAll:(id)sender {
    [self.label removeAllLink];
}

- (IBAction)reload:(id)sender {
    [self labelContent];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (void)labelContent {
    self.label.numberOfLines = 0;
    self.textLabel.numberOfLines = 0;
    
    
    NSMutableParagraphStyle *paragraph = [[NSMutableParagraphStyle alloc] init];
    paragraph.alignment = NSTextAlignmentLeft;
    paragraph.lineSpacing = 5.2;
    paragraph.lineBreakMode = NSLineBreakByCharWrapping;
    paragraph.lineHeightMultiple = 1;//行间距是多少倍
    
    NSShadow *shadow = [[NSShadow alloc] init];
    shadow.shadowColor = [UIColor blackColor];
    shadow.shadowOffset = CGSizeMake(0, 5);
    
    NSDictionary *dic = @{
                          NSFontAttributeName:[UIFont systemFontOfSize:13],/*(字体)*/
//                          NSFontAttributeName:[UIFont fontWithName:@"Arial-BoldItalicMT" size:30.0],/*(字体)*/
//                          NSBackgroundColorAttributeName:[UIColor grayColor],/*(字体背景色)*/
                          NSForegroundColorAttributeName:[UIColor blackColor],/*(字体颜色)*/
                          NSParagraphStyleAttributeName:paragraph,/*(段落)*/
//                          NSLigatureAttributeName:[NSNumber numberWithInt:1],/*(连字符)*/
//                          NSKernAttributeName:[NSNumber numberWithInt:0],/*(字间距)*/
//                          NSStrikethroughStyleAttributeName:@(NSUnderlinePatternSolid | NSUnderlineStyleSingle),/*(删除线)NSUnderlinePatternSolid(实线)*/
//                          NSUnderlineStyleAttributeName:@(NSUnderlineStyleSingle),/*(下划线)*/
//                          NSStrokeColorAttributeName:[UIColor redColor],/*(边线颜色)*/
//                          NSStrokeWidthAttributeName:@(0.5),/*(边线宽度)*/
//                          NSShadowAttributeName:shadow,/*(阴影)*/
//                          NSVerticalGlyphFormAttributeName:[NSNumber numberWithInt:0],/*(横竖排版)*/
                          };
    NSString *str = @"1这是一段测试数据2这是一段测试数据3这是一段测试数据4这是一段测试数据5这是一段测试数据6这是一段测试数据7这是一段测试数据8这是一段测试数据9这是一段测试数据10这是一段测试数据11这是一段测试数据。";
    
    //设置label text
    NSMutableAttributedString *labelTitle = [[NSMutableAttributedString alloc]initWithString:str attributes:dic];
    
    labelTitle = [self.label configureLinkAttributedString:labelTitle
                                                     atRange:NSMakeRange(13,7)
                                              linkAttributes:@{
//                                                               NSBackgroundColorAttributeName:[UIColor clearColor],/*(字体背景色)*/
                                                               NSFontAttributeName:[UIFont systemFontOfSize:15],/*(字体)*/
                                                               NSForegroundColorAttributeName:[UIColor redColor],/*(字体颜色)*/
                                                               kCJBackgroundStrokeColorAttributeName:[UIColor colorWithRed:0.2 green:0.6 blue:1 alpha:1],
                                                               kCJBackgroundFillColorAttributeName:[UIColor lightGrayColor],
                                                               kCJBackgroundLineWidthAttributeName:@(2)
                                                               }
                                        activeLinkAttributes:@{
                                                               NSFontAttributeName:[UIFont systemFontOfSize:13],/*(字体)*/
                                                               NSForegroundColorAttributeName:[UIColor brownColor],/*(字体颜色)*/
                                                               kCJActiveBackgroundFillColorAttributeName:[UIColor orangeColor],
                                                               kCJActiveBackgroundStrokeColorAttributeName:[UIColor blackColor],
                                                               }
                                                   parameter:nil
                                                  clickLinkBlock:^(NSAttributedString *attributedString, UIImage *image, id parameter, NSRange range){
                                                      NSLog(@"clickLinkBlock, str = %@, range = %@",attributedString.string,NSStringFromRange(range));
                                                  }
                                                  longPressBlock:^(NSAttributedString *attributedString, UIImage *image, id parameter, NSRange range){
                                                      NSLog(@"longPressBlock, str = %@, range = %@",attributedString.string, NSStringFromRange(range));
                                                  }];
    
    NSMutableAttributedString *title = [[NSMutableAttributedString alloc]initWithString:@"11这是" attributes:dic];
    
    labelTitle = [self.label configureLinkAttributedString:labelTitle
                                  withAttString:title
                                      sameStringEnable:NO
                                        linkAttributes:@{
                                                         NSFontAttributeName:[UIFont fontWithName:@"Arial-BoldItalicMT" size:13.0],/*(字体)*/
//                                                         NSBackgroundColorAttributeName:[UIColor whiteColor],/*(字体背景色)*/
                                                         NSForegroundColorAttributeName:[UIColor blueColor],/*(字体颜色)*/
//                                                         NSUnderlineStyleAttributeName:@(NSUnderlineStyleSingle),/*(下划线)*/
//                                                         NSStrikethroughStyleAttributeName:@(NSUnderlinePatternSolid | NSUnderlineStyleSingle),/*(删除线)NSUnderlinePatternSolid(实线)*/
                                                         kCJBackgroundFillColorAttributeName:[UIColor lightGrayColor],
                                                         kCJBackgroundStrokeColorAttributeName:[UIColor orangeColor],
                                                         kCJBackgroundLineWidthAttributeName:@(1),
                                                         kCJBackgroundLineCornerRadiusAttributeName:@(10)
                                                         }
                                        activeLinkAttributes:@{
                                                               NSForegroundColorAttributeName:[UIColor redColor],/*(字体颜色)*/
                                                               kCJActiveBackgroundFillColorAttributeName:[UIColor orangeColor],
                                                               kCJActiveBackgroundStrokeColorAttributeName:[UIColor blackColor],
                                                               }
                                             parameter:nil
                                     clickLinkBlock:^(NSAttributedString *attributedString, UIImage *image, id parameter, NSRange range){
                                         NSLog(@"clickLinkBlock, str = %@, range = %@",attributedString.string,NSStringFromRange(range));
                                     }
                                                  longPressBlock:^(NSAttributedString *attributedString, UIImage *image, id parameter, NSRange range){
                                                      NSLog(@"longPressBlock, str = %@, range = %@",attributedString.string,NSStringFromRange(range));
                                                  }];
    
    NSMutableAttributedString *labelStr = [[NSMutableAttributedString alloc]initWithAttributedString:labelTitle];
    NSMutableAttributedString *labelStr2 = [[NSMutableAttributedString alloc]initWithAttributedString:labelTitle];
    
    labelStr = [self.label configureLinkAttributedString:labelTitle
                                                addImageName:@"1.png"
                                                   imageSize:CGSizeMake(100, 75)
                                                     atIndex:20
                                              linkAttributes:@{}
                                            activeLinkAttributes:@{
                                                                   kCJBackgroundLineWidthAttributeName:@(2),
                                                                   kCJActiveBackgroundStrokeColorAttributeName:[UIColor orangeColor],
                                                                   }
                                                   parameter:nil
                                                  clickLinkBlock:^(NSAttributedString *attributedString, UIImage *image, id parameter, NSRange range){
                                                      NSLog(@"clickLinkBlock, str = %@, range = %@, image = %@",attributedString.string,NSStringFromRange(range),image);
                                                  }
                                                  longPressBlock:^(NSAttributedString *attributedString, UIImage *image, id parameter, NSRange range){
                                                      NSLog(@"longPressBlock, str = %@, range = %@, image = %@",attributedString.string,NSStringFromRange(range),image);
                                                  }];
    
//    labelStr = [self.label configureAttributedString:labelStr addImageName:@"1.png" imageSize:CGSizeMake(100, 75) atIndex:12 attributes:@{}];
    
    
    
    NSTextAttachment *attachment = [[NSTextAttachment alloc]initWithData:nil ofType:nil];
    UIImage *image = [UIImage imageNamed:@"1.png"];
    attachment.image = image;
    attachment.bounds = CGRectMake(0, 0, 100, 75);
    
    NSAttributedString *text = [NSAttributedString attributedStringWithAttachment:attachment];
    [labelStr2 insertAttributedString:text atIndex:12];
    
//    self.label.attributedText = labelStr;
    self.label.text = labelStr;
    
    self.textLabel.attributedText = labelStr2;
    
}

@end
