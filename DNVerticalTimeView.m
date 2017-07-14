//
//  DNVerticalTimeView.m
//  NDanale
//
//  Created by Tristan on 2017/7/12.
//  Copyright © 2017年 Danale. All rights reserved.
//

#define UNIT_SSCALE_LENGTH          (15.f)//每格刻度的长度
#define UNIT_SSCALE_TIME            (6.f * 60.f) //每格刻度的时间
#define MIN_TIME_GAP                (18.f * 60.f) //最小时间间隔
#define ONE_DAY_SECOND              (60.f * 60.f * 24.f)//每天的秒数
#define LENGTH_PER_SECOND           (UNIT_SSCALE_LENGTH / UNIT_SSCALE_TIME)//每秒的长度
#define TIME_PER_PX                 (UNIT_SSCALE_TIME / UNIT_SSCALE_LENGTH)//每个像素的时间
#define ONE_DAY_LENGTH              (ONE_DAY_SECOND * LENGTH_PER_SECOND)//一天的长度
#define MIN_GAP_LENGTH              (LENGTH_PER_SECOND * MIN_TIME_GAP)//最小间隔的长度
#define SCALE_LINE_WIDTH            1.f
#define OCLOCK_SCALE_LINE_WIDTH     1.5f
#define THUMBNAIL_H                 (UNIT_SSCALE_LENGTH * 10 - MIN_GAP_LENGTH)
#define THUMBNAIL_W                 (SCREEN_WIDTH <= 375 ? THUMBNAIL_H * 4.f / 3.f : THUMBNAIL_H * 16.f / 9.f)

#import "DNVerticalTimeView.h"
#import "DanaleHeader.h"
#import "DeviceCMDModel.h"
#import "UIImageView+WebCache.h"

typedef NS_ENUM(NSInteger, TimeLineSyle) {
    TimeLineSyle_empty,
    TimeLineSyle_full
};

@interface VContentView : UIView

@property (nonatomic, weak) DNVerticalTimeView *grandView;
@property (nonatomic, assign) NSUInteger day; //一共绘制到了几天前 0为当前天，1为前一天，2为前两天...

@end

@interface HTimeLine : UIView

@property (nonatomic, assign) TimeLineSyle timeLineStyle;
@property (nonatomic, weak) DNVerticalTimeView *grandView;

@end

@interface DNVerticalRecorder : UIView

@property (nonatomic, weak) DNVerticalTimeView *grandView;
@property (nonatomic, strong) NSMutableArray <CloudRecordModel *> *appendCloudRecordModels;

@end

@interface DNVerticalTimeView ()
<
    UIScrollViewDelegate
>

@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UILabel *timeLabel;
@property (nonatomic, strong) VContentView *contentView;
@property (nonatomic, strong) HTimeLine *timeLine;
@property (nonatomic, strong) DNVerticalRecorder *recoder;

@property (nonatomic, strong) NSMutableArray <CloudRecordModel *> *cloudRecordModels;
@property (nonatomic, strong) NSMutableArray <ThumbnailModel *> *thumbnailModels;
@property (nonatomic, strong) NSMutableDictionary <NSString *, ThumbnailModel *> *thumbnailDic;
@property (nonatomic, assign) NSTimeInterval currentTime;
@property (nonatomic, assign) BOOL canDrawScale;

@end

@implementation DNVerticalTimeView

#pragma mark - Life Cycle

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        _cloudRecordModels = [NSMutableArray array];
        [self initUI];
    }
    return self;
}

