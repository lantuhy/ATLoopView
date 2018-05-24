
//  Created by lantu on 2018/5/11.
//  Copyright © 2018年 lantu. All rights reserved.
//

#import "ATPageControl.h"
#import "ATLoopView.h"


typedef struct AnimationPacingBuilder AnimationPacingBuilder;

static AnimationPacingBuilder* AnimationPacingBuilderCreate(void);
static void AnimationPacingBuilderInitialize(AnimationPacingBuilder *abp, CAMediaTimingFunction *timingFuction, NSTimeInterval duration);
static float AnimationPacingBuilderGetPacing(AnimationPacingBuilder *abp, NSTimeInterval time);
static void AnimationPacingBuilderRelease(AnimationPacingBuilder *apb);


@class _ATLoopScrollView;

@protocol _ATLoopScrollViewDelegate < UIScrollViewDelegate >

- (__kindof UIView *)contentViewForScrollView:(_ATLoopScrollView *)scorllView;
- (void)scrollView:(_ATLoopScrollView *)scrollView shouldUpdateContentView:(UIView *)contentView atIndex:(NSInteger)index;
- (void)scrollView:(_ATLoopScrollView *)scrollView pageChanged:(NSInteger)newPage oldValue:(NSInteger)oldPage;
- (void)scrollView:(_ATLoopScrollView *)scrollView contentOffsetChanged:(CGPoint)newContentOffset oldValue:(CGPoint)oldContentOffset;

@end


@interface _ATLoopScrollView : UIScrollView

@property (nonatomic) ATLoopViewScrollDirection scrollDirection;

- (void)reloadContentViews;

@end

@interface ATLoopView () <_ATLoopScrollViewDelegate>

@property (nonatomic) NSInteger numberOfPages;
@property (nonatomic) NSInteger currentPage;
@property (nonatomic) BOOL needsReloadData;

@end

static inline CGFloat DirectionOffset(CGPoint point, ATLoopViewScrollDirection direction)
{
    return direction == ATLoopViewScrollDirectionHorizontal ? point.x : point.y;
}
static inline CGFloat DirectionWidth(CGSize size, ATLoopViewScrollDirection direction)
{
    return direction == ATLoopViewScrollDirectionHorizontal ? size.width : size.height;
}

@implementation ATLoopView
{
    _ATLoopScrollView *_scrollView;
    
    NSTimer *_autoScrollTimer;
    AnimationPacingBuilder *_animationPaingBulider;
    
    CADisplayLink *_displayLink;
    NSTimeInterval _animationStartTimestamp;
    
    struct ProtocolResponds
    {
        bool didSelectPage : 1;
        bool didScrollToPage : 1;
        bool updatePageTransitionPercent : 1;
    }_protocolResponds;
    ATLoopViewBlocksDelegate *_blocksDelegate;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    if(self = [super initWithFrame:frame])
        [self initialize];
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    if(self = [super initWithCoder:aDecoder])
        [self initialize];
    return self;
}

- (void)initialize
{
    _needsReloadData = YES;
    
    _scrollView = [[_ATLoopScrollView alloc] init];
    _scrollView.pagingEnabled = YES;
    _scrollView.delegate = self;
    _scrollView.scrollDirection = ATLoopViewScrollDirectionHorizontal;
    [self addSubview:_scrollView];
    
    _autoScrollTimeInterval = 5.0;
    _autoScrollAnimationDuration = 0.25;
}

- (void)dealloc
{
    AnimationPacingBuilderRelease(_animationPaingBulider);
}

- (void)setPageControl:(UIView<ATPageControl> *)pageControl
{
    _pageControl = pageControl;
    [self addSubview:_pageControl];
    _protocolResponds.updatePageTransitionPercent = [_pageControl respondsToSelector:@selector(updatePageTransitionPercent:)];
}

@synthesize delegate = _delegate;
- (void)setDelegate:(id<ATLoopViewDelegate>)delegate
{
    _delegate = delegate;
    if(_delegate)
    {
        _protocolResponds.didSelectPage = [_delegate respondsToSelector:@selector(loopView:didSelectPageAtIndex:)];
        _protocolResponds.didScrollToPage = [_delegate respondsToSelector:@selector(loopView:didScrollToPageAtIndex:)];
    }
}

- (void)setBlocksDelegate:(ATLoopViewBlocksDelegate *)delegate
{
    _blocksDelegate = delegate;
    self.delegate = delegate;
}

@dynamic scrollDirection;
- (void)setScrollDirection:(ATLoopViewScrollDirection)scrollDirection
{
    _scrollView.scrollDirection = scrollDirection;
}

