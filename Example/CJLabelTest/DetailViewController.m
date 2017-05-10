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

@property (nonatomic, weak) IBOutlet CJLabel *label;
@property (nonatomic, weak) IBOutlet UITextField *textField;
@end

@implementation DetailViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.edgesForExtendedLayout = UIRectEdgeNone;
    self.automaticallyAdjustsScrollViewInsets = NO;
    
    self.firstLabel.numberOfLines = 0;
    
    NSAttributedString *content = self.content;
    [self handleContent:content];
//    [self handleLabelContent:content];
    
    self.textField.delegate = self;
    
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    NSMutableAttributedString *attstr = [[NSMutableAttributedString alloc]initWithAttributedString:self.label.attributedText];
    [attstr replaceCharactersInRange:NSMakeRange(6, 2) withString:textField.text];
    self.label.attributedText = attstr;
    
    return YES;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)handleLabelContent:(NSAttributedString *)content {
    NSAttributedString *attStr = content;
    attStr = [CJLabel configureLinkAttributedString:attStr
                                            atRange:NSMakeRange(0, 3)
                                     linkAttributes:@{NSForegroundColorAttributeName:[UIColor blackColor],
                                                      NSFontAttributeName:[UIFont boldSystemFontOfSize:15]
                                                      }
                               activeLinkAttributes:@{NSForegroundColorAttributeName:[UIColor blueColor],
                                                      NSFontAttributeName:[UIFont boldSystemFontOfSize:15]
                                                      }
                                          parameter:nil
                                     clickLinkBlock:nil
                                     longPressBlock:nil];
    self.label.attributedText = attStr;
    
    NSRange imageRange = [attStr.string rangeOfString:@"图片"];
    if (imageRange.location != NSNotFound) {
        attStr = [CJLabel configureLinkAttributedString:attStr
                                           addImageName:@"CJLabel.png"
                                              imageSize:CGSizeMake(60, 43)
                                                atIndex:imageRange.location+imageRange.length
                                      verticalAlignment:CJContentVerticalAlignmentBottom
                                         linkAttributes:@{
                                                          kCJBackgroundStrokeColorAttributeName:[UIColor blueColor],
                                                          kCJBackgroundLineWidthAttributeName:@(1),
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
    }

    attStr = [CJLabel configureLinkAttributedString:attStr
                                       addImageName:@"CJLabel.png"
                                          imageSize:CGSizeMake(40, 23)
                                            atIndex:5
                                  verticalAlignment:CJContentVerticalAlignmentBottom
                                     linkAttributes:@{
                                                      kCJBackgroundStrokeColorAttributeName:[UIColor blueColor],
                                                      kCJBackgroundLineWidthAttributeName:@(1),
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
    self.label.attributedText = attStr;
}

- (void)handleContent:(NSAttributedString *)content {
    
    NSAttributedString *attStr = content;
    attStr = [CJLabel configureAttributedString:attStr
                                        atRange:NSMakeRange(0, 3)
                                     attributes:@{NSForegroundColorAttributeName:[UIColor blackColor],
                                                  NSFontAttributeName:[UIFont boldSystemFontOfSize:35]
                                                  }];
    switch (self.index) {
        case 0:
            self.firstLabel.hidden = YES;
            self.secondLabel = [[CJLabel alloc]initWithFrame:CGRectMake(10, 10, [[UIScreen mainScreen] bounds].size.width - 20, [[UIScreen mainScreen] bounds].size.height - 64 - 100)];
            self.secondLabel.backgroundColor = UIColorFromRGB(0xf0f0de);
            self.secondLabel.numberOfLines = 10;
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
            self.secondLabel.verticalAlignment = CJContentVerticalAlignmentTop;
            [self.view addSubview:self.secondLabel];
            
            NSRange imageRange = [attStr.string rangeOfString:@"插入图片"];
            attStr = [CJLabel configureAttributedString:attStr
                                           addImageName:@"CJLabel.png"
                                              imageSize:CGSizeMake(120, 85)
                                                atIndex:imageRange.location+imageRange.length
                                      verticalAlignment:CJContentVerticalAlignmentCenter
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
                                                              NSFontAttributeName:[UIFont boldSystemFontOfSize:20],
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
                                                  imageSize:CGSizeMake(60, 8)
                                                    atIndex:imageRange.location+imageRange.length
                                          verticalAlignment:CJContentVerticalAlignmentCenter
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
//            paragraph.lineSpacing = 2;
//            paragraph.lineHeightMultiple = 1.0;
            [str addAttribute:NSParagraphStyleAttributeName value:paragraph range:NSMakeRange(0, str.length)];
            
            self.firstLabel.attributedText = str;
            
            if (self.index == 4) {
                UIBarButtonItem *item = [[UIBarButtonItem alloc]initWithTitle:@"删除全部链点" style:UIBarButtonItemStylePlain target:self action:@selector(itemClick:)];
                item.tag = 200;
                self.navigationItem.rightBarButtonItem = item;
            }
        }
            break;
            
        default:
            break;
    }
}

- (void)itemClick:(UIBarButtonItem *)item {
    
    if (item.tag == 100) {
        NSRange labelRange = [self.firstLabel.attributedText.string rangeOfString:@"CJLabel"];
        [self.firstLabel removeLinkAtRange:labelRange];
        item.enabled = NO;
    }else if (item.tag == 200) {
        [self.firstLabel removeAllLink];
        item.enabled = NO;
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

//- (void)viewDidAppear:(BOOL)animated {
//    [super viewDidAppear:animated];
//    UILabel *label = self.firstLabel;
//    if (self.index == 0 || self.index == 3) {
//        label = self.secondLabel;
//    }
//    CGFloat hight = CGRectGetHeight(label.frame);
//    NSLog(@"\n");
//    NSLog(@"整体label hight = %@",@(hight));
//}
@end
