//
//  DNVerticalTimeView.h
//  NDanale
//
//  Created by Tristan on 2017/6/26.
//  Copyright © 2017年 Danale. All rights reserved.
//

#import <UIKit/UIKit.h>

@class DNVerticalTimeView;

@protocol DNVerticalTimeViewDelegate <NSObject>

@optional

- (void)DNVerticalTimeView:(DNVerticalTimeView *)timeView didScrollToTime:(NSTimeInterval)time;

@end

@interface DNVerticalTimeView : UIView

@property (nonatomic, weak) id <DNVerticalTimeViewDelegate> delegate;

/**
 *
 *
 *  设置视图数据源
 *
 *  @param datas     数据源
 *  @param startTime 刻度起始时间 单位ms
 */
- (void)setDatas:(NSMutableArray *)datas startTime:(int64_t)startTime;

/**
 *  
 *
 *  根据传入的时间滚动至刻度
 *
 *  @param time 传入的时间 单位s
 */
- (void)scrollToScale:(int64_t)time;


@end