- (ATLoopViewScrollDirection)scrollDirection
{
    return _scrollView.scrollDirection;
}

- (void)setAutoScrollAnimationDuration:(NSTimeInterval)duration
{
    _autoScrollAnimationDuration = duration < 0.25 ? 0.25 : duration;
}

- (CAMediaTimingFunction *)autoScrollTimingFunction
{
    if(_autoScrollTimingFunction == nil)
        _autoScrollTimingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn];
    return _autoScrollTimingFunction;
}

- (void)enableAutoScroll:(BOOL)enable
{
    if(enable)
    {
        if(_animationPaingBulider == nil)
            _animationPaingBulider = AnimationPacingBuilderCreate();
        AnimationPacingBuilderInitialize(_animationPaingBulider, self.autoScrollTimingFunction, _autoScrollAnimationDuration);
        if(_autoScrollTimer == nil)
        {
            _autoScrollTimer = [NSTimer timerWithTimeInterval:_autoScrollTimeInterval target:self selector:@selector(handleTimer:) userInfo:nil repeats:YES];
            [[NSRunLoop mainRunLoop] addTimer:_autoScrollTimer forMode:NSRunLoopCommonModes];
            
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleApplicationNotification:) name:UIApplicationWillResignActiveNotification object:nil];
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleApplicationNotification:) name:UIApplicationDidBecomeActiveNotification object:nil];
        }
    }
    else{
        [_autoScrollTimer invalidate];
        _autoScrollTimer = nil;
        [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillResignActiveNotification object:nil];
        [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
    }
}

- (void)setNumberOfPages:(NSInteger)numberOfPages
{
    _numberOfPages = numberOfPages;
    if(_pageControl)
    {
        if(_numberOfPages != _pageControl.numberOfPages)
        {
            _pageControl.numberOfPages = numberOfPages;
            [self setNeedsLayout];
        }
        _pageControl.numberOfPages = numberOfPages;
        _pageControl.hidden = numberOfPages <= 1;
        if(_protocolResponds.updatePageTransitionPercent)
            [_pageControl updatePageTransitionPercent:0.0];
    }
    self.currentPage = 0;
}

- (void)setCurrentPage:(NSInteger)currentPage
{
    _currentPage = currentPage;
    _pageControl.currentPage = currentPage;
    if(_protocolResponds.didScrollToPage)
        [_delegate loopView:self didScrollToPageAtIndex:_currentPage];
}

- (void)reloadData
{
    _needsReloadData = YES;
    [self reloadDataIfNeeds];
}

- (void)reloadDataIfNeeds
{
    if(_needsReloadData && _delegate && _displayLink == nil && !CGSizeEqualToSize(self.bounds.size, CGSizeZero))
    {
        [_autoScrollTimer setFireDate:[NSDate dateWithTimeIntervalSinceNow:_autoScrollTimeInterval]];
        self.numberOfPages = [_delegate numberOfPagesInLoopView:self];
        _scrollView.scrollEnabled = _numberOfPages > 1;
        [_scrollView reloadContentViews];
        _needsReloadData = NO;
    }
}

- (void)removeFromSuperview
{
    [super removeFromSuperview];
    [_displayLink invalidate];
    _displayLink = nil;
    [self enableAutoScroll:NO];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    CGRect bounds = self.bounds;
    _scrollView.frame = CGRectMake(0, 0, bounds.size.width, bounds.size.height);
    CGSize size = [_pageControl sizeThatFits:bounds.size];
    _pageControl.frame = CGRectMake(bounds.size.width - size.width, CGRectGetMaxY(bounds) - size.height, size.width, size.height);
    
    [self reloadDataIfNeeds];
}

- (void)handleTimer:(NSTimer *)sender
{
    if(sender == _autoScrollTimer)
    {
        if(_numberOfPages < 1 || _scrollView.isDragging || _scrollView.isDecelerating || _scrollView.isTracking)
            return;
        if(_displayLink == nil)
        {
            _displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(handleDisplayLink:)];
            [_displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
            _animationStartTimestamp = 0;
            _scrollView.userInteractionEnabled = NO;
        }
    }
}

- (void)handleDisplayLink:(CADisplayLink *)sender
{
    NSTimeInterval timestamp = sender.timestamp;
    if(_animationStartTimestamp <= 0)
        _animationStartTimestamp = timestamp - sender.duration;
    float animPacing = AnimationPacingBuilderGetPacing(_animationPaingBulider, timestamp - _animationStartTimestamp);
    _scrollView.contentOffset = _scrollView.scrollDirection == ATLoopViewScrollDirectionHorizontal ?
    CGPointMake(self.bounds.size.width * (1 + animPacing), 0) :
    CGPointMake(0, self.bounds.size.height * (1 + animPacing));
    if(animPacing == 1.0)
    {
        [_displayLink invalidate];
        _displayLink = nil;
        _scrollView.userInteractionEnabled = YES;
        if(_needsReloadData)
            [self reloadDataIfNeeds];
    }
}

