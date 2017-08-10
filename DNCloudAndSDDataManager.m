//
//  DNCloudAndSDDataManager.m
//  NDanale
//
//  Created by Tristan on 2017/7/29.
//  Copyright © 2017年 Danale. All rights reserved.
//

#import "DNCloudAndSDDataManager.h"
#import "DanaleHeader.h"
#import "DanaleSDK.h"
#import "DNTimeViewModel.h"

@interface DNCloudAndSDDataManager ()

/**
 obj: <CloudRecordModel *>NSMutableArray, key: chano   单通道设备的chano默认为1
 */
@property (nonatomic, strong) NSMutableDictionary *cloudRecordModelDic;

/**
 obj: <SDRecordModel *>NSMutableArray, key:chano 单通道设备的chano默认为1
 */
@property (nonatomic, strong) NSMutableDictionary *sdRecordModelDic;

/**
 obj: <DNTimeViewModel *>NSMutableArray, key:"type_chano" 单通道设备的chano默认为1
 */
@property (nonatomic, strong) NSMutableDictionary *timeViewModelDic;

@end

@implementation DNCloudAndSDDataManager

#pragma mark - init

- (instancetype)initWithUserDeviceModel:(UserDeviceModel *)deviceModel {
    if (self = [super init]) {
        _cloudRecordModelDic = [NSMutableDictionary dictionary];
        _sdRecordModelDic = [NSMutableDictionary dictionary];
        _timeViewModelDic = [NSMutableDictionary dictionary];
        _deviceModel = deviceModel;
        _drawVideoType = CurrentVideoType_cloud;
    }
    return self;
}

#pragma mark - TimeView

- (void)loadTimeViewModelsWithTime:(int64_t)time
                             chano:(NSInteger)chano
                         needClean:(BOOL)clean
                           success:(void (^)(int code, NSMutableArray<DNTimeViewModel *> * recordCallBackArr))response {
    if (_drawVideoType == CurrentVideoType_cloud) {
        //cloud
        if (clean) {
            [_timeViewModelDic removeObjectForKey:[NSString stringWithFormat:@"cloud_%ld",chano]];
            [_cloudRecordModelDic removeObjectForKey:@(chano).stringValue];
            if (response) {
                response(0, [NSMutableArray array]);
            }
            return;
        }
        //先查询_timeViewModelDic中是否存在满足条件的model
        NSMutableArray <DNTimeViewModel *> *resArr = [NSMutableArray array];
        __block NSMutableArray <DNTimeViewModel *> * timeViewModels = [_timeViewModelDic objectForKey:[NSString stringWithFormat:@"cloud_%ld",chano]];
        if (timeViewModels) {
            if (![self isTodayWithTimestamp:time]) {
                [timeViewModels enumerateObjectsUsingBlock:^(DNTimeViewModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                    if (obj.startTime >= time && obj.startTime + obj.length < time + 60 * 60 * 24 * 1000) {
                        [resArr addObject:obj];
                    }
                }];
            }
        }
        if (resArr.count > 0) {
            if (response) {
                response(0, resArr);
            }
        } else {
            //_timeViewModelDic中不存在满足条件的model
            //先获取满足条件的cloudRecordModel
            [self queryCloudRecordVersion:^(CloudRecordVsersionType type) {
                [self loadCloudRecordVideoWithTime:time
                           cloudRecordVsersionType:type
                                             chano:chano
                                           success:^(int code, NSMutableArray <CloudRecordModel *> *callBackArr) {
                                               if (code == 0 && callBackArr.count > 0) {
                                                   if (!timeViewModels) {
                                                       timeViewModels = [NSMutableArray array];
                                                   }
                                                   [callBackArr enumerateObjectsUsingBlock:^(CloudRecordModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                                                       [timeViewModels addObject:[DNTimeViewModel modelWithCloudRecordModelOrSdRecordModel:obj]];
                                                   }];
                                                   [_timeViewModelDic setObject:timeViewModels forKey:[NSString stringWithFormat:@"cloud_%ld",chano]];
                                                   if (response) {
                                                       response (0, timeViewModels);
                                                   }
                                               } else {
                                                   if (response) {
                                                       response (code, nil);
                                                   }
                                               }
                                           }];
            }];
        }
    } else {
        //sd
        if (clean) {
            [_timeViewModelDic removeObjectForKey:[NSString stringWithFormat:@"sd_%ld",chano]];
            [_sdRecordModelDic removeAllObjects];
            if (response) {
                response(0,[NSMutableArray array]);
            }
            return;
        }
        //先查询_timeViewModelDic中是否存在满足条件的model
        NSMutableArray <DNTimeViewModel *> *resArr = [NSMutableArray array];
        __block NSMutableArray <DNTimeViewModel *> * timeViewModels = [_timeViewModelDic objectForKey:[NSString stringWithFormat:@"sd_%ld",chano]];
        if (timeViewModels) {
            if (![self isTodayWithTimestamp:time]) {
                [timeViewModels enumerateObjectsUsingBlock:^(DNTimeViewModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                    if (obj.startTime >= time && obj.startTime + obj.length < time + 60 * 60 * 24 * 1000) {
                        [resArr addObject:obj];
                    }
                }];
            }
        }
        if (resArr.count > 0) {
            if (response) {
                response(0, resArr);
            }
        } else {
            [self loadSDRecordModelWithTime:time
                                      chano:chano
                                     result:^(int32_t code, NSMutableArray <SDRecordModel *> *recordList) {
                                         if (code == 0 && recordList.count > 0) {
                                             if (!timeViewModels) {
                                                 timeViewModels = [NSMutableArray array];
                                             }
                                             [recordList enumerateObjectsUsingBlock:^(SDRecordModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                                                 [timeViewModels addObject:[DNTimeViewModel modelWithCloudRecordModelOrSdRecordModel:obj]];
                                             }];
                                             [_timeViewModelDic setObject:timeViewModels forKey:[NSString stringWithFormat:@"sd_%ld",chano]];
                                             if (response) {
                                                 response (0, timeViewModels);
                                             }
                                         } else {
                                             if (response) {
                                                 response (code, nil);
                                             }
                                         }
                                     }];
        }
    }
}

