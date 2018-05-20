#  ATLoopView

## (图片、文字、自定义视图)循环滚动

### 示例代码
```Objective-C
NSArray<UIImage *> *images =@[image1, image2, image3];
ATLoopView *imageLoopView = [[ATLoopView alloc] init];
[imageLoopView registerClassForContentView:[UIImageView class]];
imageLoopView.numberOfPages = ^NSInteger{
      return images.count;
};
imageLoopView.shouldUpdateContentViewForPageAtIndex = ^(UIImageView *contentView, NSInteger idx){<br>
      contentView.contentMode = UIViewContentModeScaleAspectFill;<br>
      contentView.image = images[idx];
};
```

 ![](https://raw.githubusercontent.com/lantuhy/ATLoopView/screenshots/screenshot.gif)




