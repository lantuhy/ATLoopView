
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
- (void)scrollView:(_ATLoopScrollView *)scrollView shouldUpdateContentViewAtIndex:(NSInteger)index;
- (void)scrollView:(_ATLoopScrollView *)scrollView contentOffsetChangedWithNewValue:(CGPoint)contentOffsetNew oldValue:(CGPoint)contentOffsetOld;

@end


@interface _ATLoopScrollView : UIScrollView

@property (nonatomic) ATLoopViewScrollDirection scrollDirection;
@property (nonatomic) NSArray<UIView *> *contentViews;

- (void)updateContentViews;

@end

@interface ATLoopView () <_ATLoopScrollViewDelegate>

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
    ATPageControl *_pageControl;
    
    NSTimer *_autoScrollTimer;
    AnimationPacingBuilder *_animationPaingBulider;
    
    CADisplayLink *_displayLink;
    NSTimeInterval _animationStartTimestamp;
    
    struct DelegateResponds
    {
        bool didSelectPage : 1;
        bool didScrollToPage : 1;
    }_delegateResponds;
    ATLoopViewBlocksDelegate *_blocksDelegate;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    if(self = [super initWithFrame:frame])
    {
        _scrollView = [[_ATLoopScrollView alloc] init];
        _scrollView.pagingEnabled = YES;
        _scrollView.delegate = self;
        _scrollView.scrollDirection = ATLoopViewScrollDirectionHorizontal;
        [self addSubview:_scrollView];
        
        _pageControl = [[ATPageControl alloc] init];
        [self addSubview:_pageControl];
        
        _autoScrollTimeInterval = 5.0;
        _autoScrollAnimationDuration = 0.25;
    }
    return self;
}

- (void)dealloc
{
    AnimationPacingBuilderRelease(_animationPaingBulider);
}

