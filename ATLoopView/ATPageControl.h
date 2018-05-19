
//  Created by lantu on 2018/5/11.
//  Copyright © 2018年 lantu. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface ATPageControl : UIView

@property(nonatomic) NSInteger numberOfPages;
@property(nonatomic) NSInteger currentPage;

@property(nullable, nonatomic,strong) UIColor *pageIndicatorColor;
@property(nullable, nonatomic,strong) UIColor *currentPageIndicatorColor;

- (instancetype)initWithFrame:(CGRect)frame NS_DESIGNATED_INITIALIZER;
- (instancetype)initWithCoder:(NSCoder *)aDecoder NS_UNAVAILABLE;

/* 更新翻页进度，progress取值范围为:[-1.0, 1.0].
 * 1.0 <= progress < 0.0, 表示向前翻页; 0.0 < progress <= 1.0 表示向后翻页.
 */
- (void)updateTransitionProgress:(float)progress;

- (CGSize)sizeThatFits:(CGSize)size;

@end


NS_ASSUME_NONNULL_END
