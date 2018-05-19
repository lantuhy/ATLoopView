
//  Created by lantu on 2018/5/16.
//  Copyright © 2018年 lantuhy. All rights reserved.
//

#import "ATLoopView.h"
#import "ViewController.h"

@interface ViewController () < ATLoopViewDelegate >

@property (nonatomic, readonly) ATLoopView *imageLoopView;
@property (nonatomic, readonly) ATLoopView *textLoopView;
@property (nonatomic, readonly) ATLoopView *loopView3;

@end

@interface LoopViewContentLabel : UILabel

@end

@interface LoopViewCustomContentView : UIView;

@property (nonatomic, assign) IBOutlet UIImageView *imageView;
@property (nonatomic, assign) IBOutlet UILabel *textLabel;

@end


@implementation ViewController
{
    NSArray<UIImage *> *_images;
    NSArray<NSString *> *_strings;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _images = @[[UIImage imageNamed:@"image1"],
                [UIImage imageNamed:@"image2"],
                [UIImage imageNamed:@"image3"],];
    _strings = @[@"桃花坞里桃花庵，",
                 @"桃花庵下桃花仙；",
                 @"桃花仙人种桃树，",
                 @"又摘桃花卖酒钱。",];
    [self.view addSubview:self.imageLoopView];
    [self.view addSubview:self.textLoopView];
    [self.view addSubview:self.loopView3];
    [_imageLoopView enableAutoScroll:YES];
    [_textLoopView enableAutoScroll:YES];
    [_loopView3 enableAutoScroll:YES];
}

@synthesize imageLoopView = _imageLoopView;
- (ATLoopView *)imageLoopView
{
    if(_imageLoopView == nil)
    {
        _imageLoopView = [[ATLoopView alloc] init];
        [_imageLoopView registerClassForContentView:[UIImageView class]];
        _imageLoopView.currentPageIndicatorColor = [UIColor colorWithRed:0 green:0.75 blue:1.0 alpha:0.9];
        _imageLoopView.autoScrollAnimationDuration = 1.0;
        
        NSArray<UIImage *> *images =@[
                    [UIImage imageNamed:@"image4"],
                    [UIImage imageNamed:@"image5"],
                    [UIImage imageNamed:@"image4"],];
        _imageLoopView.numberOfPages = ^NSInteger{
            return images.count;
        };
        _imageLoopView.shouldUpdateContentViewForPageAtIndex = ^(UIImageView *contentView, NSInteger idx){
          
            contentView.contentMode = UIViewContentModeScaleAspectFill;
            contentView.image = images[idx];
        };
        _imageLoopView.didScrollToPageAtIndex = ^(NSInteger idx) {
            fprintf(stderr, "imageLoopView didScrollToPageAtIndex : %ld\r\n", (long)idx);
        };
    }
    return _imageLoopView;
}

@synthesize textLoopView = _textLoopView;
- (ATLoopView *)textLoopView
{
    if(_textLoopView == nil)
    {
        _textLoopView = [[ATLoopView alloc] init];
        [_textLoopView registerClassForContentView:[LoopViewContentLabel class]];
        _textLoopView.backgroundColor = [UIColor colorWithRed:0.97 green:0.99 blue:1.0 alpha:1.0];
        _textLoopView.scrollDirection = ATLoopViewScrollDirectionVertical;
        _textLoopView.pageIndicatorHidden = YES;
        _textLoopView.autoScrollAnimationDuration = 1.0;
        _textLoopView.autoScrollTimeInterval = 6.0;
        _textLoopView.delegate = self;
    }
    return _textLoopView;
}

@synthesize loopView3 = _loopView3;
- (ATLoopView *)loopView3
{
    if(_loopView3 == nil)
    {
        _loopView3 = [[ATLoopView alloc] init];
        _loopView3.currentPageIndicatorColor = [UIColor colorWithRed:0 green:0.75 blue:1.0 alpha:0.9];
        [_loopView3 registerNibForContentView:[UINib nibWithNibName:@"LoopViewCustomContentView" bundle:nil]];
        _loopView3.autoScrollTimingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
        _loopView3.autoScrollTimeInterval = 5.0;
        _loopView3.delegate = self;
    }
    return _loopView3;
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    
    CGRect bounds = self.view.bounds;
    CGRect imageLoopViewFrame = CGRectMake(0, 0, bounds.size.width, bounds.size.width * 0.5);
    _imageLoopView.frame = imageLoopViewFrame;
    CGRect textLoopViewFrame = CGRectMake(0, CGRectGetMaxY(imageLoopViewFrame), bounds.size.width, 80);
    _textLoopView.frame = textLoopViewFrame;
    _loopView3.frame = CGRectMake(0, CGRectGetMaxY(textLoopViewFrame), bounds.size.width, bounds.size.width * 0.5);
}

#pragma mark - ATLoopViewDelegate

- (NSInteger)numberOfPagesInLoopView:(ATLoopView *)loopView
{
    if(loopView == _textLoopView)
        return _strings.count;
    else if(loopView == _loopView3)
        return _images.count;
    return 0;
}

- (void)loopView:(ATLoopView *)loopView shouldUpdateContentView:(__kindof UIView *)contentView forPageAtIndex:(NSInteger)index
{
    if(loopView == _textLoopView)
    {
        LoopViewContentLabel *label = contentView;
        label.text = _strings[index];
    }
    else if(loopView == _loopView3)
    {
        LoopViewCustomContentView *theContentView = contentView;
        theContentView.imageView.image = _images[index];
        theContentView.textLabel.text = _strings[index % _strings.count];
    }
}

- (void)loopView:(ATLoopView *)loopView didScrollToPageAtIndex:(NSInteger)index
{
}

- (void)loopView:(ATLoopView *)loopView didSelectPageAtIndex:(NSInteger)index
{
    const char *which = loopView == _textLoopView ? "textLoopView" : "loopView3";
    fprintf(stderr, "%s, didSelectPageAtIndex : %ld\r\n", which, (long)index);
}

@end


@implementation LoopViewContentLabel

- (instancetype)initWithFrame:(CGRect)frame
{
    if(self = [super initWithFrame:frame])
    {
        self.textColor = [UIColor darkGrayColor];
        self.font = [UIFont systemFontOfSize:32.0];
        self.textAlignment = NSTextAlignmentCenter;
    }
    return self;
}

@end

@implementation LoopViewCustomContentView

@end
