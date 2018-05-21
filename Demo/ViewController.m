
//  Created by lantu on 2018/5/16.
//  Copyright © 2018年 lantuhy. All rights reserved.
//

#import "ATLoopView.h"
#import "ViewController.h"

@interface ViewController () < ATLoopViewDelegate >

@property (nonatomic, readonly) ATLoopView *imageLoopView;
@property (nonatomic, readonly) ATLoopView *newsLoopView;
@property (nonatomic, readonly) ATLoopView *movieLoopView;

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
    [self.view addSubview:self.newsLoopView];
    [self.view addSubview:self.loopView3];
    [_imageLoopView enableAutoScroll:YES];
    [_newsLoopView enableAutoScroll:YES];
    [_movieLoopView enableAutoScroll:YES];
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

@synthesize newsLoopView = _newsLoopView;
- (ATLoopView *)newsLoopView
{
    if(_newsLoopView == nil)
    {
        _newsLoopView = [[ATLoopView alloc] init];
        _newsLoopView.backgroundColor = [UIColor colorWithRed:0.97 green:0.99 blue:1.0 alpha:1.0];
        _newsLoopView.scrollDirection = ATLoopViewScrollDirectionVertical;
        _newsLoopView.pageIndicatorHidden = YES;
        _newsLoopView.autoScrollAnimationDuration = 1.0;
        _newsLoopView.autoScrollTimeInterval = 6.0;
        
        ATLoopViewBlocksDelegate *delegate = [ATLoopViewBlocksDelegate new];
        [_newsLoopView setBlocksDelegate:delegate];
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
    return _newsLoopView;
}

@synthesize movieLoopView = _movieLoopView;
- (ATLoopView *)loopView3
{
    if(_movieLoopView == nil)
    {
        _movieLoopView = [[ATLoopView alloc] init];
        _movieLoopView.currentPageIndicatorColor = [UIColor colorWithRed:0 green:0.75 blue:1.0 alpha:0.9];
        _movieLoopView.autoScrollTimingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
        _movieLoopView.autoScrollAnimationDuration = 1.0;
        _movieLoopView.autoScrollTimeInterval = 7.0;
        _movieLoopView.delegate = self;
    }
    return _movieLoopView;
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    
    CGRect bounds = self.view.bounds;
    CGRect imageLoopViewFrame = CGRectMake(0, 0, bounds.size.width, bounds.size.width * 0.5);
    _imageLoopView.frame = imageLoopViewFrame;
    CGRect textLoopViewFrame = CGRectMake(8, CGRectGetMaxY(imageLoopViewFrame) + 8, bounds.size.width - 16 , 56);
    _newsLoopView.frame = textLoopViewFrame;
    _movieLoopView.frame = CGRectMake(0, CGRectGetMaxY(textLoopViewFrame) + 8, bounds.size.width, bounds.size.width * 0.5);
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
