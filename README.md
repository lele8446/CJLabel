# CJLabel

`CJLabel`继承自`UILabel`，在支持`UILabel`所有属性的基础上，还提供富文本、图文混排、任意view插入展示、自定义点击链点设置、长按（双击）唤起`UIMenuController`选择复制文本等功能。

## 特性简介
   1. 禁止使用`-init`初始化！！
   2. `enableCopy` 长按或双击可唤起`UIMenuController`进行选择、全选、复制文本操作   
   3. `attributedText` 与 `text` 均可设置富文本
   4. 不支持`NSAttachmentAttributeName`，`NSTextAttachment`！！<br/>显示图片请调用:<br/>
      `+ initWithView:viewSize:lineAlignment:configure:`或者<br/>
      `+ insertViewAtAttrString:view:viewSize:atIndex:lineAlignment:configure:`方法初始化`NSAttributedString`后显示
   5. `extendsLinkTouchArea`设置是否扩大链点点击识别范围 
   6. `shadowRadius`设置文本阴影模糊半径 
   7. `textInsets` 设置文本内边距
   8. `verticalAlignment` 设置垂直方向的文本对齐方式。注意与显示图片时候的`imagelineAlignment`作区分，`self.verticalAlignment`对应的是整体文本在垂直方向的对齐方式，而`imagelineAlignment`只对图片所在行的垂直对齐方式有效
   9. `delegate` 点击链点代理
   10. `attributedTruncationToken`自定义截断字符，默认"...",只针对`self.lineBreakMode`的以下三种值有效，假如`attributedTruncationToken`=`***`，则： <br/>
 `NSLineBreakByTruncatingHead,    // 头部截断: "***wxyz"`<br/>
 `NSLineBreakByTruncatingTail,    // 中间截断: "abcd***"`<br/>
 `NSLineBreakByTruncatingMiddle   // 尾部截断:  "ab***yz"`
   11. `kCJBackgroundFillColorAttributeName` 背景填充颜色，属性优先级低于`NSBackgroundColorAttributeName`如果设置`NSBackgroundColorAttributeName`会忽略`kCJBackgroundFillColorAttributeName`的设置
   12. `kCJBackgroundStrokeColorAttributeName ` 背景边框线颜色
   13. `kCJBackgroundLineWidthAttributeName ` 背景边框线宽度
   14. `kCJBackgroundLineCornerRadiusAttributeName ` 背景边框线圆角弧度
   15. `kCJActiveBackgroundFillColorAttributeName ` 点击时候的背景填充颜色属性优先级同
`kCJBackgroundFillColorAttributeName`
   16. `kCJActiveBackgroundStrokeColorAttributeName ` 点击时候的背景边框线颜色
   17. 支持添加自定义样式、可点击（长按）的文本点击链点
   18. 支持 Interface Builder


##### CJLabel 已知 Bug

   `numberOfLines`大于0且小于实际`label.numberOfLines`，同时`verticalAlignment`不等于`CJContentVerticalAlignmentTop`时，文本显示位置有偏差。如下图所示:<br/>
   <center>
 <img src="http://oz3eqyeso.bkt.clouddn.com/CJLabelBug.jpg" width="50%"/>
 </center>

## CJLabel引用
##### 1. 直接导入
下载demo，将CJLabel文件夹导入项目，引用头文件 `#import "CJLabel.h"`
##### 2. CocoaPods安装
```ruby
pod 'CJLabel'

```

## 用法
* 根据NSAttributedString计算CJLabel的size大小

```objective-c
CGSize size = [CJLabel sizeWithAttributedString:str withConstraints:CGSizeMake(320, CGFLOAT_MAX) limitedToNumberOfLines:0];
```
* 指定内边距以及限定行数计算CJLabel的size大小
```objective-c
CGSize size = [CJLabel sizeWithAttributedString:str withConstraints:CGSizeMake(320, CGFLOAT_MAX) limitedToNumberOfLines:0 textInsets:3];
```