- (void)initUI {
    self.backgroundColor = UIColorFromHexString(@"#F9F9F9");
    _canDrawScale = YES;
    
    if (!_scrollView) {
        _scrollView = [UIScrollView new];
    }
    _scrollView.delegate = self;
    _scrollView.contentInset = UIEdgeInsetsMake(20.f, 0.f, 0.f, 0.f);
    [self addSubview:_scrollView];
    _scrollView.backgroundColor = UIColorFromHexString(@"#F9F9F9");
    [_scrollView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.mas_equalTo(self).insets(UIEdgeInsetsMake(0, 0, 0, 0));
    }];
    _scrollView.showsVerticalScrollIndicator = NO;
    _scrollView.showsHorizontalScrollIndicator = NO;
    
    if (!_contentView) {
        _contentView = [VContentView new];
    }
    _contentView.grandView = self;
    _contentView.day = 0;
    [_scrollView addSubview:_contentView];
    _contentView.backgroundColor = UIColorFromHexString(@"#F9F9F9");
    [_contentView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.mas_equalTo(_scrollView).insets(UIEdgeInsetsZero);
        make.width.mas_equalTo(_scrollView);
        make.height.mas_equalTo(ONE_DAY_LENGTH);
    }];
    
    if (!_timeLabel) {
        _timeLabel = [UILabel new];
    }
    [self addSubview:_timeLabel];
    _timeLabel.font = BOLD_FONTSIZE(11.f);
    _timeLabel.textAlignment = NSTextAlignmentCenter;
    _timeLabel.textColor = UIColorFromHexString(@"#222222");
    [_timeLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.mas_equalTo(self.mas_top).offset(20.f);
        make.size.mas_equalTo(CGSizeMake(60.f, _timeLabel.font.lineHeight));
        make.right.mas_equalTo(self.mas_right).offset(-45.f);
    }];
    
    if (!_timeLine) {
        _timeLine = [HTimeLine new];
    }
    [self addSubview:_timeLine];
    _timeLine.backgroundColor = CLEAR_COLOR;
    [_timeLine mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.mas_equalTo(self);
        make.top.mas_equalTo(self.mas_top).offset(20.f);
        make.height.mas_equalTo(1.f);
    }];
    _timeLine.grandView = self;
    _timeLine.timeLineStyle = TimeLineSyle_full;
    
    if (!_recoder) {
        _recoder = [DNVerticalRecorder new];
    }
    [_contentView addSubview:_recoder];
    _recoder.backgroundColor = UIColorFromHexString(@"#F1F1F1");
    [_recoder mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.bottom.mas_equalTo(_contentView);
        make.right.mas_equalTo(_contentView.mas_right).offset(-25.f);
        make.width.mas_equalTo(10.f);
    }];
    _recoder.grandView = self;
}


#pragma mark - Public

- (void)setDatas:(NSMutableArray *)datas startTime:(int64_t)startTime {
    [_cloudRecordModels addObjectsFromArray:datas];
    _recoder.appendCloudRecordModels = datas;

}

#pragma mark - Private

/**
 获取每天的0点的时间戳(10位)

 @param time 一个13位的毫秒级时间戳
 @return 每天的0点的时间戳(10位)
 */
- (NSTimeInterval)getDayBeginTimeWithTimeTimeStamp:(long)time {
    NSDateFormatter *dateFt = [[NSDateFormatter alloc] init];
    [dateFt setDateFormat:@"yyyyMMdd"];
    NSString *zeroDateString = [dateFt stringFromDate:[NSDate dateWithTimeIntervalSince1970:((double)time) / 1000.f]];
    return [[dateFt dateFromString:zeroDateString] timeIntervalSince1970];
}


/**
 获取某时刻距离该天0点的秒数(10位)

 @param time 一个13位的毫秒级时间戳
 @return 某时刻距离改天0点的秒数(10位)
 */
- (double)getSecondCountInDayWithTimeStamp:(long)time {
    NSTimeInterval zeroTime = [self getDayBeginTimeWithTimeTimeStamp:time];
    return ((double)time) / 1000.f - zeroTime;
}


/**
 根据某一点在contentView的y值获取当前该点对应的时间戳(10位)

 @param y 点在contentView的y值
 @return 该点对应的时间戳(10位)
 */
- (NSTimeInterval)getTimeStampWithPointY:(CGFloat)y {
    double earlisetTimeStamp = [self getDayBeginTimeWithTimeTimeStamp:[[NSDate date] timeIntervalSince1970] * 1000] + ONE_DAY_SECOND - (_contentView.height / ONE_DAY_LENGTH) * ONE_DAY_SECOND;
    NSTimeInterval time = earlisetTimeStamp + (_contentView.height - y) * TIME_PER_PX;
    return time;
}


/**
 根据时间戳获取一个在contentVIew对应的y值

 @param time 13位的时间戳
 @return 在contentVIew对应的y值
 */
- (CGFloat)getPointYWithTimeStamp:(long)time {
    NSTimeInterval topTime = [self getDayBeginTimeWithTimeTimeStamp:[[NSDate date] timeIntervalSince1970] * 1000] + ONE_DAY_SECOND;
    CGFloat y = (topTime - ((double)time) / 1000.f) * LENGTH_PER_SECOND;
    return y;
}


