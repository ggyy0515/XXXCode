//
//  DNVerticalTimeView.m
//  NDanale
//
//  Created by Tristan on 2017/6/26.
//  Copyright © 2017年 Danale. All rights reserved.
//

#define UNIT_SSCALE_LENGTH   15.f
#define MIN_TIME_GAP         (12.f * 60.f)
#define ONE_DAY_SECOND       (60.f * 60.f * 24.f)

#import "DNVerticalTimeView.h"
#import "DanaleHeader.h"
#import "DeviceCMDModel.h"
#import "UIImageView+WebCache.h"


typedef NS_ENUM(NSInteger, TimeLineType) {
    TimeLineTypeFill,
    TimeLineTypeEmpty
};


#pragma mark ========================Interface===============================


@interface VContentView : UIView

@property (nonatomic, weak) DNVerticalTimeView *grandView;
@property (nonatomic, assign) BOOL needClear;

@end


@interface HTimeLine : UIView

@property (nonatomic, assign) CGFloat leftBeginX;
@property (nonatomic, assign) CGFloat leftLength;
@property (nonatomic, assign) CGFloat midBeginX;
@property (nonatomic, assign) CGFloat midLength;
@property (nonatomic, assign) CGFloat rightBeginX;
@property (nonatomic, assign) CGFloat rightLength;
@property (nonatomic, assign) TimeLineType timeLineType;

- (instancetype)initWithLeftBeginX:(CGFloat)leftBeginX
                        leftLength:(CGFloat)leftLength
                         midBeginX:(CGFloat)midBeginX
                         midLength:(CGFloat)midLength
                       rightBeginX:(CGFloat)rightBeginX
                       rightLength:(CGFloat)rightLength;

@end


@interface DNVerticalTimeView ()
<
    UIScrollViewDelegate
>

@property (nonatomic, strong) UIScrollView *timeView;
@property (nonatomic, strong) VContentView *timeContentView;
@property (nonatomic, strong) HTimeLine *timeLine;
@property (nonatomic, strong) UILabel *timeLabel;
@property (nonatomic, strong) NSMutableArray <CloudRecordModel *> *cloudRecordModels;
@property (nonatomic, strong) NSMutableArray <ThumbnailModel *> *thumbnailModels;
@property (nonatomic, strong) NSMutableDictionary <NSString *, ThumbnailModel *> *thumbnailDic;
@property (nonatomic, assign) int64_t startTime;
@property (nonatomic, assign) BOOL canChangeTimeWhenScrolling;
@property (nonatomic, assign) NSTimeInterval currentTime;

@end


#pragma mark ========================IMP===============================


@implementation DNVerticalTimeView

#pragma mark - Life Cycle

- (instancetype)init {
    if (self = [super init]) {
        [self initUI];
    }
    return self;
}

- (void)initUI {
    self.backgroundColor = UIColorFromHexString(@"#F9F9F9");
    _canChangeTimeWhenScrolling = NO;
    
    if (!_timeView) {
        _timeView = [UIScrollView new];
    }
    _timeView.delegate = self;
    _timeView.contentInset = UIEdgeInsetsMake(20.f, 0.f, 20.f, 0.f);
    [self addSubview:_timeView];
    _timeView.backgroundColor = UIColorFromHexString(@"#F9F9F9");
    [_timeView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.mas_equalTo(self).insets(UIEdgeInsetsMake(0, 0, 0, 0));
    }];
    _timeView.showsVerticalScrollIndicator = NO;
    _timeView.showsHorizontalScrollIndicator = NO;
    
    if (!_timeContentView) {
        _timeContentView = [VContentView new];
    }
    _timeContentView.grandView = self;
    [_timeView addSubview:_timeContentView];
    _timeContentView.backgroundColor = UIColorFromHexString(@"#F9F9F9");
    [_timeContentView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.mas_equalTo(_timeView).insets(UIEdgeInsetsZero);
        make.width.mas_equalTo(_timeView);
    }];
    
    UIView *lastView = nil;
    for (NSInteger index = 0; index <= 240; index ++) {
        UILabel *mark = [UILabel new];
        [_timeContentView addSubview:mark];
        mark.backgroundColor = index % 10 == 0 ? UIColorFromHexString(@"#DFDFDF") : UIColorFromHexString(@"#E0E0E0");
        [mark mas_makeConstraints:^(MASConstraintMaker *make) {
            make.right.mas_equalTo(_timeContentView.mas_right);
            make.height.mas_equalTo(index % 10 == 0 ? 1.5 : 1.f);
            make.width.mas_equalTo(index % 10 == 0 ? 10.f : 7.f);
            if (lastView) {
                if (index == 240.f) {
                    make.top.mas_equalTo(lastView.mas_top).offset(UNIT_SSCALE_LENGTH - 1.5);
                } else {
                    make.top.mas_equalTo(lastView.mas_top).offset(UNIT_SSCALE_LENGTH);
                }
            } else {
                make.top.mas_equalTo(0.f);
            }
        }];
        if (index % 10 == 0) {
            UILabel *label = [UILabel new];
            [_timeContentView addSubview:label];
            label.textColor = UIColorFromHexString(@"#B3B3B3");
            label.text = [NSString stringWithFormat:@"%ld", 24 - index/10];
            label.font = BOLD_FONTSIZE(10.f);
            label.textAlignment = NSTextAlignmentCenter;
            [label mas_makeConstraints:^(MASConstraintMaker *make) {
                make.centerY.mas_equalTo(mark.mas_centerY);
                make.right.mas_equalTo(mark.mas_left).offset(-3.f);
                make.size.mas_equalTo(CGSizeMake(20, label.font.lineHeight));
            }];
        }
        lastView = mark;
    }
    [_timeContentView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.mas_equalTo(lastView.mas_bottom);
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
        make.right.mas_equalTo(self.mas_right).offset(-25.f);
    }];