- (void)handleApplicationNotification:(NSNotification *)sender
{
    NSString *name = sender.name;
    if([name isEqualToString:UIApplicationWillResignActiveNotification])
        _autoScrollTimer.fireDate = [NSDate distantFuture];
    else if([name isEqualToString:UIApplicationDidBecomeActiveNotification])
        _autoScrollTimer.fireDate = [NSDate dateWithTimeIntervalSinceNow:_autoScrollTimeInterval];
}

#pragma mark

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [_autoScrollTimer setFireDate:[NSDate dateWithTimeIntervalSinceNow:_autoScrollTimeInterval]];
    if(_protocolResponds.didSelectPage)
        [_delegate loopView:self didSelectPageAtIndex:_currentPage];
}

#pragma mark - _ATLoopScrollViewDelegate

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    if(!decelerate)
        [_autoScrollTimer setFireDate:[NSDate dateWithTimeIntervalSinceNow:_autoScrollTimeInterval]];
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    [_autoScrollTimer setFireDate:[NSDate dateWithTimeIntervalSinceNow:_autoScrollTimeInterval]];
}

- (__kindof UIView *)contentViewForScrollView:(_ATLoopScrollView *)scorllView
{
    return [_delegate contentViewForLoopView:self];
}

- (void)scrollView:(_ATLoopScrollView *)scrollView shouldUpdateContentView:(UIView *)contentView atIndex:(NSInteger)index
{
    if(_numberOfPages > 0)
    {
        NSInteger currentPage = _currentPage;
        NSInteger page = index == 0 ? currentPage - 1 : index == 1 ? currentPage : currentPage + 1;
        if(page < 0)
            page = _numberOfPages - 1;
        else if(page >= _numberOfPages)
            page = 0;
        [_delegate loopView:self shouldUpdateContentView:contentView forPageAtIndex:page];
    }
}

- (void)scrollView:(_ATLoopScrollView *)scrollView pageChanged:(NSInteger)newPage oldValue:(NSInteger)oldPage
{
    NSInteger currentPage = _currentPage;
    if(newPage < oldPage)
    {
        if(--currentPage < 0)
            currentPage = _numberOfPages - 1;
    }
    else{
        if(++currentPage == _numberOfPages)
            currentPage = 0;
    }
    self.currentPage = currentPage;
}

- (void)scrollView:(_ATLoopScrollView *)scrollView contentOffsetChanged:(CGPoint)newContentOffset oldValue:(CGPoint)oldContentOffset
{
    if(_numberOfPages > 0)
    {
        if(!_pageControl.hidden && _protocolResponds.updatePageTransitionPercent)
        {
            ATLoopViewScrollDirection scrollDirection = _scrollView.scrollDirection;
            CGRect bounds = _scrollView.bounds;
            CGFloat width = DirectionWidth(bounds.size, scrollDirection);
            CGFloat newOffset = DirectionOffset(newContentOffset, scrollDirection);
            double transitionPercent = (newOffset - width) * 2 / width;
            if(fabs(transitionPercent) <= 1.0 && fabs(transitionPercent) >= 0.0)
                [_pageControl updatePageTransitionPercent:transitionPercent];
        }
    }
}

@end


@interface _ATLoopScrollView ()

@property (nonatomic, weak) id<_ATLoopScrollViewDelegate> delegate;

@end

static const NSInteger kNumberOfContentViews = 3;

@implementation _ATLoopScrollView
{
    NSMutableArray<UIView *> *_contentViews;
    BOOL _contentViewsNeedsUpdate[kNumberOfContentViews];
}

- (instancetype)initWithFrame:(CGRect)frame
{
    if(self = [super initWithFrame:frame])
    {
        self.showsVerticalScrollIndicator = NO;
        self.showsHorizontalScrollIndicator = NO;
    }
    return self;
}

@dynamic delegate;