* 设置富文本展示
<center>
 <img src="http://oz3eqyeso.bkt.clouddn.com/example0_1.png" width="50%"/>
 </center>

```objective-c
//初始化配置
CJLabelConfigure *configure = [CJLabel configureAttributes:nil isLink:NO activeLinkAttributes:nil parameter:nil clickLinkBlock:nil longPressBlock:nil];
//设置配置属性
configure.attributes = @{NSFontAttributeName:[UIFont boldSystemFontOfSize:18]};
//设置指定字符属性
attStr = [CJLabel configureAttrString:attStr withString:@"不同字体" sameStringEnable:NO configure:configure];
NSRange imgRange = [attStr.string rangeOfString:@"插入图片"];
//移除指定属性
[configure removeAttributesForKey:kCJBackgroundStrokeColorAttributeName];
//指定位置插入图片
UIImageView *imgView = [[UIImageView alloc]initWithImage:[UIImage imageNamed:@"CJLabel.png"]];
imgView.contentMode = UIViewContentModeScaleAspectFill;
imgView.clipsToBounds = YES;
attStr = [CJLabel insertViewAtAttrString:attStr view:imgView viewSize:CGSizeMake(55, 45) atIndex:(imgRange.location+imgRange.length) lineAlignment:CJVerticalAlignmentBottom configure:configure];
//设置内边距
self.label.textInsets = UIEdgeInsetsMake(10, 10, 10, 0);
self.label.attributedText = attStr;
```
* 垂直对齐、选择复制
 <center>
 <img src="http://oz3eqyeso.bkt.clouddn.com/example1.gif" width="35%"/>
 </center>

```objective-c
//设置垂直对齐方式
self.label.verticalAlignment = CJVerticalAlignmentCenter;
self.label.text = self.attStr;
//支持选择复制
self.label.enableCopy = YES;
```
* 设置文字、图片点击链点
 <center>
 <img src="http://oz3eqyeso.bkt.clouddn.com/example4.gif" width="25%"/>
 </center>

```objective-c
//设置点击链点属性
configure.attributes = @{NSForegroundColorAttributeName:[UIColor blueColor]};
//设置点击高亮属性
configure.activeLinkAttributes = @{NSForegroundColorAttributeName:[UIColor redColor]};
//链点自定义参数
configure.parameter = @"参数为字符串";
//点击回调（也可通过设置self.label.delegate = self代理，返回点击回调事件）
configure.clickLinkBlock = ^(CJLabelLinkModel *linkModel) {
   //do something
};
//长按回调
configure.longPressBlock = ^(CJLabelLinkModel *linkModel) {
   //do something
};
//设置为可点击链点
configure.isLink = YES;
//设置点击链点
attStr = [CJLabel configureAttrString:attStr
                           withString:@"CJLabel"
                     sameStringEnable:YES
                            configure:configure];
//设置图片点击链点属性
NSRange imageRange = [attStr.string rangeOfString:@"图片"];
CJLabelConfigure *imgConfigure =
[CJLabel configureAttributes:@{kCJBackgroundStrokeColorAttributeName:[UIColor redColor]}
                      isLink:YES
         activeLinkAttributes:@{kCJActiveBackgroundStrokeColorAttributeName:[UIColor lightGrayColor]}
                    parameter:@"图片参数"
               clickLinkBlock:^(CJLabelLinkModel *linkModel){
                   [self clickLink:linkModel isImage:YES];
               }
               longPressBlock:^(CJLabelLinkModel *linkModel){
                   [self clicklongPressLink:linkModel isImage:YES];
               }];
attStr = [CJLabel insertViewAtAttrString:attStr view:@"CJLabel.png" viewSize:CGSizeMake(45, 35) atIndex:(imageRange.location+imageRange.length) lineAlignment:verticalAlignment configure:imgConfigure];
self.label.attributedText = attStr;
//支持选择复制
self.label.enableCopy = YES;
```

