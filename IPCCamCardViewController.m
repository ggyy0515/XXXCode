//
//  IPCCamCardViewController.m
//  NDanale
//
//  Created by chenweidong on 16/9/5.
//  Copyright © 2016年 chenweidong. All rights reserved.
//

#import "IPCCamCardViewController.h"
#import "IPCCamCardView.h"
#import "DanaleHeader.h"
#import "RootViewCellModel.h"

#import "DNVerticalTimeView.h"



@interface IPCCamCardViewController ()<IPCCamCardViewDelegate>
//@property(nonatomic, strong)IPCCamCardView *ipcCardView;

@property (nonatomic, strong) DNVerticalTimeView *timeView;

@end

@implementation IPCCamCardViewController


//-(IPCCamCardView *)ipcCardView{
//
//    if (!_ipcCardView) {
//        _ipcCardView = [[IPCCamCardView alloc] init];
//        _ipcCardView.delegate = self;
//    }
//    return _ipcCardView;
//}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.navigationController.navigationBarHidden = NO;
    self.automaticallyAdjustsScrollViewInsets = NO;
    self.view.backgroundColor = [UIColor blackColor];
    //    [self.view addSubview:self.ipcCardView];
    //    @weakify(self);
    //    [self.ipcCardView mas_makeConstraints:^(MASConstraintMaker *make) {
    //        @strongify(self);
    //        make.top.left.bottom.and.right.equalTo(self.view).with.insets(UIEdgeInsetsMake(0, 0, 0, 0));
    //
    //    }];
    //    [self.ipcCardView refreshUI];
    
    if (!_timeView) {
        _timeView = [[DNVerticalTimeView alloc] initWithFrame:CGRectMake(0, SCREEN_HEIGHT - 350.f, SCREEN_WIDTH, 350.f)];
    }
    [self.view addSubview:_timeView];
    
    CloudRecordModel *model1 = [[CloudRecordModel alloc] init];
    model1.chan_no = 1;
    model1.start_time = 1499954400000 + 60*60*24*1000*6;//22
    model1.device_id = @"123";
    model1.time_len = 50000;
    model1.record_type = 2;
    
    CloudRecordModel *model2 = [[CloudRecordModel alloc] init];
    model2.chan_no = 1;
    model2.start_time = 1499940000000 + 60*60*24*1000*6;//18
    model2.device_id = @"123";
    model2.time_len = 1050000;
    model2.record_type = 2;
    
    CloudRecordModel *model3 = [[CloudRecordModel alloc] init];
    model3.chan_no = 1;
    model3.start_time = 1499932800000 + 60*60*24*1000*6;//16
    model3.device_id = @"123";
    model3.time_len = 550000;
    model3.record_type = 2;
    
    CloudRecordModel *model4 = [[CloudRecordModel alloc] init];
    model4.chan_no = 1;
    model4.start_time = 1499922000000 + 60*60*24*1000*6;//13
    model4.device_id = @"123";
    model4.time_len = 850000;
    model4.record_type = 2;
    
    CloudRecordModel *model5 = [[CloudRecordModel alloc] init];
    model5.chan_no = 1;
    model5.start_time = 1499904000000 + 60*60*24*1000*6;//8
    model5.device_id = @"123";
    model5.time_len = 950000;
    model5.record_type = 2;
    
    
    [_timeView setDatas:@[model1, model2, model3, model4, model5].mutableCopy startTime:0];
    //
    //    [self performSelector:@selector(ggyy) withObject:nil afterDelay:3.f];
}

- (void)ggyy {
    [_timeView scrollToScale:1500040800000];
}
//- (void)fuck {
//    dispatch_async(dispatch_get_global_queue(0, 0), ^{
//        NSTimeInterval start = 1499738400;
//        for (NSInteger i = 0; i < 100; i ++) {
//            dispatch_async(dispatch_get_main_queue(), ^{
//                [_timeView scrollToScale:start];
//            });
//            start++;
//            sleep(1);
//        }
//    });
//}

//- (void)didReceiveMemoryWarning {
//    [super didReceiveMemoryWarning];
//    // Dispose of any resources that can be recreated.
//}
//
//- (void)viewDidAppear:(BOOL)animated{
//    [super viewDidAppear:animated];
//    if (_ipcCardView) {
//        [_ipcCardView  viewDidAppear];
//    }
//}
//
//- (void)viewWillDisappear:(BOOL)animated{
//    [super viewWillDisappear:animated];
//    if (_ipcCardView) {
//        [_ipcCardView  viewWillDisappear];
//    }

//}


#pragma mark - pPSCamCardViewDelegate
-(void)IPCCamCardView:(IPCCamCardView *)IPCCamCardView didSelectAction:(id)sender{
    
    
}


/*
 #pragma mark - Navigation
 
 // In a storyboard-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
 // Get the new view controller using [segue destinationViewController].
 // Pass the selected object to the new view controller.
 }
 */

@end
