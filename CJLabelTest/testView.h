//
//  testView.h
//  CJLabelTest
//
//  Created by C.K.Lian on 15/12/22.
//  Copyright © 2015年 C.K.Lian. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CJLabel.h"

@interface testView : UIView
@property(nonatomic,weak)IBOutlet CJLabel *label;
@property(nonatomic,strong)NSMutableAttributedString *labelTitle;

- (void)setTheFrame:(CGRect)frame;
@end