- (BOOL)isTodayWithTimestamp:(int64_t)sourceTime {
    NSDateFormatter *ft = [[NSDateFormatter alloc] init];
    [ft setDateFormat:@"yyyyMMdd"];
    NSString *sourceZeroTimeStrng = [ft stringFromDate:[NSDate dateWithTimeIntervalSinceNow:((NSTimeInterval)sourceTime / 1000)]];
    NSString *currentZeroString = [ft stringFromDate:[NSDate date]];
    return [sourceZeroTimeStrng compare:currentZeroString] == NSOrderedSame;
    
}

- (void)setDrawVideoType:(CurrentVideoType)drawVideoType {
    if (_drawVideoType != drawVideoType) {
        _drawVideoType = drawVideoType;
        if (_hasChangeDrawVideoType) {
            _hasChangeDrawVideoType();
        }
    }
    _drawVideoType = drawVideoType;
}


#pragma mark - CloudRecord

/**
 查询云录像版本类型

 @param completionBlock 回调(目前仅支持 CloudRecordVsersion_Old)
 */
- (void)queryCloudRecordVersion:(void (^)(CloudRecordVsersionType))completionBlock {
    completionBlock(CloudRecordVsersion_Old);
}


/**
 读取设备某一天的云录像数据模型

 @param time 该天的零点时间戳,ms
 @param type 云录像版本类型
 @param chano 通道号
 @param response callback
 */
- (void)loadCloudRecordVideoWithTime:(int64_t)time
             cloudRecordVsersionType:(CloudRecordVsersionType)type
                               chano:(NSInteger)chano
                             success:(void (^)(int code, NSMutableArray * recordCallBackArr))response {
    if (type == CloudRecordVsersion_Old) {
        //cloudRecordModelDic中如果存在该天的数据，直接取出
        NSMutableArray <CloudRecordModel *> *resArr = [NSMutableArray array];
        __block NSMutableArray <CloudRecordModel *> *cloudRecordModels = [_cloudRecordModelDic objectForKey:@(chano).stringValue];
        if (cloudRecordModels) {
            if (![self isTodayWithTimestamp:time]) {
                [cloudRecordModels enumerateObjectsUsingBlock:^(CloudRecordModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                    if (obj.start_time >= time && obj.start_time + obj.time_len < time + 60 * 60 * 24 * 1000) {
                        [resArr addObject:obj];
                    }
                }];
            }
        }
        if (resArr.count > 0) {
            response(0, resArr);
            return;
        } else {
            //cloudRecordModelDic中不存在这一天的云录像数据，加载网络数据
            [[DanaleCloudeConnection manager] getCloudRecordInfo:222
                                                          device:_deviceModel.device_id
                                                        withChan:chano
                                                        withTime:time
                                                         success:^(int code, NSMutableArray <CloudRecordModel *> *recordCallBackArr) {
                                                             if (code == 0) {
                                                                 if (recordCallBackArr.count == 0 && IS_NORMAL_RESPONDDELEGATE_FUNC(_delegate, @selector(cloudAndSDDataManager:hasLoadAllCloudRecordDataWithChano:))) {
                                                                     [_delegate cloudAndSDDataManager:self hasLoadAllCloudRecordDataWithChano:chano];
                                                                 }
                                                                 [recordCallBackArr sortUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"start_time" ascending:YES]]];
                                                                 //把读取到的加入到数组里面
                                                                 if (!cloudRecordModels) {
                                                                     cloudRecordModels = [NSMutableArray array];
                                                                 }
                                                                 [cloudRecordModels addObjectsFromArray:recordCallBackArr];
                                                                 [cloudRecordModels sortUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"start_time" ascending:YES]]];
                                                                 [_cloudRecordModelDic setObject:cloudRecordModels forKey:@(chano).stringValue];
                                                                 response(0, recordCallBackArr);
                                                             } else {
                                                                 response(-1, nil);
                                                             }
                                                         }];
        }
    }
}