/**
 根据秒数获取时间字符串

 @param second 从这一天的0点到指定时刻的秒数
 @return
 */
- (NSString *)getFormatTimeWithSecond:(NSInteger)second {
    return [NSString stringWithFormat:@"%02ld:%02ld:%02ld",second/3600,second%3600/60,second%60];
}


/**
 获取时间线上的时间戳(10位)

 @return 时间戳(10位)
 */
- (NSTimeInterval)getTimeLineTimeStamp {
    CGFloat y = [_contentView convertPoint:CGPointMake(0, 20.f) fromView:self].y;
    NSTimeInterval time = [self getTimeStampWithPointY:y];
    return time;
}


/**
 获取时间线上展示的时间

 @return
 */
- (NSString *)getTimeLineShowTime {
    NSTimeInterval time = [self getTimeLineTimeStamp];
    return [self getFormatTimeWithSecond:[self getSecondCountInDayWithTimeStamp:time * 1000]];
}


/**
 继续画新的刻度
 */
- (void)drawMoreTimeScaleIfNeed {
    //如果 1.位置处在比当天7点还早的时候，2.并且当天是已经绘制出的最后一天 绘制前一天的时间轴
    //条件1
    NSTimeInterval timeLineStamp = [self getTimeLineTimeStamp];//时间线上的时间戳
    double second = [self getSecondCountInDayWithTimeStamp:timeLineStamp * 1000];//时间线距离当天0点的秒数
    //条件2
    double contentViewTopTime = [self getDayBeginTimeWithTimeTimeStamp:[[NSDate date] timeIntervalSince1970] * 1000.f] + ONE_DAY_SECOND;//contentView最高点的时间戳
    double largeSecond = contentViewTopTime - timeLineStamp;//时间线到contentView最高点之间的秒数
    NSInteger timeLineDay = largeSecond / ONE_DAY_SECOND;//时间线在第几天
    NSInteger day = _contentView.height / ONE_DAY_LENGTH - 1;//当前加载到第几天，0是今天，1是前一天...
    if (second < (7.f * 3600) && day == timeLineDay) {
        [_contentView mas_updateConstraints:^(MASConstraintMaker *make) {
            make.height.mas_equalTo(_contentView.height + ONE_DAY_LENGTH);
        }];
        [self layoutIfNeeded];
        _contentView.day = day + 1;
        _canDrawScale = NO;
    }
    
}


#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    //展示时间线上的时间
    _timeLabel.text = [self getTimeLineShowTime];
    //继续画心的刻度
    [self drawMoreTimeScaleIfNeed];
    
}




@end



@implementation VContentView

- (void)drawRect:(CGRect)rect {
    [super drawRect:rect];
    [self drawScaleInDay:_day];
}

- (void)setDay:(NSUInteger)day {
    _day = day;
    [self setNeedsDisplay];
}

/**
 绘制刻度
 
 @param day 0为当前天，1为前一天，2为前两天...
 */