//    _timeLabel.hidden = YES;
}

- (void)drawRect:(CGRect)rect {
    [super drawRect:rect];
    _timeView.contentInset = UIEdgeInsetsMake(20.f, 0.f, rect.size.height - 20.f, 0.f);
}

#pragma mark - Public

- (void)setDatas:(NSMutableArray *)datas startTime:(int64_t)startTime {
    _cloudRecordModels = datas;
    _startTime = startTime;
    _timeLabel.text = [self getTimeStringWithTimeStamp:startTime];
    [self layoutIfNeeded];
    CGRect rect = self.bounds;
    if (!_timeLine) {
        UIImage *image = [UIImage imageNamed:@"messages_move"];
        _timeLine = [[HTimeLine alloc] initWithLeftBeginX:15.f
                                               leftLength:image.size.width + 10.f
                                                midBeginX:rect.size.width / 2.f - (rect.size.height - 80.f) / 3.f  * 16.f / 9.f / 2.f - 5.f
                                                midLength:(rect.size.height - 80.f) / 3.f  * 16.f / 9.f + 10.f
                                              rightBeginX:SCREEN_WIDTH - 25.f - 60.f
                                              rightLength:60.f];
        [self addSubview:_timeLine];
        _timeLine.timeLineType = TimeLineTypeFill;
        _timeLine.backgroundColor = CLEAR_COLOR;
        [_timeLine mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.right.mas_equalTo(self);
            make.height.mas_equalTo(1.f);
            make.top.mas_equalTo(19.5f);
        }];
        [_timeLine layoutIfNeeded];
    }
    
    [_timeContentView setNeedsDisplay];
}



- (void)scrollToScale:(int64_t)time {
    _canChangeTimeWhenScrolling = NO;
    _currentTime = time;
    CGPoint point = [self getPointWithTimeStamp:time * 1000];
    NSString *timeString = [self getTimeStringWithTimeStamp:time * 1000];
    _timeLabel.text = timeString;
    [_timeView setContentOffset:CGPointMake(0, point.y - _timeView.contentInset.top) animated:YES];
}

- (void)setThumbnailModels:(NSMutableArray<ThumbnailModel *> *)thumbnailModels {
    _thumbnailModels = thumbnailModels;
    if (thumbnailModels.count <= 0) {
        return;
    }
    [_thumbnailModels sortUsingComparator:^NSComparisonResult(ThumbnailModel * _Nonnull obj1, ThumbnailModel * _Nonnull obj2) {
        if (obj1.timestamp > obj2.timestamp) {
            return NSOrderedDescending;
        } else {
            return NSOrderedAscending;
        }
    }];
    [self clearThumbnailsInScrollView];
    //创建时间轴旁边的缩略图
    CGFloat imageHeight = (_timeView.frame.size.height - 80.f) / 3.f;
    CGFloat imageWidth = imageHeight * 16.f / 9.f;
    CGPoint yPoint = [self getPointWithTimeStamp:[thumbnailModels objectAtIndex:0].timestamp];
    [self createThumbnailImageViewsWithBeginPoint:CGPointMake(_timeContentView.centerX - imageWidth / 2.f, yPoint.y)];
}


#pragma mark - Private

// 'timeStamp' is a time stamp with 13 bits
//从当天零点开始到输入时间经过的时间（秒）
- (double)getBeginSecondWithTimeStamp:(long)timeStamp {
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:(timeStamp / 1000)];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyyMMdd"];
    NSString *zeroTimeString = [dateFormatter stringFromDate:date];
    NSTimeInterval ZeroTimeInterval = [[dateFormatter dateFromString:zeroTimeString] timeIntervalSince1970];
    return timeStamp / 1000 - ZeroTimeInterval;

}

