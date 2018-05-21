#  ATLoopView

## (图片、文字、自定义视图)循环滚动

### 示例代码
```Objective-C
_imageLoopView = [[ATLoopView alloc] init];
_imageLoopView.autoScrollAnimationDuration = 1.0;
ATLoopViewImageDelegate *delegate = 
    [[ATLoopViewImageDelegate alloc] 
        initWithImages:@[image1, image2, image3] 
        contentMode:UIViewContentModeScaleAspectFit];
[_imageLoopView setBlocksDelegate:delegate];
```

### 演示
<img src="https://github.com/lantuhy/ATLoopView/blob/master/Screenshots/demo.gif" width="320" height="568" />





