
//  Created by lantu on 2018/5/11.
//  Copyright © 2018年 lantuhy. All rights reserved.


#import <UIKit/UIKit.h>
#import "ATPageControl.h"

NS_ASSUME_NONNULL_BEGIN

@class ATLoopView;

@protocol ATLoopViewDelegate < NSObject >

@required
- (NSInteger)numberOfPagesInLoopView:(ATLoopView *)loopView;
- (__kindof UIView *)contentViewForLoopView:(ATLoopView *)loopView;
- (void)loopView:(ATLoopView *)loopView shouldUpdateContentView:(__kindof UIView *)contentView forPageAtIndex:(NSInteger)index;

@optional
- (void)loopView:(ATLoopView *)loopView didSelectPageAtIndex:(NSInteger)index;
- (void)loopView:(ATLoopView *)loopView didScrollToPageAtIndex:(NSInteger)index;

@end

@interface ATLoopViewBlocksDelegate : NSObject< ATLoopViewDelegate >

@property (nonatomic, strong) NSInteger ( ^ numberOfPages)(void);
@property (nonatomic, strong) UIView * (^ contentViewForLoopView)(void);
@property (nonatomic, strong) void ( ^ shouldUpdateContentViewForPageAtIndex)(__kindof UIView *contentView, NSInteger idx);
@property (nonatomic, strong, nullable) void ( ^ didScrollToPageAtIndex)(NSInteger idx);
@property (nonatomic, strong, nullable) void ( ^ didSelectPageAtIndex)(NSInteger idx);

@end

typedef NS_ENUM(NSInteger, ATLoopViewScrollDirection)
{
    ATLoopViewScrollDirectionHorizontal,
    ATLoopViewScrollDirectionVertical,
};


@interface ATLoopView : UIView

@property (nonatomic) ATLoopViewScrollDirection scrollDirection;
@property (nonatomic, weak, nullable) id<ATLoopViewDelegate> delegate;

@property (nonatomic, strong, nullable) UIView<ATPageControl> *pageControl;

@property (nonatomic) NSTimeInterval autoScrollAnimationDuration;  // default is 0.25
@property (nonatomic) NSTimeInterval autoScrollTimeInterval;       // default is 5.0

/* 自动滚动动画的时间函数
 * default is [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn]
 */
@property (nonatomic, strong) CAMediaTimingFunction *autoScrollTimingFunction;

- (instancetype)initWithFrame:(CGRect)frame NS_DESIGNATED_INITIALIZER;
- (instancetype)initWithCoder:(NSCoder *)aDecoder NS_DESIGNATED_INITIALIZER;

/* 把ATLoopViewBlocksDelegate对象设置为它的delegate,并持有它。
 */
- (void)setBlocksDelegate:(nullable ATLoopViewBlocksDelegate *)delegate;
- (void)reloadData;
- (void)enableAutoScroll:(BOOL)enable;

@end


@interface ATLoopViewImageDelegate : ATLoopViewBlocksDelegate

@property (nonatomic, copy) NSArray<UIImage *> *images;
@property (nonatomic) UIViewContentMode contentMode;   // content mode for UIImageView.

- (instancetype)initWithImages:(NSArray<UIImage *> *)images contentMode:(UIViewContentMode)contentMode;

@end

NS_ASSUME_NONNULL_END

