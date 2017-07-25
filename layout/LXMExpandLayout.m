//
//  LXMExpandLayout.m
//  LXMExpandLayoutDemo
//
//  Created by luxiaoming on 15/5/27.
//  Copyright (c) 2015年 luxiaoming. All rights reserved.
//

#import "LXMExpandLayout.h"
#import "LXMCopiedView.h"

typedef NS_ENUM(NSInteger, LXMAutoScrollDirection) {
    LXMAutoScrollDirectionNone = 0,
    LXMAutoScrollDirectionUp,
    LXMAutoScrollDirectionDown,
};


@interface LXMExpandLayout ()<UIGestureRecognizerDelegate>

@property (nonatomic, assign) CGFloat itemWidth;
@property (nonatomic, assign) CGFloat itemHeight;
@property (nonatomic, assign) CGFloat expandedItemWidth;
@property (nonatomic, assign) CGFloat expandedItemHeight;
@property (nonatomic, assign) CGFloat expandedFactor;
@property (nonatomic, assign) CGFloat collectionViewWidth;
@property (nonatomic, assign) CGFloat orderedItemAlpha;


@property (nonatomic, assign) CGFloat selectedItemOriginalY;
@property (nonatomic, assign) CGFloat padding;//item 之间的间隔
@property (nonatomic, assign) NSInteger numberOfItemsInRow;

@property (nonatomic, strong) NSArray *sameRowItemArray;

//手势相关
@property (nonatomic, assign) BOOL isGestureSetted;
@property (nonatomic, strong) UILongPressGestureRecognizer *longPressGesture;
@property (nonatomic, strong) UIPanGestureRecognizer *panGesture;
@property (nonatomic, assign) CGPoint panTranslation;
@property (nonatomic, strong) LXMCopiedView *fakeCellView;
@property (nonatomic, strong) CADisplayLink *displayLink;
@property (nonatomic, assign) LXMAutoScrollDirection autoScrollDirection;

@end

@implementation LXMExpandLayout


- (instancetype)init {
    self = [super init];
    if (self) {
        self.numberOfItemsInRow = 1;//这里必须不能是0，否则下面会出现0/0的bug
        self.seletedIndexPath = [NSIndexPath indexPathForItem:0 inSection:0];
        self.orderedItemAlpha = 0.5;
    }
    return self;
}

- (void)prepareLayout {
    [super prepareLayout];
    //这个方法是在viewDidLayoutSubview之后调用的，所以这时候collectionView的大小才是正确的
    self.itemWidth = self.itemSize.width;
    self.itemHeight = self.itemSize.height;
    self.collectionViewWidth = CGRectGetWidth(self.collectionView.frame);
    self.numberOfItemsInRow = [[super layoutAttributesForElementsInRect:CGRectMake(0, 0, self.collectionViewWidth - self.sectionInset.left - self.sectionInset.right, self.itemHeight)] count];//取出按默认位置一行应该有几个item
    if (self.numberOfItemsInRow <= 3) {
        self.numberOfItemsInRow = 3;//这里必须加这一句判断，否则当cell个数小于3时会出问题
    }
    self.padding = (self.collectionViewWidth - self.itemWidth * self.numberOfItemsInRow - self.sectionInset.left - self.sectionInset.right) / (self.numberOfItemsInRow - 1);
    self.expandedItemWidth = self.collectionViewWidth - self.itemWidth - self.padding - self.sectionInset.left - self.sectionInset.right;
    self.expandedFactor = self.expandedItemWidth / self.itemWidth;
    self.expandedItemHeight = self.itemHeight * self.expandedFactor;
    
    [self setupGesture];
}



- (CGSize)collectionViewContentSize {
    CGSize newSize = [super collectionViewContentSize];
    newSize.height += (self.expandedItemHeight - self.itemHeight);
    return newSize;
}



#pragma mark - publicMethod




#pragma mark - privateMethod

- (BOOL)isItemInTheSelectedIndexPathRowWithUICollectionViewLayoutAttributes:(UICollectionViewLayoutAttributes *)attributes {
    BOOL result = NO;
    for (UICollectionViewLayoutAttributes *tempAttributes in self.sameRowItemArray) {
        if (tempAttributes.indexPath.row == attributes.indexPath.row
            && tempAttributes.indexPath.section == attributes.indexPath.section) {
            result = YES;
            break;
        }
    }
    return result;
}

- (BOOL)shouldItemExpandToLeftWithAttributes:(UICollectionViewLayoutAttributes *)attributes {
    BOOL result = YES;
    NSInteger index = attributes.indexPath.item % self.numberOfItemsInRow;
    NSInteger centerIndex = ceilf(self.numberOfItemsInRow / 2.0);
    if (index >= centerIndex) {
        result = NO;
    }
    return result;
}

