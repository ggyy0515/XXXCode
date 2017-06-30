//
//  DNVerticalTimeView.m
//  NDanale
//
//  Created by Tristan on 2017/6/26.
//  Copyright © 2017年 Danale. All rights reserved.
//

#define ONE_DAY_SECOND   (60.f * 60 * 24)

#import "DNVerticalTimeView.h"
#import "DanaleHeader.h"
#import "DNBaseCollectionViewCell.h"
#import "DNBaseTableViewCell.h"
#import "DNTimeViewModel.h"


typedef NS_ENUM(NSInteger, TimeLineType) {
    TimeLineTypeFill,
    TimeLineTypeEmpty
};


#pragma mark ========================Interface===============================

@interface DNVerticalTimeViewCollectionViewCell: DNBaseCollectionViewCell

@property (nonatomic, strong) UIImageView *tipImageView;
@property (nonatomic, strong) UIImageView *thumbnailImageView;
@property (nonatomic, assign) BOOL isTipImageInTimeLinePosition;

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
    UICollectionViewDelegate,
    UICollectionViewDataSource,
    UICollectionViewDelegateFlowLayout
>

@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) UIScrollView *timeView;
@property (nonatomic, strong) UIView *timeContentView;
@property (nonatomic, strong) HTimeLine *timeLine;
@property (nonatomic, strong) UILabel *timeLabel;
@property (nonatomic, strong) UIImageView *tipImage;
@property (nonatomic, strong) UIDynamicAnimator *animator;

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
    
    if (!_animator) {
        _animator = [[UIDynamicAnimator alloc] initWithReferenceView:self];
    }
    
    if (!_collectionView) {
        UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
        layout.minimumLineSpacing = 20.f;
        _collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
    }
    [self addSubview:_collectionView];
    [_collectionView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.bottom.top.mas_equalTo(self);
        make.right.mas_equalTo(self.mas_right).offset(-60.f);
    }];
    _collectionView.backgroundColor = UIColorFromHexString(@"#F9F9F9");
    _collectionView.delegate = self;
    _collectionView.dataSource = self;
    _collectionView.showsHorizontalScrollIndicator = NO;
    _collectionView.showsVerticalScrollIndicator = NO;
    [_collectionView registerClass:[DNVerticalTimeViewCollectionViewCell class]
        forCellWithReuseIdentifier:CELL_IDENTIFY_WITH_OBJECT(DNVerticalTimeViewCollectionViewCell)];
    
    if (!_timeView) {
        _timeView = [UIScrollView new];
    }
    _timeView.delegate = self;
    _timeView.contentInset = UIEdgeInsetsMake(20.f, 0.f, 20.f, 0.f);
    [self addSubview:_timeView];
    _timeView.backgroundColor = UIColorFromHexString(@"#F9F9F9");
    [_timeView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(self.collectionView.mas_right);
        make.top.mas_equalTo(self.collectionView.mas_top);
        make.bottom.right.mas_equalTo(self);
    }];
    _timeView.showsVerticalScrollIndicator = NO;
    _timeView.showsHorizontalScrollIndicator = NO;
    
    if (!_timeContentView) {
        _timeContentView = [UIView new];
    }
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
                make.top.mas_equalTo(lastView.mas_bottom).offset(15.f);
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
    _timeLabel.text = @"23:00:12";
    _timeLabel.hidden = YES;
    
    if (!_tipImage) {
        _tipImage = [UIImageView new];
    }
    [self addSubview:_tipImage];
    UIImage *image = [UIImage imageNamed:@"messages_move"];
    [_tipImage setImage:image];
    [_tipImage mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(self.mas_left).offset(20.f);
        make.centerY.mas_equalTo(self.mas_top).offset(20.f);
        make.size.mas_equalTo(CGSizeMake(image.size.width, image.size.height));
    }];
    _tipImage.hidden = YES;
}

- (void)drawRect:(CGRect)rect {
    [super drawRect:rect];
    
    _timeView.contentInset = UIEdgeInsetsMake(20.f, 0.f, rect.size.height - 20.f, 0.f);
    
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
    
}

#pragma mark - Private

- (CGFloat)getCurrentSelectedTime {
    CGPoint selectedPoint = [self convertPoint:CGPointMake(SCREEN_WIDTH, 20.f) toView:_timeContentView];
    if (selectedPoint.y < 0) {
        selectedPoint = CGPointMake(SCREEN_WIDTH, 0);
    }
    if (selectedPoint.y > _timeContentView.height) {
        selectedPoint = CGPointMake(SCREEN_WIDTH, _timeContentView.height);
    }
    CGFloat currentSecond = (_timeContentView.height - selectedPoint.y) / _timeContentView.height * 24 * 60 * 60;
    return currentSecond;
}

