//
//  ViewController.m
//  tableViewLabelDemo
//
//  Created by YiChe on 16/6/13.
//  Copyright © 2016年 YiChe. All rights reserved.
//

#import "ViewController.h"
#import "Common.h"
#import "AttributedTableViewCell.h"
#import "FirstDetailViewController.h"
#import "SecondDetailViewController.h"


@interface ViewController ()<UITableViewDelegate,UITableViewDataSource,CJLabelLinkDelegate>
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSMutableArray *espressos;

@property (nonatomic, strong) AttributedTableViewCell *tempCell;

@end

@implementation ViewController

- (AttributedTableViewCell *)tempCell {
    if (!_tempCell) {
        _tempCell = [[[NSBundle mainBundle] loadNibNamed:@"AttributedTableViewCell" owner:self options:Nil] lastObject];
    }
    return _tempCell;
}


- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.edgesForExtendedLayout = UIRectEdgeNone;
    self.automaticallyAdjustsScrollViewInsets = NO;
    
    self.tableView = [[UITableView alloc]initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height) style:UITableViewStylePlain];
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.tableFooterView = [[UIView alloc] init];
    [self.view addSubview:self.tableView];
    
    [self readFile];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)readFile {
    NSString *path = [[NSBundle mainBundle] pathForResource:@"Example" ofType:@"json"];
    NSString *content = [[NSString alloc] initWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
    
    NSData *JSONData = [content dataUsingEncoding:NSUTF8StringEncoding];
    NSArray *responseJSON = nil;
    if (JSONData) {
        responseJSON = [NSJSONSerialization JSONObjectWithData:JSONData options:NSJSONReadingMutableContainers error:nil];
    }
    
    /* 设置默认换行模式为：NSLineBreakByCharWrapping
     * 当Label的宽度不够显示内容或图片的时候就自动换行, 如果不自动换行, 超出一行的部分图片将不显示
     */
    NSMutableParagraphStyle *paragraph = [[NSMutableParagraphStyle alloc] init];
    paragraph.lineBreakMode = NSLineBreakByCharWrapping;
    paragraph.lineSpacing = 6;
    
    self.espressos = [NSMutableArray array];
    for (int i = 0; i<responseJSON.count; i++) {
        NSString *str = [[responseJSON objectAtIndex:i] objectForKey:@"text"];
        if (str.length == 0) {
            continue;
        }
        NSMutableAttributedString *attStr = [[NSMutableAttributedString alloc]initWithString:str];
        [attStr addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:13] range:NSMakeRange(0, str.length)];
        
        CJLabelConfigure *configure =
        [CJLabel configureAttributes:@{NSFontAttributeName:[UIFont boldSystemFontOfSize:15]}
                              isLink:NO
                activeLinkAttributes:nil
                           parameter:nil
                      clickLinkBlock:nil
                      longPressBlock:nil];
        attStr = [CJLabel configureAttrString:attStr atRange:NSMakeRange(0, 3) configure:configure];
        
        configure.attributes = @{NSForegroundColorAttributeName:[UIColor blueColor],
                                 NSFontAttributeName:[UIFont boldSystemFontOfSize:13]
                                 };
        configure.activeLinkAttributes = @{NSForegroundColorAttributeName:[UIColor redColor]};
        
        
        if (i==6) {
            configure.isLink = NO;
            attStr = [CJLabel configureAttrString:attStr withString:@"#CJLabel#" sameStringEnable:YES configure:configure];
        }else{
            configure.isLink = YES;
            configure.parameter = @"CJLabel";
            attStr = [CJLabel configureAttrString:attStr withString:@"CJLabel" sameStringEnable:YES configure:configure];
        }
        
        [attStr addAttribute:NSParagraphStyleAttributeName value:paragraph range:NSMakeRange(0, attStr.length)];
        [self.espressos addObject:attStr];
    }
}


- (NSInteger)tableView:(__unused UITableView *)tableView numberOfRowsInSection:(__unused NSInteger)section {
    return (NSInteger)[self.espressos count];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(__unused NSIndexPath *)indexPath {
    NSAttributedString *content = [self.espressos objectAtIndex:(NSUInteger)indexPath.row];
    
    // 方法一 systemLayoutSizeFittingSize:计算高度
//    self.tempCell.label.text = content;
//    CGSize size =[self.tempCell.contentView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize];
//    return size.height+1;

    // 方法二 CJLabel类方法计算高度
    CGSize size1 = [CJLabel sizeWithAttributedString:content withConstraints:CGSizeMake(ScreenWidth-20, CGFLOAT_MAX) limitedToNumberOfLines:4 textInsets:UIEdgeInsetsMake(5, 5, 5, 0)];
    // label垂直方向约束高度top=10，另外再 + 1
    return size1.height+11;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"Cell";
    AttributedTableViewCell *cell = (AttributedTableViewCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[NSBundle mainBundle] loadNibNamed:@"AttributedTableViewCell" owner:self options:Nil] lastObject];
    }
    cell.selectionStyle = UITableViewCellSelectionStyleGray;
    cell.label.delegate = self;
    NSAttributedString *content = [self.espressos objectAtIndex:(NSUInteger)indexPath.row];
    cell.label.attributedText = content;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    //    NSLog(@"点击第 %@ 行cell",@(indexPath.row+1));
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    switch (indexPath.row) {
        case 0:
        case 2:
        case 4:
        case 6:
        {
            SecondDetailViewController *detailCtr = [[SecondDetailViewController alloc]initWithNibName:@"SecondDetailViewController" bundle:nil];
            detailCtr.index = indexPath.row;
            detailCtr.content = self.espressos[indexPath.row];
            [self.navigationController pushViewController:detailCtr animated:YES];
        }
            break;
        case 1:
        case 3:
        case 5:
        {
            FirstDetailViewController *detailCtr = [[FirstDetailViewController alloc]initWithNibName:@"FirstDetailViewController" bundle:nil];
            detailCtr.index = indexPath.row;
            detailCtr.content = self.espressos[indexPath.row];
            [self.navigationController pushViewController:detailCtr animated:YES];
        }
            
        default:
            break;
    }
    
    
}

#pragma mark - CJLabelLinkDelegate
- (void)CJLable:(CJLabel *)label didClickLink:(CJLabelLinkModel *)linkModel {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"点击链点" message:linkModel.attributedString.string preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil];
    [alert addAction:cancel];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)CJLable:(CJLabel *)label didLongPressLink:(CJLabelLinkModel *)linkModel {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"长按链点" message:linkModel.attributedString.string preferredStyle:UIAlertControllerStyleActionSheet];
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil];
    [alert addAction:cancel];
    [self presentViewController:alert animated:YES completion:nil];
}
@end
