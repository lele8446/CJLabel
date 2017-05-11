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

@interface DetailViewController ()<UITextFieldDelegate>
@property (nonatomic, weak) IBOutlet CJLabel *firstLabel;
@property (nonatomic, strong) CJLabel *secondLabel;
@property (nonatomic, strong) NSAttributedString *attStr;
@end

@implementation DetailViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.edgesForExtendedLayout = UIRectEdgeNone;
    self.automaticallyAdjustsScrollViewInsets = NO;
    
    self.firstLabel.numberOfLines = 0;
    
    NSAttributedString *content = self.content;
    [self handleContent:content];

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)handleContent:(NSAttributedString *)content {
    
    NSAttributedString *attStr = content;
    attStr = [CJLabel configureAttributedString:attStr
                                        atRange:NSMakeRange(0, 3)
                                     attributes:@{NSForegroundColorAttributeName:[UIColor blackColor],
                                                  NSFontAttributeName:[UIFont boldSystemFontOfSize:15]
                                                  }];
    self.attStr = attStr;
    switch (self.index) {
        case 0:
            self.firstLabel.hidden = YES;
            self.secondLabel = [[CJLabel alloc]initWithFrame:CGRectMake(10, 10, [[UIScreen mainScreen] bounds].size.width - 20, [[UIScreen mainScreen] bounds].size.height - 64 - 100)];
            self.secondLabel.backgroundColor = UIColorFromRGB(0xf0f0de);
            self.secondLabel.numberOfLines = 10;
            self.secondLabel.textInsets = UIEdgeInsetsMake(10, 15, 20, 0);
            self.secondLabel.verticalAlignment = CJVerticalAlignmentBottom;
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
            if (self.index == 2) {
                UIBarButtonItem *item = [[UIBarButtonItem alloc]initWithTitle:@"删除首个链点" style:UIBarButtonItemStylePlain target:self action:@selector(itemClick:)];
                item.tag = 100;
                self.navigationItem.rightBarButtonItem = item;
            }
            
        }
            break;
            
        case 3:
            self.firstLabel.hidden = YES;
            self.secondLabel = [[CJLabel alloc]initWithFrame:CGRectMake(10, 10, [[UIScreen mainScreen] bounds].size.width - 20, [[UIScreen mainScreen] bounds].size.height - 64 - 100)];
            self.secondLabel.backgroundColor = UIColorFromRGB(0xf0f0de);
            self.secondLabel.numberOfLines = 0;
            self.secondLabel.verticalAlignment = CJVerticalAlignmentTop;
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
        {
            [self configureLabelContent:attStr verticalAlignment:CJVerticalAlignmentBottom];
            UIBarButtonItem *item = [[UIBarButtonItem alloc]initWithTitle:@"删除全部链点" style:UIBarButtonItemStylePlain target:self action:@selector(itemClick:)];
            item.tag = 200;
            self.navigationItem.rightBarButtonItem = item;
            break;
        }
        case 5:
        {
            [self configureLabelContent:attStr verticalAlignment:CJVerticalAlignmentBottom];
            UIBarButtonItem *item1 = [[UIBarButtonItem alloc]initWithTitle:@"居上" style:UIBarButtonItemStylePlain target:self action:@selector(itemClick:)];
            item1.tag = 300;
            UIBarButtonItem *item2 = [[UIBarButtonItem alloc]initWithTitle:@"居中" style:UIBarButtonItemStylePlain target:self action:@selector(itemClick:)];
            item2.tag = 400;
            UIBarButtonItem *item3 = [[UIBarButtonItem alloc]initWithTitle:@"居下" style:UIBarButtonItemStylePlain target:self action:@selector(itemClick:)];
            item3.tag = 500;
            self.navigationItem.rightBarButtonItems = @[item1,item2,item3];
        }
            break;
            
        default:
            break;
    }
}

- (void)configureLabelContent:(NSAttributedString *)attStr verticalAlignment:(CJLabelVerticalAlignment)verticalAlignment {
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
                                                      NSFontAttributeName:[UIFont boldSystemFontOfSize:15],
                                                      kCJActiveBackgroundStrokeColorAttributeName:[UIColor blackColor],
                                                      kCJActiveBackgroundFillColorAttributeName:UIRGBColor(247,231,121,1)
                                                      }
                                          parameter:@"参数为字符串"
                                     clickLinkBlock:^(CJLabelLinkModel *linkModel){
                                         [self clickLink:linkModel isImage:NO];
                                     }longPressBlock:^(CJLabelLinkModel *linkModel){
                                         [self clicklongPressLink:linkModel isImage:NO];
                                     }];
    
    NSRange imageRange = [attStr.string rangeOfString:@"图片"];
    attStr = [CJLabel configureLinkAttributedString:attStr
                                       addImageName:@"CJLabel.png"
                                          imageSize:CGSizeMake(60, 48)
                                            atIndex:imageRange.location+imageRange.length
                                  verticalAlignment:verticalAlignment
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
    self.firstLabel.extendsLinkTouchArea = YES;
}

- (void)itemClick:(UIBarButtonItem *)item {
    
    if (item.tag == 100) {
        NSRange labelRange = [self.firstLabel.attributedText.string rangeOfString:@"CJLabel"];
        [self.firstLabel removeLinkAtRange:labelRange];
        item.enabled = NO;
    }else if (item.tag == 200) {
        [self.firstLabel removeAllLink];
        item.enabled = NO;
    }else if (item.tag == 300) {
        [self configureLabelContent:self.attStr verticalAlignment:CJVerticalAlignmentTop];
    }else if (item.tag == 400) {
        [self configureLabelContent:self.attStr verticalAlignment:CJVerticalAlignmentCenter];
    }else if (item.tag == 500) {
        [self configureLabelContent:self.attStr verticalAlignment:CJVerticalAlignmentBottom];
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