- (NSString *)getFormatTimeWithSecond:(NSInteger)second {
    return [NSString stringWithFormat:@"%02ld:%02ld:%02ld",second/3600,second%3600/60,second%60];
}

#pragma mark - UICollectionView Method

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return 10;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    DNVerticalTimeViewCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:CELL_IDENTIFY_WITH_OBJECT(DNVerticalTimeViewCollectionViewCell)
                                                                                           forIndexPath:indexPath];
    return cell;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return CGSizeMake(SCREEN_WIDTH - 60.f, (self.height - 80.f) / 3.f);
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
    return UIEdgeInsetsMake(20.f, 0.f, self.height - 25.f, 0.f);
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    _timeLabel.text = [self getFormatTimeWithSecond:[self getCurrentSelectedTime]];
    if (scrollView == _collectionView) {
        NSArray *arr = [_collectionView visibleCells];
        [arr enumerateObjectsUsingBlock:^(DNVerticalTimeViewCollectionViewCell * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
             CGRect fm = [self convertRect:obj.contentView.frame fromView:obj];
            if (fm.origin.y < 19.f && fm.origin.y + fm.size.height > 21.f) {
                if (!obj.isTipImageInTimeLinePosition) {
                    //move to position animation
                    _timeLine.timeLineType = TimeLineTypeEmpty;
                    _timeLabel.hidden = NO;
                    CGPoint finalPoint = CGPointMake(CGRectGetMidX(_tipImage.frame), CGRectGetMidY(_tipImage.frame));
                    _tipImage.frame = [self convertRect:obj.tipImageView.frame fromView:obj.contentView];
                    _tipImage.hidden = NO;
                    obj.tipImageView.hidden = YES;
                    UISnapBehavior *snap = [[UISnapBehavior alloc] initWithItem:_tipImage snapToPoint:finalPoint];
                    snap.damping = 0.4;
                    __weak UISnapBehavior *weakSnap = snap;
                    snap.action = ^ {
                        if (CGPointEqualToPoint(CGPointMake(CGRectGetMidX(_tipImage.frame), CGRectGetMidY(_tipImage.frame)), finalPoint)) {
                            weakSnap.action = nil;
                            [_animator removeAllBehaviors];
                        }
                    };
                    [_animator addBehavior:snap];
                    obj.isTipImageInTimeLinePosition = YES;
                }
            } else {
                if (obj.isTipImageInTimeLinePosition) {
                    //let tipImage move out from position
                    _timeLine.timeLineType = TimeLineTypeFill;
                    _timeLabel.hidden = YES;
                    _tipImage.hidden = YES;
                    obj.isTipImageInTimeLinePosition = NO;
                    obj.tipImageView.hidden = NO;
                }
            }
        }];
    }
}


@end





@implementation DNVerticalTimeViewCollectionViewCell

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self initUI];
    }
    return self;
}

- (void)initUI {
    
    self.contentView.backgroundColor = UIColorFromHexString(@"#F9F9F9");
    _isTipImageInTimeLinePosition = NO;
    
    if (!_tipImageView) {
        _tipImageView = [UIImageView new];
    }
    [self.contentView addSubview:_tipImageView];
    UIImage *moveImage = [UIImage imageNamed:@"messages_move"];
    [_tipImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.mas_equalTo(self.contentView.mas_centerY);
        make.size.mas_equalTo(moveImage.size);
        make.left.mas_equalTo(self.contentView.mas_left).offset(20.f);
    }];
    [_tipImageView setImage:moveImage];
    
    if (!_thumbnailImageView) {
        _thumbnailImageView = [UIImageView new];
    }
    [self.contentView addSubview:_thumbnailImageView];
    _thumbnailImageView.backgroundColor = [UIColor blackColor];
    _thumbnailImageView.layer.cornerRadius = 5.f;
    _thumbnailImageView.clipsToBounds = YES;
    _thumbnailImageView.layer.masksToBounds = YES;
    CGPoint thumbnailCenter = [self.contentView convertPoint:[UIApplication sharedApplication].keyWindow.center fromViewOrWindow:[UIApplication sharedApplication].keyWindow];
    [_thumbnailImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.size.mas_equalTo(CGSizeMake(self.contentView.frame.size.height * 16.f / 9.f, self.contentView.frame.size.height));
        make.top.mas_equalTo(self.contentView.mas_top);
        make.left.mas_equalTo(thumbnailCenter.x - (self.contentView.frame.size.height * 16.f / 9.f) / 2.f);
    }];

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