- (void)setFrame:(CGRect)frame
{
    CGRect previousFrame = self.frame;
    [super setFrame:frame];
    if(!CGSizeEqualToSize(previousFrame.size, frame.size))
    {
        self.contentSize = _scrollDirection == ATLoopViewScrollDirectionHorizontal ?
            CGSizeMake(frame.size.width * kNumberOfContentViews, frame.size.height) :
            CGSizeMake(frame.size.width, frame.size.height * kNumberOfContentViews);
        [self layoutContentViews];
        if(previousFrame.size.width != 0 && previousFrame.size.height != 0)
        {
            CGPoint contentOffset = self.contentOffset;
            self.contentOffset = _scrollDirection == ATLoopViewScrollDirectionHorizontal ?
                CGPointMake(contentOffset.x * frame.size.width / previousFrame.size.width, 0) :
                CGPointMake(0, contentOffset.y * frame.size.height / previousFrame.size.height);
        }
    }
}

- (void)reloadContentViews
{
    for(NSInteger i = 0; i < kNumberOfContentViews; ++i)
        _contentViewsNeedsUpdate[i] = YES;
    if(_contentViews == nil)
    {
        _contentViews = [[NSMutableArray alloc] initWithCapacity:kNumberOfContentViews];
        for(NSInteger i = 0; i < kNumberOfContentViews; ++i)
        {
            UIView *contentView = [self.delegate contentViewForScrollView:self];
            [self addSubview:contentView];
            _contentViews[i] = contentView;
        }
        [self layoutContentViews];
        [self adjustContentOffsetToMiddle];
    }
    [self updateContentViewsIfNeeded];
}

- (void)updateContentViewsIfNeeded
{
    NSInteger idx = 0;
    for(UIView *contentView in _contentViews)
    {
        if(_contentViewsNeedsUpdate[idx])
        {
            [self.delegate scrollView:self shouldUpdateContentView:contentView atIndex:idx];
            _contentViewsNeedsUpdate[idx] = NO;
        }
        ++idx;
    }
}

- (void)layoutContentViews
{
    CGRect bounds = self.bounds;
    NSInteger idx = 0;
    for(UIView *contentView in _contentViews)
    {
        contentView.frame = _scrollDirection == ATLoopViewScrollDirectionHorizontal ?
            CGRectMake(bounds.size.width * idx, 0, bounds.size.width, bounds.size.height) :
            CGRectMake(0, bounds.size.height * idx, bounds.size.width, bounds.size.height);
        ++idx;
    }
}

- (void)adjustContentOffsetToMiddle
{
    CGRect bounds = self.bounds;
    CGPoint contentOffset = _scrollDirection == ATLoopViewScrollDirectionHorizontal ?
        CGPointMake(bounds.size.width, 0) :
        CGPointMake(0, bounds.size.height);
    super.contentOffset = contentOffset;
}

- (void)setContentOffset:(CGPoint)contentOffset
{
    CGPoint oldContentOffset = self.contentOffset;
    [super setContentOffset:contentOffset];
    
    [self.delegate scrollView:self contentOffsetChanged:contentOffset oldValue:oldContentOffset];
    if(_contentViews)
    {
        CGFloat oldOffset = DirectionOffset(oldContentOffset, _scrollDirection);
        CGFloat newOffset = DirectionOffset(contentOffset, _scrollDirection);
        CGFloat width = DirectionWidth(self.bounds.size, _scrollDirection);
        
        NSInteger oldPage = floor((oldOffset + width / 2) / width);
        NSInteger newPage = floor((newOffset + width / 2) / width);
        if(newPage != oldPage)
            [self.delegate scrollView:self pageChanged:newPage oldValue:oldPage];
        
        if( (oldOffset > 0 && newOffset <= 0) || (oldOffset < 2 * width && newOffset >= 2 * width) )
        {
            if(newOffset == 0)
            {
                UIView *contentView2 = _contentViews[2];
                _contentViews[2] = _contentViews[1];
                _contentViews[1] = _contentViews[0];
                _contentViews[0] = contentView2;
                _contentViewsNeedsUpdate[0] = YES;
            }
            else {
                UIView *contentView0 = _contentViews[0];
                _contentViews[0] = _contentViews[1];
                _contentViews[1] = _contentViews[2];
                _contentViews[2] = contentView0;
                _contentViewsNeedsUpdate[2] = YES;
            }
            [self layoutContentViews];
            [self adjustContentOffsetToMiddle];
            [self updateContentViewsIfNeeded];
        }
    }
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [super touchesEnded:touches withEvent:event];
    [self.superview touchesEnded:touches withEvent:event];
}

@end


@implementation ATLoopViewBlocksDelegate

- (NSInteger)numberOfPagesInLoopView:(ATLoopView *)loopView
{
    return  _numberOfPages();
}

- (__kindof UIView *)contentViewForLoopView:(ATLoopView *)loopView
{
    return _contentViewForLoopView();
}

