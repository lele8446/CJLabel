//
//  DetailViewController.m
//  CJLabelTest
//
//  Created by ChiJinLian on 2017/4/28.
//  Copyright © 2017年 C.K.Lian. All rights reserved.
//

#import "DetailViewController.h"
#import "CJLabel.h"

#define UIRGBColor(r,g,b,a) ([UIColor colorWithRed:r/255.0 green:g/255.0 blue:b/255.0 alpha:a])
#define UIColorFromRGB(rgbValue) [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 \
                                                 green:((float)((rgbValue & 0xFF00) >> 8))/255.0 \
                                                  blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0]

@interface DetailViewController ()
@property (nonatomic, weak) IBOutlet CJLabel *firstLabel;
@property (nonatomic, strong) CJLabel *secondLabel;
@end

@implementation DetailViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.edgesForExtendedLayout = UIRectEdgeNone;
    self.automaticallyAdjustsScrollViewInsets = NO;
    
    self.firstLabel.numberOfLines = 0;
    
    [self handleLabelContent];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    
}

- (void)handleLabelContent {
    
    NSAttributedString *attStr = self.content;
    attStr = [CJLabel configureAttributedString:attStr
                                        atRange:NSMakeRange(0, 3)
                                     attributes:@{NSForegroundColorAttributeName:[UIColor blackColor],
                                                  NSFontAttributeName:[UIFont boldSystemFontOfSize:15]
                                                  }];
    
    switch (self.index) {
        case 0:
            self.firstLabel.hidden = YES;
            self.secondLabel = [[CJLabel alloc]initWithFrame:CGRectMake(10, 10, [[UIScreen mainScreen] bounds].size.width - 20, [[UIScreen mainScreen] bounds].size.height - 64 - 100)];
            self.secondLabel.backgroundColor = UIColorFromRGB(0xf0f0de);
            self.secondLabel.numberOfLines = 0;
            self.secondLabel.textInsets = UIEdgeInsetsMake(10, 15, 20, 0);
            self.secondLabel.verticalAlignment = CJContentVerticalAlignmentBottom;
            [self.view addSubview:self.secondLabel];
            
            attStr = [CJLabel configureAttributedString:attStr
                                             withString:@"CJLabel"
                                       sameStringEnable:NO
                                             attributes:@{
                                                          NSForegroundColorAttributeName:[UIColor blueColor],
                                                          NSFontAttributeName:[UIFont boldSystemFontOfSize:15],
                                                          kCJBackgroundStrokeColorAttributeName:[UIColor orangeColor],
                                                          kCJBackgroundLineWidthAttributeName:@(2),
                                                          kCJBackgroundFillColorAttributeName:[UIColor lightGrayColor]
                                                          }];
            self.secondLabel.attributedText = attStr;
            break;
            
        case 1:
        case 2:
        {
            attStr = [CJLabel configureLinkAttributedString:attStr
                                                 withString:@"CJLabel"
                                           sameStringEnable:(self.index==1?NO:YES)
                                             linkAttributes:@{
                                                              NSForegroundColorAttributeName:[UIColor blueColor],
                                                              NSFontAttributeName:[UIFont boldSystemFontOfSize:15],
                                                              kCJBackgroundStrokeColorAttributeName:[UIColor orangeColor],
                                                              kCJBackgroundLineWidthAttributeName:@((self.index==1?2:1)),
                                                              kCJBackgroundFillColorAttributeName:[UIColor lightGrayColor]
                                                              }
                                       activeLinkAttributes:@{
                                                              NSForegroundColorAttributeName:[UIColor redColor],
                                                              kCJActiveBackgroundStrokeColorAttributeName:[UIColor blackColor],
                                                              kCJActiveBackgroundFillColorAttributeName:UIRGBColor(247,231,121,1)
                                                              }
                                                  parameter:@"参数为字符串"
                                             clickLinkBlock:^(CJLabelLinkModel *linkModel){
                                                 [self clickLink:linkModel isImage:NO];
                                             }longPressBlock:^(CJLabelLinkModel *linkModel){
                                                 [self clicklongPressLink:linkModel isImage:NO];
                                             }];
            self.firstLabel.attributedText = attStr;
        }
            break;
            
        case 3:
            self.firstLabel.hidden = YES;
            self.secondLabel = [[CJLabel alloc]initWithFrame:CGRectMake(10, 10, [[UIScreen mainScreen] bounds].size.width - 20, [[UIScreen mainScreen] bounds].size.height - 64 - 100)];
            self.secondLabel.backgroundColor = UIColorFromRGB(0xf0f0de);
            self.secondLabel.numberOfLines = 0;
            self.secondLabel.verticalAlignment = CJContentVerticalAlignmentTop;
            [self.view addSubview:self.secondLabel];
            
            NSRange imageRange = [attStr.string rangeOfString:@"插入图片"];
            attStr = [CJLabel configureAttributedString:attStr
                                           addImageName:@"CJLabel.png"
                                              imageSize:CGSizeMake(120, 85)
                                                atIndex:imageRange.location+imageRange.length
                                             attributes:@{kCJBackgroundStrokeColorAttributeName:[UIColor redColor],
                                                          kCJBackgroundLineWidthAttributeName:@(2)}];
            
            attStr = [CJLabel configureAttributedString:attStr
                                             withString:@"CJLabel"
                                       sameStringEnable:NO
                                             attributes:@{
                                                          NSForegroundColorAttributeName:[UIColor blueColor],
                                                          NSFontAttributeName:[UIFont boldSystemFontOfSize:15],
                                                          kCJBackgroundStrokeColorAttributeName:[UIColor orangeColor],
                                                          kCJBackgroundLineWidthAttributeName:@(2),
                                                          kCJBackgroundFillColorAttributeName:[UIColor lightGrayColor]
                                                          }];
            self.secondLabel.attributedText = attStr;
            
            break;
            
        case 4:
        case 5:
        {
            attStr = [CJLabel configureLinkAttributedString:attStr
                                                 withString:@"CJLabel"
                                           sameStringEnable:NO
                                             linkAttributes:@{
                                                              NSForegroundColorAttributeName:[UIColor blueColor],
                                                              NSFontAttributeName:[UIFont boldSystemFontOfSize:15],
                                                              kCJBackgroundStrokeColorAttributeName:[UIColor orangeColor],
                                                              kCJBackgroundLineWidthAttributeName:@(self.index == 5?1:2),
                                                              kCJBackgroundFillColorAttributeName:[UIColor lightGrayColor]
                                                              }
                                       activeLinkAttributes:@{
                                                              NSForegroundColorAttributeName:[UIColor redColor],
                                                              kCJActiveBackgroundStrokeColorAttributeName:[UIColor blackColor],
                                                              kCJActiveBackgroundFillColorAttributeName:UIRGBColor(247,231,121,1)
                                                              }
                                                  parameter:@"参数为字符串"
                                             clickLinkBlock:^(CJLabelLinkModel *linkModel){
                                                 [self clickLink:linkModel isImage:NO];
                                             }longPressBlock:^(CJLabelLinkModel *linkModel){
                                                 [self clicklongPressLink:linkModel isImage:NO];
                                             }];
            
            NSRange imageRange = [attStr.string rangeOfString:@"插入图片"];
            attStr = [CJLabel configureLinkAttributedString:attStr
                                               addImageName:@"CJLabel.png"
                                                  imageSize:CGSizeMake(60, 43)
                                                    atIndex:imageRange.location+imageRange.length
                                             linkAttributes:@{
                                                              kCJBackgroundStrokeColorAttributeName:[UIColor blueColor],
                                                              kCJBackgroundLineWidthAttributeName:@(self.index == 5?1:2),
                                                              }
                                       activeLinkAttributes:@{
                                                              kCJActiveBackgroundStrokeColorAttributeName:[UIColor redColor],
                                                              }
                                                  parameter:@"图片参数"
                                             clickLinkBlock:^(CJLabelLinkModel *linkModel){
                                                 [self clickLink:linkModel isImage:YES];
                                             }longPressBlock:^(CJLabelLinkModel *linkModel){
                                                 [self clicklongPressLink:linkModel isImage:YES];
                                             }];
            /* 设置默认换行模式为：NSLineBreakByCharWrapping
             * 当Label的宽度不够显示内容或图片的时候就自动换行, 不自动换行, 部分图片将会看不见
             */
            NSMutableAttributedString *str = [[NSMutableAttributedString alloc]initWithAttributedString:attStr];
            NSMutableParagraphStyle *paragraph = [[NSMutableParagraphStyle alloc] init];
            paragraph.lineBreakMode = NSLineBreakByCharWrapping;
            [str addAttribute:NSParagraphStyleAttributeName value:paragraph range:NSMakeRange(0, str.length)];
            
            self.firstLabel.attributedText = str;
        }
            break;
            
        default:
            break;
    }
}

- (void)clickLink:(CJLabelLinkModel *)linkModel isImage:(BOOL)isImage {
    NSString *title = [NSString stringWithFormat:@"点击链点 %@",linkModel.attributedString.string];
    if (isImage) {
         title = [NSString stringWithFormat:@"点击链点图片：%@",linkModel.imageName];
    }
    NSString *parameter = [NSString stringWithFormat:@"自定义参数：%@",linkModel.parameter];
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:parameter preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil];
    [alert addAction:cancel];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)clicklongPressLink:(CJLabelLinkModel *)linkModel isImage:(BOOL)isImage {
    NSString *title = [NSString stringWithFormat:@"长按点击: %@",linkModel.attributedString.string];
    if (isImage) {
        title = [NSString stringWithFormat:@"长按点击图片：%@",linkModel.imageName];
    }

    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil];
    [alert addAction:cancel];
    [self presentViewController:alert animated:YES completion:nil];
}

@end
