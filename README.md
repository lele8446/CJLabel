# CJLabel

## 功能简介

 * CJLabel 继承自 UILabel，其文本绘制基于NSAttributedString实现，同时增加了图文混排、富文本展示以及添加自定义点击链点并设置点击链点文本属性的功能。
 *
 *
 * CJLabel 与 UILabel 不同点：
 *
   1. `- init` 不可直接调用init初始化，请使用`initWithFrame:` 或 `initWithCoder:`，以便完成相关初始属性设置
 
   2. `attributedText` 与 `text` 均可设置文本，注意 [self setText:text]中 text类型只能是NSAttributedString或NSString
 
   3. `NSAttributedString`不再通过`NSTextAttachment`显示图片（使用`NSTextAttachment`不会起效），请调用
      `- configureAttributedString: addImageName: imageSize: atIndex: attributes:`或者
      `- configureLinkAttributedString: addImageName: imageSize: atIndex: linkAttributes: activeLinkAttributes: parameter: clickLinkBlock: longPressBlock:`方法添加图片
 
   4. 新增`extendsLinkTouchArea`， 设置是否加大点击响应范围，类似于UIWebView的链点点击效果
 
   5. 新增`shadowRadius`， 设置文本阴影模糊半径，可与 `shadowColor`、`shadowOffset` 配合设置，注意改设置将对全局文本起效
 
   6. 新增`textInsets` 设置文本内边距
 
   7. 新增`verticalAlignment` 设置垂直方向的文本对齐方式
   
   8. 新增`delegate` 点击链点代理
 *
 *
 * CJLabel 已知bug：
 *
   `numberOfLines`大于0且小于实际`label.numberOfLines`，同时`verticalAlignment`不等于`CJContentVerticalAlignmentTop`时，文本显示位置有偏差

<br/>

## 使用方法
### 一、引用CJLabel
下载demo，将CJLabel文件夹导入项目，引用头文件`#import "CJLabel.h"`
### 二、CocoaPods安装
* Podfile<br/>
```ruby
platform :ios, '7.0'
pod 'CJLabel', '~> 2.1.2'
```

包含NSString+CJString与CJLabel两个文件
#### NSString+CJString
NSString类别
  * `-getNSAttributedString: labelDict:`<br/>
  NSMutableAttributedString属性封装方法

  ```objective-c
  NSDictionary *dic = @{
                        NSFontAttributeName:[UIFont systemFontOfSize:20],/*(字体)*/
                        NSForegroundColorAttributeName:[UIColor blackColor],/*(字体颜色)*/
                       };
  NSMutableAttributedString *labelTitle = [NSString getNSAttributedString:@"this is test string" labelDict:dic];
  ```
  * `-sizeLabelToFit: width: height:`<br/>
  返回UILabel自适应后的size方法

  * `-getStringRect: width: height:`<br/>
  动态计算NSString的CGSize方法

#### CJLabel
UILabel的extension，可响应任意字符的点击
  * `-addLinkString: linkAddAttribute: block:`<br/>
  增加点击链点方法

  ```objective-c
  NSDictionary *linkDic = @{
                            NSForegroundColorAttributeName:[UIColor redColor],
                            NSUnderlineStyleAttributeName:@(NSUnderlineStyleSingle)
                          };
    
  [self.label addLinkString:@"点击" linkAddAttribute:linkDic block:^(CJLinkLabelModel *linkModel) {
      NSLog(@"点击了链接: %@",linkModel.linkString);
  }];
  ```
  * `-addLinkString: linkAddAttribute: linkParameter: block:`<br/>
  增加点击链点方法

  ```objective-c
  NSDictionary *linkDic = @{
                            NSForegroundColorAttributeName:[UIColor redColor],
                            NSUnderlineStyleAttributeName:@(NSUnderlineStyleSingle)
                          };
    
  [self.label addLinkString:@"点击" linkAddAttribute:linkDic linkParameter:@{@"id":@"1",@"type":@"text"} block:^(CJLinkLabelModel *linkModel) {
      NSLog(@"点击了链接: %@",linkModel.linkString);
  }];
  ```
  * `-removeLinkString:`<br/>
  移除点击链点方法

  * `-removeAllLink`<br/>
  移除所有点击链点方法

## cocoapods安装
* Podfile<br/>
```ruby
platform :ios, '7.0'
pod 'CJLabel', '~> 1.0.3'
```

## V1.0.0
v1.0.0版本注意：文本内存在相同链点时只有首次出现的链点能够响应点击

<br/>
## V1.0.1
*  增加文本中内容相同的链点能够响应点击属性sameLinkEnable，必须在设置self.attributedText前赋值，默认值为NO，只取文本中首次出现的链点。<br/>
*  CJLinkLabelModel的linkString改为NSString类型<br/>

<br/>
## V1.0.2
* 点击链点增加扩展属性parameter<br/>
* 增加方法`- addLinkString: linkAddAttribute: linkParameter: block:`
