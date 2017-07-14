//
//  DNVerticalTimeView.h
//  NDanale
//
//  Created by Tristan on 2017/7/12.
//  Copyright © 2017年 Danale. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DNVerticalTimeView : UIView

/**
 *
 *
 *  设置视图数据源
 *
 *  @param datas     数据源
 *  @param startTime 刻度起始时间 单位ms
 */
- (void)setDatas:(NSMutableArray *)datas startTime:(int64_t)startTime;

@end
