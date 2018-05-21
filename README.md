#  ATLoopView

## (图片、文字、自定义视图)循环滚动

### 示例代码
```Objective-C
NSArray<UIImage *> *images = @[image1, image2, image3];
ATLoopView *imageLoopView = [[ATLoopView alloc] init];
[imageLoopView registerClassForContentView:[UIImageView class]];
imageLoopView.numberOfPages = ^NSInteger{
      return images.count;
};
imageLoopView.shouldUpdateContentViewForPageAtIndex = ^(UIImageView *contentView, NSInteger idx){
      contentView.contentMode = UIViewContentModeScaleAspectFill;
      contentView.image = images[idx];
};
```

### 演示
 <img src="https://github.com/lantuhy/ATLoopView/blob/master/Screenshot/demo.gif" width="320" height="568" />