* 自定义截断文本，并设置为可点击
 <center>
 <img src="http://oz3eqyeso.bkt.clouddn.com/example5.gif" width="28%"/>
 </center>

```objective-c
//配置链点属性
configure.isLink = YES;
configure.clickLinkBlock = ^(CJLabelLinkModel *linkModel) {
    //点击 `……全文`
    [self clickTruncationToken:linkModel];
};
configure.attributes = @{NSForegroundColorAttributeName:[UIColor blueColor],NSFontAttributeName:[UIFont systemFontOfSize:13]};
//自定义截断字符为："……全文"
NSAttributedString *truncationToken = [CJLabel initWithAttributedString:[[NSAttributedString alloc]initWithString:@"……全文"] strIdentifier:@"TruncationToken" configure:configure];
//设置行尾截断
self.label.lineBreakMode = NSLineBreakByTruncatingTail;
self.label.attributedTruncationToken = truncationToken;
//设置点击链点
attStr = [CJLabel configureAttrString:attStr withAttributedString:truncationToken strIdentifier:@"TruncationToken" sameStringEnable:NO configure:configure];            
self.label.attributedText = attStr;
//支持选择复制
self.label.enableCopy = YES;
```

## 版本说明
* ***V4.7.0***<br/>
   新增不可换行标签功能，优化图文混排展示

* ***V4.6.0***<br/>
   支持显示任意view

* ***V4.5.0 V4.5.1 V4.5.3***<br/>
   增加`attributedTruncationToken`属性，支持自定义截断字符；增加`kCJStrikethroughStyleAttributeName、kCJStrikethroughColorAttributeName`属性，可对指定文本添加删除线

* ***V4.4.0***<br/>
   优化NSAttributedString链点属性设置

* ***V4.0.0***<br/>
   新增`enableCopy`属性，支持选择、全选、复制功能，类似`UITextView`的选择复制效果。

* ***V3.0.0***<br/>
   优化富文本配置方法，新增CJLabelConfigure类，简化方法调用，增加对NSAttributedString点击链点的判断（比如对于两个重名用户：@lele 和 @lele，可以分别设置不同的点击响应事件）<br/>
   ***注意***
   ***`V3.0.0`*** 版本引入`CJLabelConfigure`类，优化了NSAttributedString的设置，旧的配置API不再支持。相关调用请参照以下相关方法<br/>
   `+ initWithImage:imageSize:imagelineAlignment:configure:`<br/>
   `+ initWithString:configure:`<br/>
   `+ initWithAttributedString:strIdentifier:configure:`<br/>

* ***V2.1.2***<br/>
   可修改图片所在行在垂直方向的对齐方式（只针对当前行），有居上、居中、居下选项，默认居下

* ***V2.1.1***<br/>
   修复单行文字时候点击链点的判断，增加delegate

* ***V2.0.0***<br/>
   优化点击链点响应判断，增加插入图片、插入图片链点、点击链点背景色填充、点击链点边框线描边等功能
    v2.0.0之后版本与v1.x.x版本差别较大，基本上重写了增加以及移除点击链点的API

* ***V1.0.2***<br/>
   点击链点增加扩展属性parameter

* ***V1.0.1***<br/>
   增加文本中内容相同的链点能够响应点击属性sameLinkEnable，必须在设置self.attributedText前赋值，默认值为NO，只取文本中首次出现的链点。

* ***V1.0.0***<br/>
  支持链点点击响应

  
## 许可证
CJLabel 使用 MIT 许可证，详情见 LICENSE 文件。

## 更多
[深入理解 iOS 图文混排原理并自定义图文控件](https://www.infoq.cn/article/cy916KUJYK7GA3p2VjZH)
[CJLabel富文本三 —— UILabel支持选择复制以及实现原理](https://www.jianshu.com/p/7de3e6d19e31)