- (void)loopView:(ATLoopView *)loopView shouldUpdateContentView:(nonnull __kindof UIView *)contentView forPageAtIndex:(NSInteger)index
{
    _shouldUpdateContentViewForPageAtIndex(contentView, index);
}

- (void)loopView:(ATLoopView *)loopView didScrollToPageAtIndex:(NSInteger)index
{
    if(_didScrollToPageAtIndex)
        _didScrollToPageAtIndex(index);
}

- (void)loopView:(ATLoopView *)loopView didSelectPageAtIndex:(NSInteger)index
{
    if(_didSelectPageAtIndex)
        _didSelectPageAtIndex(index);
}

@end

@implementation ATLoopViewImageDelegate

- (instancetype)initWithImages:(NSArray<UIImage *> *)images contentMode:(UIViewContentMode)contentMode
{
    if(self = [super init])
    {
        _images = [images copy];
        _contentMode = contentMode;
    }
    return self;
}

- (NSInteger)numberOfPagesInLoopView:(ATLoopView *)loopView
{
    return _images.count;
}

- (__kindof UIView *)contentViewForLoopView:(ATLoopView *)loopView
{
    UIImageView *imageView = [[UIImageView alloc] init];
    imageView.contentMode = _contentMode;
    return imageView;
}

- (void)loopView:(ATLoopView *)loopView shouldUpdateContentView:(UIImageView *)contentView forPageAtIndex:(NSInteger)index
{
    contentView.image = _images[index];
}

@end

//
struct AnimationPacingBuilder
{
    float c1x, c1y, c2x, c2y;       // Bezizer曲线控制点
    /* 动画时间duration等分为sampleCount个时间点，由给定的Bezier曲线计算出每个时间点对应的动画进度,结果存入数组sampleValues
     */
    NSInteger sampleCount;
    float *sampleValues;
};

AnimationPacingBuilder* AnimationPacingBuilderCreate(void)
{
    AnimationPacingBuilder *apb = (AnimationPacingBuilder *)malloc(sizeof(AnimationPacingBuilder));
    if(apb)
        memset(apb, 0, sizeof(AnimationPacingBuilder));
    return apb;
}

static inline float BezierValue(float v1, float v2, float t)
{
    // bezier曲线公式
    return 3 * v1 * t * (1 - t) * (1 - t) + 3 * v2 * t * t * (1 - t) + t * t * t;
}

static const NSInteger kSampleCountPerSecond = 120;

void AnimationPacingBuilderInitialize(AnimationPacingBuilder *apb, CAMediaTimingFunction *funtion, NSTimeInterval duration)
{
    float cp1[2], cp2[2];
    [funtion getControlPointAtIndex:1 values:cp1];
    [funtion getControlPointAtIndex:2 values:cp2];
    NSInteger sampleCount = floorf(duration * kSampleCountPerSecond);
    if(apb->c1x == cp1[0] && apb->c1y == cp1[1] && apb->c2x == cp2[0] && apb->c2y == cp2[1] && apb->sampleCount == sampleCount)
        return;
    apb->c1x = cp1[0];
    apb->c1y = cp1[1];
    apb->c2x = cp2[0];
    apb->c2y = cp2[1];
    
    free(apb->sampleValues);
    apb->sampleCount = sampleCount;
    apb->sampleValues = (float *)malloc(sampleCount * sizeof(float));
    // 计算每个时刻的动画进度
    for(NSInteger i = 1; i <= sampleCount; ++i)
    {
        // 二分法求t
        float x = (float)(i) / sampleCount;
        float t0 = 0.0, t1 = 1.0, t = 0.0;
        while(t0 < t1)
        {
            t = (t0 + t1) / 2;
            float value = BezierValue(apb->c1x, apb->c2x, t);
            // 误差 < 0.0001
            if(fabsf(x - value) < 0.001)
                break;
            if(x < value)
                t1 = t;
            else
                t0 = t;
        }
        apb->sampleValues[i - 1] = BezierValue(apb->c1y, apb->c2y, t);
    }
    apb->sampleValues[sampleCount - 1] = 1.0;
}

float AnimationPacingBuilderGetPacing(AnimationPacingBuilder *abp, NSTimeInterval time)
{
    NSInteger idx = roundf(time * kSampleCountPerSecond);
    if(idx > abp->sampleCount)
        idx = abp->sampleCount;
    float pacing = abp->sampleValues[idx - 1];
    return pacing;
}

void AnimationPacingBuilderRelease(AnimationPacingBuilder *apb)
{
    if(apb)
    {
        apb->sampleCount = 0;
        free(apb->sampleValues);
        apb->sampleValues = NULL;
        free(apb);
    }
}
