
//  Created by lantu on 2018/5/11.
//  Copyright © 2018年 lantu. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN


@protocol ATPageControl

@required
@property(nonatomic) NSInteger numberOfPages;
@property(nonatomic) NSInteger currentPage;

@optional
/* 更新翻页完成的百分比，percent取值范围为:[-1.0, 1.0].
 * -1.0 <= percent < 0.0, 向前翻页; 0.0 < percent <= 1.0, 向后翻页.
 */
- (void)updatePageTransitionPercent:(float)percent;

@end


@interface ATPageControl : UIView <ATPageControl>

@property(nonatomic) NSInteger numberOfPages;
@property(nonatomic) NSInteger currentPage;

@property(nullable, nonatomic,strong) UIColor *pageIndicatorColor;
@property(nullable, nonatomic,strong) UIColor *currentPageIndicatorColor;

- (instancetype)initWithFrame:(CGRect)frame NS_DESIGNATED_INITIALIZER;
- (instancetype)initWithCoder:(NSCoder *)aDecoder NS_DESIGNATED_INITIALIZER;

- (void)updatePageTransitionPercent:(float)percent;

- (CGSize)sizeThatFits:(CGSize)size;

@end


NS_ASSUME_NONNULL_END