@synthesize delegate = _delegate;
- (void)setDelegate:(id<ATLoopViewDelegate>)delegate
{
    _delegate = delegate;
    if(_delegate)
    {
        _delegateResponds.didSelectPage = [_delegate respondsToSelector:@selector(loopView:didSelectPageAtIndex:)];
        _delegateResponds.didScrollToPage = [_delegate respondsToSelector:@selector(loopView:didScrollToPageAtIndex:)];
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

- (void)setPageIndicatorHidden:(BOOL)hidden
{
    _pageIndicatorHidden = hidden;
    _pageControl.hidden = hidden;
}

@dynamic pageIndicatorColor;
@dynamic currentPageIndicatorColor;

- (id)forwardingTargetForSelector:(SEL)aSelector
{
    if(aSelector == @selector(setPageIndicatorColor:) ||
       aSelector == @selector(setCurrentPageIndicatorColor:) ||
       aSelector == @selector(pageIndicatorColor) ||
       aSelector == @selector(currentPageIndicatorColor))
        return _pageControl;
    return [super forwardingTargetForSelector:aSelector];
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

- (void)reloadData
{
    NSInteger numberOfPages = [_delegate numberOfPagesInLoopView:self];
    if(numberOfPages != _pageControl.numberOfPages)
    {
        _pageControl.numberOfPages = numberOfPages;
        [self setNeedsLayout];
    }
    _pageControl.currentPage = 0;
    _pageControl.hidden = _pageIndicatorHidden || numberOfPages <= 1;
    _scrollView.scrollEnabled = numberOfPages > 1;
    [_scrollView updateContentViews];
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
    if(!CGSizeEqualToSize(bounds.size, CGSizeZero) && _pageControl.numberOfPages == 0)
        [self reloadData];
}

- (void)handleTimer:(NSTimer *)sender
{
    if(sender == _autoScrollTimer)
    {
        if(_pageControl.numberOfPages < 1 || _scrollView.isDragging || _scrollView.isDecelerating || _scrollView.isTracking)
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
    if(_delegateResponds.didSelectPage)
    {
        NSInteger currentPage = _pageControl.currentPage;
        [_delegate loopView:self didSelectPageAtIndex:currentPage];
    }
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

- (void)scrollView:(_ATLoopScrollView *)scrollView shouldUpdateContentViewAtIndex:(NSInteger)index
{
    NSInteger numberOfPages = _pageControl.numberOfPages;
    if(numberOfPages > 0)
    {
        NSInteger currentPage = _pageControl.currentPage;
        NSInteger page = index == 0 ? currentPage - 1 : index == 1 ? currentPage : currentPage + 1;
        if(page < 0)
            page = numberOfPages - 1;
        else if(page >= numberOfPages)
            page = 0;
        [_delegate loopView:self shouldUpdateContentView:_scrollView.contentViews[index] forPageAtIndex:page];
    }
}

- (void)scrollView:(_ATLoopScrollView *)scrollView contentOffsetChangedWithNewValue:(CGPoint)contentOffsetNew oldValue:(CGPoint)contentOffsetOld;
{
    CGRect bounds = _scrollView.bounds;
    NSInteger numberOfPages = _pageControl.numberOfPages;
    if(numberOfPages > 0)
    {
        ATLoopViewScrollDirection scrollDirection = _scrollView.scrollDirection;
        CGFloat width = DirectionWidth(bounds.size, scrollDirection);
        CGFloat offsetOld = DirectionOffset(contentOffsetOld, scrollDirection);
        CGFloat offsetNew = DirectionOffset(contentOffsetNew, scrollDirection);
        
        NSInteger currentPage = _pageControl.currentPage;
        BOOL currentPageChanged = NO;
        if(offsetOld <= width * 1.5 &&  offsetNew > width * 1.5)
        {
            if(++currentPage >= numberOfPages)
                currentPage = 0;
            _pageControl.currentPage = currentPage;
            currentPageChanged = YES;
        }
        if(offsetOld >= width * 0.5 && offsetNew < width * 0.5 )
        {
            if(--currentPage < 0)
                currentPage = numberOfPages - 1;
            _pageControl.currentPage = currentPage;
            currentPageChanged = YES;
        }
        if(currentPageChanged && _delegateResponds.didScrollToPage)
            [_delegate loopView:self didScrollToPageAtIndex:currentPage];
        
        if(!_pageControl.hidden)
        {
            float transitionProgress = (offsetNew - width) * 2 / width;
            if(fabsf(transitionProgress) <= 1.0 && fabsf(transitionProgress) >= 0.0)
                [_pageControl updateTransitionProgress:transitionProgress];
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
    BOOL _layoutingContentViews;
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
    }
}

- (void)layoutContentViews
{
    _layoutingContentViews = YES;
    CGRect bounds = self.bounds;
    if(DirectionWidth(bounds.size, _scrollDirection) > 0)
    {
        if(_contentViews == nil)
        {
            _contentViews = [[NSMutableArray alloc] initWithCapacity:kNumberOfContentViews];
            for(NSInteger i = 0; i < kNumberOfContentViews; ++i)
            {
                UIView *contentView = [self.delegate contentViewForScrollView:self];
                [self addSubview:contentView];
                _contentViews[i] = contentView;
            }
        }
        
        NSInteger i = 0;
        for(UIView *contentView in _contentViews)
        {
            contentView.frame = _scrollDirection == ATLoopViewScrollDirectionHorizontal ?
            CGRectMake(bounds.size.width * i, 0, bounds.size.width, bounds.size.height) :
            CGRectMake(0, bounds.size.height * i, bounds.size.width, bounds.size.height);
            ++i;
        }
        
        self.contentOffset = _scrollDirection == ATLoopViewScrollDirectionHorizontal ?
        CGPointMake(bounds.size.width, 0) : CGPointMake(0, bounds.size.height);
    }
    _layoutingContentViews = NO;
}

- (void)updateContentViews
{
    for(NSInteger i = 0; i < kNumberOfContentViews; ++i)
        _contentViewsNeedsUpdate[i] = YES;
    if(DirectionOffset(self.contentOffset, _scrollDirection) == DirectionWidth(self.bounds.size, _scrollDirection))
        [self updateContentViewsIfNeeded];
}

- (void)updateContentViewsIfNeeded
{
    for(NSInteger i = 0; i < kNumberOfContentViews; ++i)
    {
        if(_contentViewsNeedsUpdate[i])
        {
            [self.delegate scrollView:self shouldUpdateContentViewAtIndex:i];
            _contentViewsNeedsUpdate[i] = NO;
        }
    }
}

- (void)setContentOffset:(CGPoint)contentOffset
{
    CGPoint contentOffsetOld = self.contentOffset;
    [super setContentOffset:contentOffset];
    
    [self.delegate scrollView:self contentOffsetChangedWithNewValue:contentOffset oldValue:contentOffsetOld];
    if(_contentViews && !_layoutingContentViews)
    {
        CGFloat offsetOld = DirectionOffset(contentOffsetOld, _scrollDirection);
        CGFloat offsetNew = DirectionOffset(contentOffset, _scrollDirection);
        CGFloat width = DirectionWidth(self.bounds.size, _scrollDirection);
        if( (offsetOld > 0 && offsetNew <= 0) || (offsetOld < 2 * width && offsetNew >= 2 * width) )
        {
            if(offsetNew == 0)
            {
                UIView *contentView2 = _contentViews[2];
                _contentViews[2] = _contentViews[1];
                _contentViews[1] = _contentViews[0];
                _contentViews[0] = contentView2;
                _contentViewsNeedsUpdate[0] = YES;
                [self layoutContentViews];
            }
            else {
                UIView *contentView0 = _contentViews[0];
                _contentViews[0] = _contentViews[1];
                _contentViews[1] = _contentViews[2];
                _contentViews[2] = contentView0;
                _contentViewsNeedsUpdate[2] = YES;
                [self layoutContentViews];
            }
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
    float progress = abp->sampleValues[idx - 1];
    return progress;
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
