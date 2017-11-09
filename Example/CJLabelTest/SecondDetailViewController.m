//
//  DetailViewController.m
//  CJLabelTest
//
//  Created by ChiJinLian on 2017/4/28.
//  Copyright © 2017年 C.K.Lian. All rights reserved.
//

#import "SecondDetailViewController.h"
#import "CJLabel.h"
#import "Common.h"


@interface SecondDetailViewController ()
@property (nonatomic, weak) IBOutlet CJLabel *firstLabel;
@property (nonatomic, strong) CJLabel *secondLabel;
@property (nonatomic, strong) NSAttributedString *attStr;
@end

@implementation SecondDetailViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.edgesForExtendedLayout = UIRectEdgeNone;
    self.automaticallyAdjustsScrollViewInsets = NO;
    
    self.firstLabel.numberOfLines = 0;
    
    NSMutableAttributedString *content = self.content;
    [self handleContent:content];

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)handleContent:(NSMutableAttributedString *)content {
    /* 设置默认换行模式为：NSLineBreakByCharWrapping
     * 当Label的宽度不够显示内容或图片的时候就自动换行, 如果不自动换行, 超出一行的部分图片将不显示
     */
    NSMutableParagraphStyle *paragraph = [[NSMutableParagraphStyle alloc] init];
    paragraph.lineBreakMode = NSLineBreakByCharWrapping;
    paragraph.lineSpacing = 6;
    NSMutableAttributedString *attStr = content;
    [attStr addAttribute:NSParagraphStyleAttributeName value:paragraph range:NSMakeRange(0, attStr.length)];
    
    self.attStr = attStr;
    
    CJLabelConfigure *configure = [CJLabel configureAttributes:nil isLink:NO activeLinkAttributes:nil parameter:nil clickLinkBlock:nil longPressBlock:nil];
    
    switch (self.index) {
        case 0:
        {
            //设置 CJLabel 不可点击
            configure.isLink = NO;
            attStr = [CJLabel configureAttrString:attStr withString:@"CJLabel" sameStringEnable:YES configure:configure];
            
            //设置 `不同字体` 显示为粗体17的字号
            configure.attributes = @{NSFontAttributeName:[UIFont boldSystemFontOfSize:18]};
            attStr = [CJLabel configureAttrString:attStr withString:@"不同字体" sameStringEnable:NO configure:configure];
            
            //设置 `字体背景色` 填充背景色，以及填充区域圆角
            configure.attributes = @{kCJBackgroundFillColorAttributeName:[UIColor colorWithWhite:0.5 alpha:1],kCJBackgroundLineCornerRadiusAttributeName:@(2)};
//            configure.isLink = YES;
            attStr = [CJLabel configureAttrString:attStr withString:@"字体背景色" sameStringEnable:NO configure:configure];
            
            //设置 `字体边框线` 边框线
            configure.attributes = @{kCJBackgroundStrokeColorAttributeName:[UIColor orangeColor]};
//            configure.isLink = YES;
            attStr = [CJLabel configureAttrString:attStr withString:@"字体边框线" sameStringEnable:NO configure:configure];
            
            //指定位置插入图片
            NSRange imgRange = [attStr.string rangeOfString:@"插入图片"];
            [configure removeAttributesForKey:kCJBackgroundStrokeColorAttributeName];
            attStr = [CJLabel insertImageAtAttrString:attStr image:@"CJLabel.png" imageSize:CGSizeMake(55, 45) atIndex:(imgRange.location+imgRange.length) imagelineAlignment:CJVerticalAlignmentBottom configure:configure];
            
            //设置内边距
            self.firstLabel.textInsets = UIEdgeInsetsMake(10, 10, 10, 0);
            self.firstLabel.attributedText = attStr;
            self.firstLabel.enableCopy = YES;
        }
            break;
            
        case 1:
        case 2:
        {
            configure.attributes = @{
                                     NSForegroundColorAttributeName:[UIColor blueColor],
                                     NSFontAttributeName:[UIFont boldSystemFontOfSize:15],
                                     kCJBackgroundStrokeColorAttributeName:[UIColor orangeColor],
                                     kCJBackgroundLineWidthAttributeName:@((self.index==1?2:1)),
                                     kCJBackgroundFillColorAttributeName:[UIColor lightGrayColor]
                                     };
            configure.activeLinkAttributes = @{
                                               NSForegroundColorAttributeName:[UIColor redColor],
                                               kCJActiveBackgroundStrokeColorAttributeName:[UIColor blackColor],
                                               kCJActiveBackgroundFillColorAttributeName:UIRGBColor(247,231,121,1)
                                               };
            configure.parameter = @"参数为字符串";
            configure.clickLinkBlock = ^(CJLabelLinkModel *linkModel) {
                [self clickLink:linkModel isImage:NO];
            };
            configure.longPressBlock = ^(CJLabelLinkModel *linkModel) {
                [self clicklongPressLink:linkModel isImage:NO];
            };
            configure.isLink = YES;
            attStr = [CJLabel configureAttrString:attStr
                                       withString:@"CJLabel"
                                 sameStringEnable:(self.index==1?NO:YES)
                                        configure:configure];
            
            self.firstLabel.textInsets = UIEdgeInsetsMake(2, 0, 0, 0);
            self.firstLabel.attributedText = attStr;
            if (self.index == 2) {
                UIBarButtonItem *item = [[UIBarButtonItem alloc]initWithTitle:@"删除首个链点" style:UIBarButtonItemStylePlain target:self action:@selector(itemClick:)];
                item.tag = 100;
                self.navigationItem.rightBarButtonItem = item;
            }
            
        }
            break;
            
        case 3:
        {
            self.firstLabel.hidden = YES;
            self.secondLabel = [[CJLabel alloc]initWithFrame:CGRectMake(10, 10, [[UIScreen mainScreen] bounds].size.width - 20, [[UIScreen mainScreen] bounds].size.height - 64 - 100)];
            self.secondLabel.backgroundColor = UIColorFromRGB(0xf0f0de);
            self.secondLabel.numberOfLines = 0;
            self.secondLabel.textInsets = UIEdgeInsetsMake(100, 50, 0, 0);
            self.secondLabel.verticalAlignment = CJVerticalAlignmentTop;
            self.secondLabel.enableCopy = YES;
            [self.view addSubview:self.secondLabel];
            
            NSRange imageRange = [attStr.string rangeOfString:@"插入图片"];
            CJLabelConfigure *imgConfigure =
            [CJLabel configureAttributes:@{kCJBackgroundStrokeColorAttributeName:[UIColor redColor],                                                         kCJBackgroundLineWidthAttributeName:@(2)} isLink:YES activeLinkAttributes:nil parameter:nil clickLinkBlock:^(CJLabelLinkModel *linkModel) {
                [self clickLink:linkModel isImage:YES];
            } longPressBlock:nil];
            
            attStr = [CJLabel insertImageAtAttrString:attStr
                                                image:[UIImage imageNamed:@"CJLabel.png"]
                                            imageSize:CGSizeMake(120, 85)
                                              atIndex:(imageRange.location+imageRange.length)
                                   imagelineAlignment:CJVerticalAlignmentBottom
                                            configure:imgConfigure];
            
            configure.attributes = @{
                                     NSForegroundColorAttributeName:[UIColor blueColor],
                                     NSFontAttributeName:[UIFont boldSystemFontOfSize:15],
                                     kCJBackgroundStrokeColorAttributeName:[UIColor orangeColor],
                                     kCJBackgroundLineWidthAttributeName:@(2),
                                     kCJBackgroundFillColorAttributeName:[UIColor lightGrayColor]
                                     };
            attStr = [CJLabel configureAttrString:attStr
                                       withString:@"CJLabel"
                                 sameStringEnable:NO
                                        configure:configure];
            
            self.secondLabel.attributedText = attStr;
        }
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
            self.firstLabel.textInsets = UIEdgeInsetsMake(0, 0, 0, 0);
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
    CJLabelConfigure *configure =
    [CJLabel configureAttributes:@{
                                   NSForegroundColorAttributeName:[UIColor blueColor],
                                   NSFontAttributeName:[UIFont boldSystemFontOfSize:45],
//                                   kCJBackgroundStrokeColorAttributeName:[UIColor orangeColor],
                                   kCJBackgroundLineWidthAttributeName:@(self.index == 5?1:2),
//                                   kCJBackgroundFillColorAttributeName:[UIColor lightGrayColor]
                                   }
                          isLink:YES
            activeLinkAttributes:@{
                                   NSForegroundColorAttributeName:[UIColor redColor],
                                   NSFontAttributeName:[UIFont boldSystemFontOfSize:15],
                                   kCJActiveBackgroundStrokeColorAttributeName:[UIColor blackColor],
                                   kCJActiveBackgroundFillColorAttributeName:UIRGBColor(247,231,121,1),
                                   kCJBackgroundLineCornerRadiusAttributeName:@(0)
                                   }
                       parameter:@"字符串参数"
                  clickLinkBlock:^(CJLabelLinkModel *linkModel){
                      [self clickLink:linkModel isImage:NO];
                  }
                  longPressBlock:^(CJLabelLinkModel *linkModel){
                      [self clicklongPressLink:linkModel isImage:NO];
                  }];
    //CJLabel
    attStr = [CJLabel configureAttrString:attStr
                               withString:@"CJLabel"
                         sameStringEnable:NO
                                configure:configure];

    NSRange imageRange = [attStr.string rangeOfString:@"图片"];
    CJLabelConfigure *imgConfigure =
    [CJLabel configureAttributes:@{
                                   kCJBackgroundStrokeColorAttributeName:[UIColor blueColor],
                                   kCJBackgroundLineWidthAttributeName:@(self.index == 5?1:2),
                                   kCJBackgroundLineCornerRadiusAttributeName:@(0)
                                   }
                          isLink:YES
            activeLinkAttributes:@{kCJActiveBackgroundStrokeColorAttributeName:[UIColor redColor]}
                       parameter:@"图片参数"
                  clickLinkBlock:^(CJLabelLinkModel *linkModel){
                      [self clickLink:linkModel isImage:YES];
                  }
                  longPressBlock:^(CJLabelLinkModel *linkModel){
                      [self clicklongPressLink:linkModel isImage:YES];
                  }];
    attStr = [CJLabel insertImageAtAttrString:attStr image:@"CJLabel.png" imageSize:CGSizeMake(45, 28) atIndex:(imageRange.location+imageRange.length) imagelineAlignment:verticalAlignment configure:imgConfigure];

    self.firstLabel.attributedText = attStr;
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
         title = [NSString stringWithFormat:@"点击链点图片：%@",linkModel.image];
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
        title = [NSString stringWithFormat:@"长按点击图片：%@",linkModel.image];
    }

    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil];
    [alert addAction:cancel];
    [self presentViewController:alert animated:YES completion:nil];
}

@end