/**
 获取将要播放的那一段云录像对应的cloudRecordModel

 @param chano 通道号
 @param sourceTime 滑动到的时间
 @return model
 */
- (CloudRecordModel *)getPlayCloudRecordModelWithChano:(NSInteger)chano
                                            sourceTime:(NSTimeInterval)sourceTime {
    NSMutableArray <CloudRecordModel *> *cloudRecordModels = [_cloudRecordModelDic objectForKey:@(chano).stringValue];
    __block CloudRecordModel *model = nil;
    [cloudRecordModels enumerateObjectsUsingBlock:^(CloudRecordModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (obj.start_time < sourceTime * 1000 && obj.start_time + obj.time_len >= sourceTime * 1000) {
            model = obj;
            *stop = YES;
            return;
        }
        if (obj.start_time >= sourceTime * 1000) {
            model = obj;
            *stop = YES;
        }
    }];
    return model;
}


- (void)getCloudRecordPlayModelWithTime:(NSTimeInterval)sourceTime
                                  chano:(NSInteger)chano
                                success:(void (^)(int code, CloudRecordPlayModel *cloudEntity))response {
    CloudRecordModel *cloudRecordModel = [self getPlayCloudRecordModelWithChano:chano sourceTime:sourceTime];
    if (!cloudRecordModel) {
        response(-1, nil);
        return;
    }
    [[DanaleCloudeConnection manager] getCloudPlayTime:111
                                              deviceid:self.deviceModel.device_id
                                              withChan:@(chano).intValue
                                       withCurrentTime:cloudRecordModel.start_time
                                               success:^(int code, CloudRecordPlayModel *cloudEntity) {
                                                   if (code == 0) {
                                                       response(0, cloudEntity);
                                                   } else {
                                                       response(code, nil);
                                                   }
                                               }];
}


#pragma mark - SD Card


/**
 在这个Setter里面判断是否需要断开连接，并回调

 @param currtenVideoType
 */
- (void)setCurrtenVideoType:(CurrentVideoType)currtenVideoType {
    if ((_currtenVideoType == CurrentVideoType_live || _currtenVideoType == CurrentVideoType_SD) &&
        currtenVideoType != _currtenVideoType &&
        (currtenVideoType == CurrentVideoType_SD || currtenVideoType == CurrentVideoType_live)) {
        //需要断开连接
        if (IS_NORMAL_RESPONDDELEGATE_FUNC(_delegate, @selector(shouldDoCloseVideoConnectionAction))) {
            [_delegate shouldDoCloseVideoConnectionAction];
        }
    }
    _currtenVideoType = currtenVideoType;
}


/**
 根据通道号读取设备及SD卡信息

 @param chano 通道号
 @param result 结果回调
 */
- (void)loadDeviceBaseInfoWithChano:(NSInteger)chano
                         completion:(void (^)(int32_t code,DeviceBaseInfoModel * model))result {
    [[DeviceCMDOpration manager] getBaseInfoWithDevice:_deviceModel.device_id
                                               channel:@(chano).intValue
                                                result:^(int32_t code, DeviceBaseInfoModel *model) {
                                                    if (code == 0) {
                                                        result(0, model);
                                                    } else {
                                                        result(-1, nil);
                                                    }
                                                }];
}