- (void)setupGesture {
    if (self.isGestureSetted == NO) {
        _longPressGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPressGesture:)];
        _longPressGesture.delegate = self;
        [self.collectionView addGestureRecognizer:_longPressGesture];
        
        _panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePanGesture:)];
        _panGesture.delegate = self;
        [self.collectionView addGestureRecognizer:_panGesture];
        
        self.isGestureSetted = YES;
    }
}


- (void)moveItemIfNeeded {
    NSIndexPath *atIndexPath = self.fakeCellView.indexPath;
    NSIndexPath *toIndexPath = [self.collectionView indexPathForItemAtPoint:self.fakeCellView.center];
    if (toIndexPath == nil || [toIndexPath isEqual:atIndexPath]) {
        return;
    }
    
    [self.collectionView performBatchUpdates:^{
        self.fakeCellView.indexPath = toIndexPath;//注意这一句必须写，否则会出问题
        [self.collectionView moveItemAtIndexPath:atIndexPath toIndexPath:toIndexPath];
    } completion:^(BOOL finished) {
        if ([self.delegate respondsToSelector:@selector(lxmExpandLayout:didMoveItemAtIndexPath:toIndexPath:)]) {
            [self.delegate lxmExpandLayout:self didMoveItemAtIndexPath:atIndexPath toIndexPath:toIndexPath];
        }
    }];
}

- (void)setUpDisplayLink {
    if (_displayLink) {
        return;
    }
    _displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(autoScroll)];
    [_displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
}

-  (void)invalidateDisplayLink {
    [_displayLink invalidate];
    _displayLink = nil;
}

- (void)autoScroll {
    CGPoint newContentOffset = self.collectionView.contentOffset;
    if (self.autoScrollDirection == LXMAutoScrollDirectionUp) {
        NSLog(@"LXMAutoScrollDirectionUp");
        newContentOffset.y -= 10;
        if (newContentOffset.y < - self.collectionView.contentInset.top) {
            newContentOffset.y = - self.collectionView.contentInset.top;
            [self invalidateDisplayLink];
        }
        [self.collectionView setContentOffset:newContentOffset animated:NO];
        self.fakeCellView.originalCenter = CGPointMake(self.fakeCellView.originalCenter.x, self.fakeCellView.originalCenter.y - 10);
        self.fakeCellView.center = CGPointMake(self.fakeCellView.originalCenter.x + self.panTranslation.x, self.fakeCellView.originalCenter.y + self.panTranslation.y);
        NSLog(@"panTranslation is %@", NSStringFromCGPoint(self.panTranslation));
    } else if (self.autoScrollDirection == LXMAutoScrollDirectionDown) {
        NSLog(@"LXMAutoScrollDirectionDown");
        newContentOffset.y += 10;
        if (newContentOffset.y >= self.collectionViewContentSize.height - CGRectGetHeight(self.collectionView.bounds)) {
            newContentOffset.y = self.collectionViewContentSize.height - CGRectGetHeight(self.collectionView.bounds);
            [self invalidateDisplayLink];
        }
        [self.collectionView setContentOffset:newContentOffset animated:NO];
        self.fakeCellView.originalCenter = CGPointMake(self.fakeCellView.originalCenter.x, self.fakeCellView.originalCenter.y + 10);
        self.fakeCellView.center = CGPointMake(self.fakeCellView.originalCenter.x + self.panTranslation.x, self.fakeCellView.originalCenter.y + self.panTranslation.y);
    } else {
        [self invalidateDisplayLink];
        return;
    }
}

#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    if (gestureRecognizer == self.panGesture) {
        if (self.longPressGesture.state == UIGestureRecognizerStatePossible ||
            self.longPressGesture.state == UIGestureRecognizerStateFailed) {
            //如果长按手势没有识别处理，则pan手势不能执行
            return NO;
        }
    } else if (gestureRecognizer == self.longPressGesture) {
        if (self.collectionView.panGestureRecognizer.state != UIGestureRecognizerStatePossible &&
            self.collectionView.panGestureRecognizer.state !=UIGestureRecognizerStateFailed) {
            //如果系统的pan手势识别出来了，则长按手势不应该被执行
            return NO;
        }
    }
    return YES;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    if ([gestureRecognizer isEqual:self.panGesture]
        && [otherGestureRecognizer isEqual:self.longPressGesture]) {
        return YES;
    } else if ([gestureRecognizer isEqual:self.longPressGesture]
               && [otherGestureRecognizer isEqual:self.panGesture]) {
        return YES;
    } else {
        return NO;
    }
}