- (void)drawScaleInDay:(NSUInteger)day {
    CGFloat dayBeginY = day * ONE_DAY_LENGTH;
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetLineCap(context, kCGLineCapSquare);
    for (NSInteger index = 0; index < 240; index ++) {
        CGPoint beginPoint = CGPointZero;
        if (index % 10 == 0) {
            //整点时刻
            //画线
            if (day == 0 && index == 0) {
                beginPoint = CGPointMake(SCREEN_WIDTH - 10.f, dayBeginY + index * UNIT_SSCALE_LENGTH + OCLOCK_SCALE_LINE_WIDTH / 2.f);
            } else {
                beginPoint = CGPointMake(SCREEN_WIDTH - 10.f, dayBeginY + index * UNIT_SSCALE_LENGTH);
            }
            CGContextMoveToPoint(context, beginPoint.x, beginPoint.y);
            CGContextSetRGBStrokeColor(context, 223.f / 255.f, 223.f / 255.f, 223.f / 255.f, 1);
            CGContextSetLineWidth(context, OCLOCK_SCALE_LINE_WIDTH);
            CGContextAddLineToPoint(context, SCREEN_WIDTH, beginPoint.y);
            CGContextStrokePath(context);
            //画数字
            NSString *str = [NSString stringWithFormat:@"%ld", 24 - index/10];
            CGFloat strY = beginPoint.y - 5.f;
            if (day == 0 && index == 0) {
                strY = beginPoint.y - 4;
            }
            [str drawInRect:CGRectMake(SCREEN_WIDTH - 5.f - 20.f, strY, 20.f, 10.f)
             withAttributes:@{NSFontAttributeName:BOLD_FONTSIZE(10.f),
                              NSForegroundColorAttributeName:UIColorFromHexString(@"#B3B3B3")}];
        } else {
            //非整点
            beginPoint = CGPointMake(SCREEN_WIDTH - 7.f, dayBeginY + index * UNIT_SSCALE_LENGTH);
            CGContextMoveToPoint(context, beginPoint.x, beginPoint.y);
            CGContextSetRGBStrokeColor(context, 224.f / 255.f, 224.f / 255.f, 224.f / 255.f, 1);
            CGContextSetLineWidth(context, SCALE_LINE_WIDTH);
            CGContextAddLineToPoint(context, SCREEN_WIDTH, beginPoint.y);
            CGContextStrokePath(context);
        }
    }
    _grandView.canDrawScale = YES;
}


@end


@implementation HTimeLine

- (void)drawRect:(CGRect)rect {
    [super drawRect:rect];
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextClearRect(context, rect);
    CGContextSetLineCap(context, kCGLineCapSquare);
    CGContextSetLineWidth(context, 1.f);
    CGContextSetRGBStrokeColor(context, 88.f / 255.f, 152.f / 255.f, 176.f / 255.f, 1.f);
    CGContextBeginPath(context);
    CGContextMoveToPoint(context, 0, 0);
    if (_timeLineStyle == TimeLineSyle_full) {
        CGContextAddLineToPoint(context, self.grandView.timeLabel.left, 0);
        CGContextMoveToPoint(context, self.grandView.timeLabel.right, 0);
        CGContextAddLineToPoint(context, SCREEN_WIDTH, 0);
        
    } else {
        UIImage *image = [UIImage imageNamed:@"messages_move"];
        CGContextAddLineToPoint(context, 17.f, 0);
        CGContextMoveToPoint(context, 20.f + image.size.width + 3.f, 0);
        CGContextAddLineToPoint(context, self.centerX - THUMBNAIL_W / 2.f - 3.f, 0);
        CGContextMoveToPoint(context, self.centerX + THUMBNAIL_W / 2.f + 3.f, 0);
        CGContextAddLineToPoint(context, self.grandView.timeLabel.left, 0);
        CGContextMoveToPoint(context, self.grandView.timeLabel.right, 0);
        CGContextAddLineToPoint(context, SCREEN_WIDTH, 0);
    }
    CGContextStrokePath(context);
}

- (void)setTimeLineStyle:(TimeLineSyle)timeLineStyle {
    _timeLineStyle = timeLineStyle;
    [self setNeedsDisplay];
}

@end

@implementation DNVerticalRecorder

- (void)drawRect:(CGRect)rect {
    [super drawRect:rect];
    [self drawCloudRecord];
    
}

- (void)setAppendCloudRecordModels:(NSMutableArray<CloudRecordModel *> *)appendCloudRecordModels {
    _appendCloudRecordModels = appendCloudRecordModels;
    [self setNeedsDisplay];
}

- (void)drawCloudRecord {
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetLineCap(context, kCGLineCapSquare);
    CGContextSetLineWidth(context, 5.f);
    CGContextBeginPath(context);
    [_appendCloudRecordModels enumerateObjectsUsingBlock:^(CloudRecordModel * _Nonnull model, NSUInteger idx, BOOL * _Nonnull stop) {
        CGFloat beginY = [_grandView getPointYWithTimeStamp:model.start_time];
        CGFloat endY = beginY - ((double)model.time_len) / 1000.f * LENGTH_PER_SECOND;
        CGContextSetRGBStrokeColor(context, 88.f / 255.f, 152.f / 255.f, 176.f / 255.f, 1.f);//后面在这里根据model的告警类型更改颜色 TODO
        CGContextMoveToPoint(context, 5.f, beginY);
        CGContextAddLineToPoint(context, 5.f, endY);
    }];
    CGContextStrokePath(context);

}



@end