/**
 根据时间和通道号读取SD卡录像数据模型

 @param time 如果是当天，time为当前时刻  如果是前一天，time为前一天24点的时间戳
 @param chano 通道号
 @param result 回调
 */
- (void)loadSDRecordModelWithTime:(int64_t)time
                            chano:(NSInteger)chano
                           result:(void (^)(int32_t code,NSMutableArray * recordList))result {
    //先在sdRecordModel中查询一把，有的话直接抛出
    NSMutableArray *resArr = [NSMutableArray array];
    __block NSMutableArray <SDRecordModel *> *sdRecordModels = [_sdRecordModelDic objectForKey:@(chano).stringValue];
    if (sdRecordModels) {
        if (![self isTodayWithTimestamp:time]) {
            [sdRecordModels enumerateObjectsUsingBlock:^(SDRecordModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                if (obj.start_time >= time && obj.start_time + obj.length < time + 60 * 60 * 24 * 1000) {
                    [resArr addObject:obj];
                }
            }];
        }
    }
    if (resArr.count > 0) {
        result(0, resArr);
        return;
    } else {
        [[DeviceCMDOpration manager] getSDCardRecordListWithDevice:_deviceModel.device_id
                                                           channel:@(chano).intValue
                                                           getType:1
                                                          lastTime:time/1000
                                                            result:^(int32_t code, NSMutableArray *recordList) {
                                                                if (code == 0) {
                                                                    [recordList sortUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"start_time" ascending:YES]]];
                                                                    if (!sdRecordModels) {
                                                                        sdRecordModels = [NSMutableArray array];
                                                                    }
                                                                    [sdRecordModels addObjectsFromArray:recordList];
                                                                    [sdRecordModels sortUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"start_time" ascending:YES]]];
                                                                    [_sdRecordModelDic setObject:sdRecordModels forKey:@(chano).stringValue];
                                                                    result(0, recordList);
                                                                } else {
                                                                    result(-1, nil);
                                                                }
                                                            }];
    }
    
}

/**
 根据SD卡状态重新刷新数据
 
 @param status status
 */
- (void)reloadDataWithSDCardStatus:(SDCardStatus)status{
    if (status != SDCardStatusNormal) {
        @weakify(self);
        [self loadTimeViewModelsWithTime:0 chano:0 needClean:YES success:^(int code, NSMutableArray<DNTimeViewModel *> *recordCallBackArr) {
            @strongify(self);
            if (self.reloadDataBlock) {
                self.reloadDataBlock(code, recordCallBackArr);
            }
        }];
    }
}

/**
 获取将要播放的那一段云录像对应的sdRecordModel

 @param chano 通道
 @param sourceTime 选择的时间
 @return
 */
- (SDRecordModel *)getPlaySDRecordModelWithChano:(NSInteger)chano
                                      sourceTime:(NSTimeInterval)sourceTime {
    NSMutableArray <SDRecordModel *> *sdRecordModels = [_sdRecordModelDic objectForKey:@(chano).stringValue];
    __block SDRecordModel *model = nil;
    [sdRecordModels enumerateObjectsUsingBlock:^(SDRecordModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (obj.start_time < sourceTime * 1000 && obj.start_time + obj.length >= sourceTime * 1000) {
            model = obj;
            *stop = YES;
            return;
        }
        if (obj.start_time >= sourceTime * 1000) {
            model = obj;
            *stop = YES;
        }
    }];
    return model;
}


#pragma mark - 交互接口

//__________________________________________时间轴接口__________________________________________

/**
 滚动到某时刻
 
 @param timeLineTime 时间线上的时间 ms
 @param timeViewModel 可播放的timeViewModel
 */
- (void)didScrollToTime:(NSTimeInterval)timeLineTime timeViewModel:(DNTimeViewModel *)timeViewModel {
    if (_didScrollToTime) {
        _didScrollToTime (timeLineTime, timeViewModel);
    }
}


//__________________________________________playView接口__________________________________________

- (void)didFinishPlayWithTimeViewModel:(DNTimeViewModel *)timeViewModel interruptType:(playerInterruptType)intertuptType videoType:(CurrentVideoType)videoType {
    if (_didFinishPlay) {
        _didFinishPlay (timeViewModel, intertuptType, videoType);
    }
}

- (void)shouldPlayWithVideoType:(CurrentVideoType)type {
    if (_shouldPlayVideo) {
        _shouldPlayVideo(_currtenVideoType);
    }
}

- (void)timeViewShouldScroll{
    if (_timeViewShouldScrol) {
        _timeViewShouldScrol();
    }
}


@end