//'timeStamp' is a time stamp with 13 bits
- (CGPoint)getPointWithTimeStamp:(double)timeStamp {
    double beginSecond = [self getBeginSecondWithTimeStamp:timeStamp];
    double beginY = _timeContentView.height - _timeContentView.height * (beginSecond / ONE_DAY_SECOND);
    return CGPointMake(_timeLabel.centerX - 5.f, beginY);
}


- (CGFloat)getCurrentSelectedTime {
    CGPoint selectedPoint = [self convertPoint:CGPointMake(SCREEN_WIDTH, 20.f) toView:_timeContentView];
    if (selectedPoint.y < 0) {
        selectedPoint = CGPointMake(SCREEN_WIDTH, 0);
    }
    if (selectedPoint.y > _timeContentView.height) {
        selectedPoint = CGPointMake(SCREEN_WIDTH, _timeContentView.height);
    }
    CGFloat currentSecond = ONE_DAY_SECOND * (_timeContentView.height - selectedPoint.y) / _timeContentView.height;
    return currentSecond;
}

// 'timeStamp' is a time stamp with 13 bits
- (NSString *)getTimeStringWithTimeStamp:(double)timeStamp {
    NSDateFormatter *dateFt = [[NSDateFormatter alloc] init];
    [dateFt setDateFormat:@"HH:mm:ss"];
    return [dateFt stringFromDate:[NSDate dateWithTimeIntervalSince1970:timeStamp / 1000]];
}

//time length is milliscond
- (CGFloat)getLengthWithTimeLength:(CGFloat)timeLength {
    return _timeContentView.height * (timeLength / 1000.f) / (ONE_DAY_SECOND);
}

- (CGFloat)getRecordHeightWithLengthCloudRecordModel:(CloudRecordModel *)model {
    return model.time_len * (_timeContentView.height / ONE_DAY_SECOND /1000.f);
}


- (NSString *)getFormatTimeWithSecond:(NSInteger)second {
    return [NSString stringWithFormat:@"%02ld:%02ld:%02ld",second/3600,second%3600/60,second%60];
}

- (CGFloat)getSecondWithY:(CGFloat)y {
    return (_timeContentView.height - y) / _timeContentView.height * ONE_DAY_SECOND;
}

- (void)clearThumbnailsInScrollView {
    [_timeContentView.subviews enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj isKindOfClass:[UIImageView class]] && obj.centerX == _timeContentView.centerX) {
            [obj removeFromSuperview];
        }
    }];
}


/**
 绘制时间轴旁边的缩略图

 @param beginPoint 缩略图左下角的点
 */
- (void)createThumbnailImageViewsWithBeginPoint:(CGPoint)beginPoint {
    CGFloat imageHeight = (_timeView.frame.size.height - 80.f) / 3.f;
    CGFloat imageWidth = imageHeight * 16.f / 9.f;
    CGFloat gapHeight = [self getLengthWithTimeLength:MIN_TIME_GAP];
    if (beginPoint.y - imageHeight < 0) {
        //如果展示不下最后一张缩略图return
        return;
    }
    ThumbnailModel *firstModel = [_thumbnailModels objectAtIndex:0];
    CGPoint firstPoint = [self getPointWithTimeStamp:firstModel.timestamp];
    if (beginPoint.y == firstPoint.y) {
        //如果是最早的一个点,创建当天最早的一张图片
        UIImageView *firstImageView = [[UIImageView alloc] initWithFrame:CGRectMake(beginPoint.x, beginPoint.y - imageHeight, imageHeight, imageWidth)];
        firstImageView.backgroundColor = [UIColor blackColor];
        [firstImageView sd_setImageWithURL:[NSURL URLWithString:firstModel.addr]];
        [_timeContentView addSubview:firstImageView];
        [self createThumbnailImageViewsWithBeginPoint:CGPointMake(beginPoint.x, beginPoint.y - imageHeight - gapHeight)];
        return;
    }
    //接下来开始整第一张（最早）以后的缩略图
    //TODO
    
    //先看一下从beginPoint到图片的左上角的点，这段空间对应的时间有木有视屏
}

