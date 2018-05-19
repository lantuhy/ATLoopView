#  ATLoopView

## (图片、文字、自定义视图)循环滚动

## 示例代码
NSArray<UIImage *> *images =@[image1, image2, image3];
ATLoopView *imageLoopView = [[ATLoopView alloc] init];
[imageLoopView registerClassForContentView:[UIImageView class]];
imageLoopView.numberOfPages = ^NSInteger{
    return images.count;
};
imageLoopView.shouldUpdateContentViewForPageAtIndex = ^(UIImageView *contentView, NSInteger idx){
    contentView.contentMode = UIViewContentModeScaleAspectFill;
    contentView.image = images[idx];
};

 ![image](https://github.com/lantuhy/ATLoopView/raw/master/screenshots/vim-screenshot.jpg)




