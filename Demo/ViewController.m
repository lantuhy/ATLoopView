
//  Created by lantu on 2018/5/16.
//  Copyright © 2018年 lantuhy. All rights reserved.
//

#import "ATLoopView.h"
#import "ViewController.h"
#import "ATScreenshots.h"

@interface ViewController () < ATLoopViewDelegate >

@property (nonatomic, readonly) ATLoopView *imageLoopView;
@property (nonatomic, readonly) ATLoopView *textLoopView;
@property (nonatomic, readonly) ATLoopView *loopView3;

@end

@interface NewsContentView : UIView

@property (nonatomic, assign) IBOutlet UILabel *groupLabel;
@property (nonatomic, assign) IBOutlet UILabel *titleLabel;

@end

@interface MovieContentView : UIView;

@property (nonatomic, assign) IBOutlet UIImageView *imageView;
@property (nonatomic, assign) IBOutlet UILabel *textLabel;

@end


@implementation ViewController
{
    NSArray<NSDictionary<NSString *, NSObject *> *> *_movies;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _movies = @[
           @{@"image" : [UIImage imageNamed:@"image1"] , @"title" : @"桃花坞里桃花庵"},
           @{@"image" : [UIImage imageNamed:@"image2"], @"title" : @"桃花庵下桃花仙"},
           @{@"image" : [UIImage imageNamed:@"image3"], @"title" : @"桃花仙人种桃树"},];
    [self.view addSubview:self.imageLoopView];
    [self.view addSubview:self.textLoopView];
    [self.view addSubview:self.loopView3];
    [_imageLoopView enableAutoScroll:YES];
    [_textLoopView enableAutoScroll:YES];
    [_loopView3 enableAutoScroll:YES];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(4.9 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        ATScreenshots *sh = [ATScreenshots new];
        sh.duration = 3.2;
        sh.view = self.view;
        sh.compressGIF = YES;
        [sh start];
    });
}

@synthesize imageLoopView = _imageLoopView;
- (ATLoopView *)imageLoopView
{
    if(_imageLoopView == nil)
    {
        _imageLoopView = [[ATLoopView alloc] init];
        _imageLoopView.autoScrollAnimationDuration = 1.0;
        NSArray<UIImage *> *images = @[
           [UIImage imageNamed:@"image4"],
           [UIImage imageNamed:@"image5"],
           [UIImage imageNamed:@"image6"],];
        ATLoopViewImageDelegate *delegate = [[ATLoopViewImageDelegate alloc] initWithImages:images contentMode:UIViewContentModeScaleAspectFit];
        [_imageLoopView setBlocksDelegate:delegate];
    }
    return _imageLoopView;
}

@synthesize textLoopView = _textLoopView;
- (ATLoopView *)textLoopView
{
    if(_textLoopView == nil)
    {
        _textLoopView = [[ATLoopView alloc] init];
        _textLoopView.backgroundColor = [UIColor colorWithRed:0.97 green:0.99 blue:1.0 alpha:1.0];
        _textLoopView.scrollDirection = ATLoopViewScrollDirectionVertical;
        _textLoopView.pageIndicatorHidden = YES;
        _textLoopView.autoScrollAnimationDuration = 1.0;
        _textLoopView.autoScrollTimeInterval = 6.0;
        
        ATLoopViewBlocksDelegate *delegate = [ATLoopViewBlocksDelegate new];
        [_textLoopView setBlocksDelegate:delegate];
        NSArray<NSDictionary<NSString *, NSString *> *> *array =
        @[@{@"group" : @"热门", @"title" : @"酒醒只在花前坐，酒醉还来花下眠"},
          @{@"group" : @"推荐", @"title" : @"半醒半醉日复日，花落花开年复年"},
          @{@"group" : @"最新", @"title" : @"别人笑我太疯癫，我笑他人看不穿"},];
        delegate.numberOfPages = ^NSInteger{
            return array.count;
        };
        delegate.contentViewForLoopView = ^UIView * _Nonnull{
            NSArray<UIView *> *views = [[NSBundle mainBundle] loadNibNamed:@"NewsContentView" owner:nil options:nil];
            return views.firstObject;
        };
        delegate.shouldUpdateContentViewForPageAtIndex = ^(NewsContentView *contentView, NSInteger idx) {
            contentView.groupLabel.text = array[idx][@"group"];
            contentView.titleLabel.text = array[idx][@"title"];
        };
        delegate.didSelectPageAtIndex = ^(NSInteger idx) {
            fprintf(stderr, "点击类第%ld条新闻\r\n", (long)(idx + 1) );
        };
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
        _loopView3.autoScrollTimingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
        _loopView3.autoScrollAnimationDuration = 1.0;
        _loopView3.autoScrollTimeInterval = 7.0;
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
    CGRect textLoopViewFrame = CGRectMake(8, CGRectGetMaxY(imageLoopViewFrame) + 8, bounds.size.width - 16 , 56);
    _textLoopView.frame = textLoopViewFrame;
    _loopView3.frame = CGRectMake(0, CGRectGetMaxY(textLoopViewFrame) + 8, bounds.size.width, bounds.size.width * 0.5);
}

#pragma mark - ATLoopViewDelegate

- (NSInteger)numberOfPagesInLoopView:(ATLoopView *)loopView
{
    return _movies.count;
}

- (__kindof UIView *)contentViewForLoopView:(ATLoopView *)loopView
{
    NSArray<UIView *> *views = [[NSBundle mainBundle] loadNibNamed:@"MovieContentView" owner:nil options:nil];
    return views.firstObject;
}

- (void)loopView:(ATLoopView *)loopView shouldUpdateContentView:(__kindof UIView *)contentView forPageAtIndex:(NSInteger)index
{
    MovieContentView *movieContentView = contentView;
    movieContentView.imageView.image = (UIImage *) _movies[index][@"image"];
    movieContentView.textLabel.text = (NSString *)_movies[index][@"title"];
}

- (void)loopView:(ATLoopView *)loopView didSelectPageAtIndex:(NSInteger)index
{
}

@end


@implementation NewsContentView

@end

@implementation MovieContentView

@end