//获取竖直方向上两个坐标点之间的缩略图数据模型
- (NSMutableArray *)getThumbModelsBetweenLowerY:(CGFloat)lowY andHegherY:(CGFloat)higherY {
    CGFloat beginSecond = [self getSecondWithY:lowY];
    CGFloat endSecond = [self getSecondWithY:higherY];
    
    NSMutableArray *array = [NSMutableArray array];
    [_thumbnailModels enumerateObjectsUsingBlock:^(ThumbnailModel * _Nonnull model, NSUInteger idx, BOOL * _Nonnull stop) {
        //TODO
    }];
    return nil;
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (_canChangeTimeWhenScrolling) {
        _timeLabel.text = [self getFormatTimeWithSecond:[self getCurrentSelectedTime]];
    }
    if (IS_NORMAL_RESPONDDELEGATE_FUNC(_delegate, @selector(DNVerticalTimeView:didScrollToTime:))) {
        [_delegate DNVerticalTimeView:self didScrollToTime:_currentTime];
    }
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    _canChangeTimeWhenScrolling = YES;
}




@end





@implementation HTimeLine

#pragma mark - Life Cycle

- (instancetype)initWithLeftBeginX:(CGFloat)leftBeginX leftLength:(CGFloat)leftLength midBeginX:(CGFloat)midBeginX midLength:(CGFloat)midLength rightBeginX:(CGFloat)rightBeginX rightLength:(CGFloat)rightLength {
    if (self = [super init]) {
        _leftBeginX = leftBeginX;
        _leftLength = leftLength;
        _midBeginX = midBeginX;
        _midLength = midLength;
        _rightBeginX = rightBeginX;
        _rightLength = rightLength;
    }
    return self;
}

- (void)drawRect:(CGRect)rect {
    [super drawRect:rect];
    CGContextClearRect(UIGraphicsGetCurrentContext(), rect);
    if (_timeLineType == TimeLineTypeFill) {
        [self beFill];
    } else {
        [self beEmpty];
    }
}

#pragma mark - Setter

- (void)setTimeLineType:(TimeLineType)timeLineType {
    _timeLineType = timeLineType;
    [self setNeedsDisplay];
}

#pragma mark - Private

- (void)beFill {
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetLineCap(context, kCGLineCapSquare);
    CGContextSetLineWidth(context, 1.f);
    CGContextSetRGBStrokeColor(context, 88.f / 255.f, 152.f / 255.f, 176.f / 255.f, 1.f);
    CGContextBeginPath(context);
    CGContextMoveToPoint(context, 0, 0);
    CGContextAddLineToPoint(context, _rightBeginX, 0.f);
    CGContextMoveToPoint(context, _rightBeginX + _rightLength, 0.f);
    CGContextAddLineToPoint(context, SCREEN_WIDTH, 0.f);
    CGContextStrokePath(context);
}

- (void)beEmpty {
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetLineCap(context, kCGLineCapSquare);
    CGContextSetLineWidth(context, 1.f);
    CGContextSetRGBStrokeColor(context, 88.f / 255.f, 152.f / 255.f, 176.f / 255.f, 1.f);
    CGContextBeginPath(context);
    CGContextMoveToPoint(context, 0, 0);
    CGContextAddLineToPoint(context, _leftBeginX, 0.f);
    CGContextMoveToPoint(context, _leftBeginX + _leftLength, 0);
    CGContextAddLineToPoint(context, _midBeginX, 0.f);
    CGContextMoveToPoint(context, _midBeginX + _midLength, 0.f);
    CGContextAddLineToPoint(context, _rightBeginX, 0.f);
    CGContextMoveToPoint(context, _rightBeginX + _rightLength, 0.f);
    CGContextAddLineToPoint(context, SCREEN_WIDTH, 0.f);
    CGContextStrokePath(context);
}

@end


@implementation VContentView

- (void)drawRect:(CGRect)rect {
    [super drawRect:rect];
    [self drawCloudRecord];
}

- (void)drawCloudRecord {
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextMoveToPoint(context, _grandView.timeLabel.centerX - 5.f, 0.f);
    CGContextSetLineCap(context, kCGLineCapSquare);
    CGContextSetLineWidth(context, 9.f);
    CGContextSetRGBStrokeColor(context, 1.f, 1.f, 1.f, 1.f);
    CGContextAddLineToPoint(context, _grandView.timeLabel.centerX - 5.f, self.height);
    CGContextStrokePath(context);
    CGContextSetLineWidth(context, 5.f);
    [_grandView.cloudRecordModels enumerateObjectsUsingBlock:^(CloudRecordModel * _Nonnull model, NSUInteger idx, BOOL * _Nonnull stop) {
        CGPoint beginPoint = [_grandView getPointWithTimeStamp:model.start_time];
        CGContextSetRGBStrokeColor(context, 88.f / 255.f, 152.f / 255.f, 176.f / 255.f, 1.f);
        CGContextMoveToPoint(context, beginPoint.x, beginPoint.y);
        CGContextAddLineToPoint(context, beginPoint.x, beginPoint.y - [_grandView getLengthWithTimeLength:model.time_len]);
        CGContextStrokePath(context);
    }];
}


@end