#pragma mark - gestureAction

- (void)handleLongPressGesture:(UILongPressGestureRecognizer *)sender {
    if (sender.state == UIGestureRecognizerStateBegan) {
        CGPoint loaction = [sender locationInView:self.collectionView];
        NSIndexPath *longPressedIndexPath = [self.collectionView indexPathForItemAtPoint:loaction];
        if (longPressedIndexPath) {
            self.collectionView.scrollsToTop = NO;
            UICollectionViewCell *cell  = [self.collectionView cellForItemAtIndexPath:longPressedIndexPath];
            self.fakeCellView = [[LXMCopiedView alloc] initWithTargetView:cell andIndexPath:longPressedIndexPath];
            [self.collectionView addSubview:self.fakeCellView];
//            [self invalidateLayout];//这句是干什么用的？
            [UIView animateWithDuration:0.4 delay:0 options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionCurveEaseInOut animations:^{
                self.fakeCellView.bounds = CGRectMake(0, 0, self.itemWidth * 1.1, self.itemHeight * 1.1);
                cell.alpha = self.orderedItemAlpha;
            } completion:^(BOOL finished) {
                
            }];
            
            
        } else {
            return;//当前位置没有cell
        }
        
        
    } else if (sender.state == UIGestureRecognizerStateEnded ||
               sender.state == UIGestureRecognizerStateCancelled) {
        self.collectionView.scrollsToTop = YES;
        UICollectionViewCell *cell = [self.collectionView cellForItemAtIndexPath:self.fakeCellView.indexPath];
        cell.alpha = 1.0;//加上这一句是防止没有移动时cell没有恢复原状的问题
        [self.fakeCellView removeFromSuperview];
        self.fakeCellView = nil;
        [self invalidateLayout];
        [self invalidateDisplayLink];
    } else {

    }
    
}

- (void)handlePanGesture:(UIPanGestureRecognizer *)sender {
    if (sender.state == UIGestureRecognizerStateChanged) {
        self.panTranslation = [sender translationInView:self.collectionView];
        self.fakeCellView.center = CGPointMake(self.fakeCellView.originalCenter.x + self.panTranslation.x, self.fakeCellView.originalCenter.y + self.panTranslation.y);
        [self moveItemIfNeeded];
        
        //autoScroll
        if (CGRectGetMaxY(self.fakeCellView.frame) > self.collectionView.contentOffset.y + CGRectGetHeight(self.collectionView.bounds) &&
            CGRectGetMaxY(self.fakeCellView.frame) < self.collectionViewContentSize.height) {
           
            self.autoScrollDirection = LXMAutoScrollDirectionDown;
            [self setUpDisplayLink];
        } else if (CGRectGetMinY(self.fakeCellView.frame) < self.collectionView.contentOffset.y + self.collectionView.contentInset.top &&
                   self.collectionView.contentOffset.y > - 64) {
//            NSLog(@"fakeViewFrame is %@", NSStringFromCGRect(self.fakeCellView.frame));
//            NSLog(@"offset is %@", NSStringFromCGPoint(self.collectionView.contentOffset));
            self.autoScrollDirection = LXMAutoScrollDirectionUp;
            [self setUpDisplayLink];
        } else {
            self.autoScrollDirection = LXMAutoScrollDirectionNone;
            [self invalidateDisplayLink];
        }
        
        
        
    }
    if (sender.state == UIGestureRecognizerStateEnded ||
        sender.state == UIGestureRecognizerStateCancelled) {
        //结束写在longPress的手势里了，所以这里不用写了
    }
    
}

@end








#pragma mark - UICollectionView 扩展

@implementation UICollectionView (LXMExpandLayout)

- (void)expandItemAtIndexPath:(NSIndexPath *)indexPath animated:(BOOL)animated {
    LXMExpandLayout *layout = (LXMExpandLayout *)self.collectionViewLayout;
    if (animated) {
        //用UIView Animation 包住performBatchUpdates可以使view的Animation代替collectionView默认的动画
        [UIView animateWithDuration:0.6 delay:0 usingSpringWithDamping:0.5 initialSpringVelocity:0.3 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            [self performBatchUpdates:^{
                if (layout.layoutCoolType == LayoutColType_one) {
                    layout.layoutCoolType = LayoutColType_two;
                } else {
                    layout.layoutCoolType = LayoutColType_one;
                }
            } completion:^(BOOL finished) {
                
            }];
        } completion:^(BOOL finished) {
            
        }];
        
    } else {
        layout.seletedIndexPath = indexPath;
        [layout invalidateLayout];
    }
}


@end
