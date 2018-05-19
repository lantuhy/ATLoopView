#  ATLoopView

## (图片、文字、自定义视图)循环滚动

## 示例代码
NSArray<UIImage *> *images =@[image1, image2, image3];<br>
ATLoopView *imageLoopView = [[ATLoopView alloc] init];<br>
[imageLoopView registerClassForContentView:[UIImageView class]];<br>
imageLoopView.numberOfPages = ^NSInteger{<br>
>return images.count;<br>
};
imageLoopView.shouldUpdateContentViewForPageAtIndex = ^(UIImageView *contentView, NSInteger idx){<br>
>contentView.contentMode = UIViewContentModeScaleAspectFill;<br>
>contentView.image = images[idx];<br>
};<br>

 ![image](https://github.com/lantuhy/ATLoopView/raw/master/screenshots/vim-screenshot.jpg)




