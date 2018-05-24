
//  Created by lantu on 2018/5/11.
//  Copyright © 2018年 lantu. All rights reserved.
//

#import "ATPageControl.h"


static const CGFloat DotRadius = 5.0;
static const CGFloat DotSpacing = 16.0;
static const UIEdgeInsets DotsLayoutMargins = {12, 16, 12, 16};


@interface _ATPageTransitionLayer : CAShapeLayer

@end

@implementation ATPageControl
{
    NSMutableArray<CAShapeLayer *> *_dotLayers;
    _ATPageTransitionLayer *_pageTransitionLayer;
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
    _dotLayers = [[NSMutableArray alloc] initWithCapacity:8];
    _currentPageIndicatorColor = [UIColor colorWithWhite:1.0 alpha:0.9];
    _pageIndicatorColor = [UIColor colorWithWhite:0.5 alpha:0.9];
}

- (CGSize)sizeThatFits:(CGSize)size
{
    CGSize result;
    NSInteger numberOfPages = self.numberOfPages;
    result.width
    = DotRadius * 2 * numberOfPages
    + DotSpacing * (numberOfPages > 0 ? numberOfPages - 1 : 0)
    + DotsLayoutMargins.left + DotsLayoutMargins.right;
    result.height = DotRadius * 2 + DotsLayoutMargins.top + DotsLayoutMargins.bottom;
    return result;
}

@dynamic numberOfPages;

- (NSInteger)numberOfPages
{
    return  _dotLayers.count;
}

- (void)setNumberOfPages:(NSInteger)numberOfPages
{
    if(numberOfPages > _dotLayers.count)
    {
        NSInteger insertDots = numberOfPages - _dotLayers.count;
        for(NSInteger i = 0; i < insertDots; ++i)
        {
            CAShapeLayer *shapeLayer = [[CAShapeLayer alloc] init];
            shapeLayer.bounds = CGRectMake(0, 0, DotRadius * 2, DotRadius * 2);
            CGMutablePathRef path = CGPathCreateMutable();
            CGPathAddArc(path, NULL, DotRadius, DotRadius, DotRadius, 0, M_PI * 2, NO);
            shapeLayer.path = path;
            CGPathRelease(path);
            [self.layer addSublayer:shapeLayer];
            [_dotLayers addObject:shapeLayer];
        }
    }
    else{
        for(NSInteger i = numberOfPages; i < _dotLayers.count; ++i)
            [_dotLayers[i] removeFromSuperlayer];
        [_dotLayers removeObjectsInRange:NSMakeRange(_dotLayers.count, numberOfPages - _dotLayers.count)];
    }
    
    NSInteger idx = 0;
    for(CAShapeLayer *layer in _dotLayers)
    {
        layer.fillColor = idx == _currentPage ? _currentPageIndicatorColor.CGColor : _pageIndicatorColor.CGColor;
        ++idx;
    }
}

- (void)setCurrentPage:(NSInteger)currentPage
{
    if(_dotLayers.count == 0)
        return;
    if(currentPage >= _dotLayers.count)
        currentPage = _dotLayers.count - 1;
    if(currentPage < 0)
        currentPage = 0;
    if(currentPage != _currentPage)
    {
        _dotLayers[_currentPage].fillColor = _pageIndicatorColor.CGColor;
        _currentPage = currentPage;
        _dotLayers[_currentPage].fillColor = _currentPageIndicatorColor.CGColor;
        
        _pageTransitionLayer.hidden = YES;
    }
}

- (void)setPageIndicatorColor:(UIColor *)color
{
    _pageIndicatorColor = color;
    NSInteger idx = 0;
    for(CAShapeLayer *layer in _dotLayers)
    {
        if(idx != _currentPage)
            layer.fillColor = color.CGColor;
    }
}

- (void)setCurrentPageIndicatorColor:(UIColor *)color
{
    _currentPageIndicatorColor = color;
    NSInteger idx = 0;
    for(CAShapeLayer *layer in _dotLayers)
    {
        if(idx == _currentPage)
            layer.fillColor = color.CGColor;
    }
}

- (void)updatePageTransitionPercent:(float)percent
{
    if(_pageTransitionLayer == nil)
    {
        _pageTransitionLayer = [[_ATPageTransitionLayer alloc] init];
        _pageTransitionLayer.anchorPoint = CGPointMake(0, 0.5);
        _pageTransitionLayer.cornerRadius = DotRadius;
        _pageTransitionLayer.fillColor = _currentPageIndicatorColor.CGColor;
        _pageTransitionLayer.fillRule = kCAFillRuleNonZero;
        [self.layer addSublayer:_pageTransitionLayer];
    }
    
    CGRect bounds = self.bounds;
    CGPoint layerPosition = CGPointMake(
                                        DotsLayoutMargins.left + (DotRadius * 2 + DotSpacing) * _currentPage,
                                        CGRectGetMaxY(bounds) - DotsLayoutMargins.bottom - DotRadius);
    CGRect layerBounds = CGRectMake(0 ,0,
                                    DotRadius * 2 + fabsf(percent) * (DotRadius * 2 + DotSpacing),
                                    DotRadius * 2);
    if(percent < 0)
        layerPosition.x -= (layerBounds.size.width - DotRadius * 2);
    
    CGMutablePathRef path = CGPathCreateMutable();
    CGPathAddArc(path, NULL, DotRadius, DotRadius, DotRadius, 0, M_PI * 2, NO);
    CGPathMoveToPoint(path, NULL, CGRectGetMaxX(layerBounds), DotRadius);
    CGPathAddArc(path, NULL, CGRectGetMaxX(layerBounds) - DotRadius, DotRadius, DotRadius, 0, M_PI * 2, NO);
    CGPathMoveToPoint(path, NULL, DotRadius, 0);
    CGPoint ep = CGPointMake(CGRectGetMaxX(layerBounds) - DotRadius, 0);
    CGPoint cp = CGPointMake(CGRectGetMidX(layerBounds), DotRadius * fabsf(percent) * fabsf(percent));
    CGPathAddQuadCurveToPoint(path, NULL, cp.x, cp.y, ep.x, ep.y);
    CGPathAddLineToPoint(path, NULL, ep.x, DotRadius * 2);
    CGPathAddQuadCurveToPoint(path, NULL, cp.x, DotRadius * 2 - cp.y, DotRadius, DotRadius * 2);
    CGPathAddLineToPoint(path, NULL, DotRadius, 0);
    
    _pageTransitionLayer.path = path;
    CGPathRelease(path);
    _pageTransitionLayer.position = layerPosition;
    _pageTransitionLayer.bounds = layerBounds;
    _pageTransitionLayer.hidden = fabsf(percent) == 0.0 || fabs(percent) == 1.0 ? YES : NO;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    CGRect bounds = self.bounds;
    NSInteger idx = 0;
    for(CAShapeLayer *layer in _dotLayers)
    {
        layer.position = CGPointMake(
                                     DotsLayoutMargins.left + (DotRadius * 2  + DotSpacing) * idx + DotRadius,
                                     CGRectGetMaxY(bounds) - DotsLayoutMargins.bottom - DotRadius);
        ++idx;
    }
}

@end


@implementation _ATPageTransitionLayer

- (id<CAAction>)actionForKey:(NSString *)event
{
    return [NSNull null];
}

@end
