//
//  AttributedTableViewCell.h
//  tableViewLabel
//
//  Created by YiChe on 16/4/19.
//  Copyright © 2016年 YiChe. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CJLabel.h"

#define ScreenWidth [[UIScreen mainScreen] bounds].size.width


@interface AttributedTableViewCell : UITableViewCell
@property (nonatomic,weak)IBOutlet CJLabel *label;

@end
