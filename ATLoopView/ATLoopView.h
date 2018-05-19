
//  Created by lantu on 2018/5/11.
//  Copyright © 2018年 lantuhy. All rights reserved.


#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class ATLoopView;

@protocol ATLoopViewDelegate < NSObject >

@required
- (NSInteger)numberOfPagesInLoopView:(ATLoopView *)loopView;
- (void)loopView:(ATLoopView *)loopView shouldUpdateContentView:(__kindof UIView *)contentView forPageAtIndex:(NSInteger)index;

@optional
- (void)loopView:(ATLoopView *)loopView didSelectPageAtIndex:(NSInteger)index;
- (void)loopView:(ATLoopView *)loopView didScrollToPageAtIndex:(NSInteger)index;

@end

typedef NS_ENUM(NSInteger, ATLoopViewScrollDirection)
{
    ATLoopViewScrollDirectionHorizontal,
    ATLoopViewScrollDirectionVertical,
};

@interface ATLoopView : UIView

@property (nonatomic) ATLoopViewScrollDirection scrollDirection;
@property (nonatomic, weak, nullable) id<ATLoopViewDelegate> delegate;

@property(nullable, nonatomic,strong) UIColor *pageIndicatorColor;
@property(nullable, nonatomic,strong) UIColor *currentPageIndicatorColor;
@property(nonatomic) BOOL pageIndicatorHidden;

@property (nonatomic) NSTimeInterval autoScrollAnimationDuration;  // default is 0.25
@property (nonatomic) NSTimeInterval autoScrollTimeInterval;       // default is 5.0

/* 自动滚动动画的时间函数
 * default is [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn]
 */
@property (nonatomic, strong) CAMediaTimingFunction *autoScrollTimingFunction;

/* 和ATLoopViewDelegate对应的blocks
 */
@property (nonatomic, strong) NSInteger ( ^ numberOfPages)(void);
@property (nonatomic, strong) void ( ^ shouldUpdateContentViewForPageAtIndex)(__kindof UIView *contentView, NSInteger idx);
@property (nonatomic, strong, nullable) void ( ^ didScrollToPageAtIndex)(NSInteger idx);
@property (nonatomic, strong, nullable) void ( ^ didSelectPageAtIndex)(NSInteger idx);

- (instancetype)initWithFrame:(CGRect)frame NS_DESIGNATED_INITIALIZER;
- (instancetype)initWithCoder:(NSCoder *)aDecoder NS_UNAVAILABLE;

- (void)registerClassForContentView:(Class)cls;
- (void)registerNibForContentView:(UINib *)nib;
- (void)reloadData;
- (void)enableAutoScroll:(BOOL)enable;

@end

NS_ASSUME_NONNULL_END
