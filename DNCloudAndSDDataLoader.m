//
//  DNCloudAndSDDataLoader.m
//  NDanale
//
//  Created by Tristan on 2017/8/10.
//  Copyright © 2017年 Danale. All rights reserved.
//

#import "DNCloudAndSDDataLoader.h"
#import "DanaleHeader.h"
#import "DanaleSDK.h"

@interface DNCloudAndSDDataLoader ()

/**
 obj: <CloudRecordModel *>NSMutableArray, key: chano   单通道设备的chano默认为1
 */
@property (nonatomic, strong) NSMutableDictionary *cloudRecordModelDic;

/**
 obj: <SDRecordModel *>NSMutableArray, key:chano 单通道设备的chano默认为1
 */
@property (nonatomic, strong) NSMutableDictionary *sdRecordModelDic;


@end

@implementation DNCloudAndSDDataLoader

#pragma mark - init

- (instancetype)initWithUserDeviceModel:(UserDeviceModel *)deviceModel {
    if (self = [super init]) {
        _cloudRecordModelDic = [NSMutableDictionary dictionary];
        _sdRecordModelDic = [NSMutableDictionary dictionary];
        _deviceModel = deviceModel;
    }
    return self;
}

#pragma mark - Private


/**
 判断时间戳是否是今天

 @param sourceTime ms
 @return
 */
- (BOOL)isTodayWithTimestamp:(int64_t)sourceTime {
    NSDateFormatter *ft = [[NSDateFormatter alloc] init];
    [ft setDateFormat:@"yyyyMMdd"];
    NSString *sourceZeroTimeStrng = [ft stringFromDate:[NSDate dateWithTimeIntervalSinceNow:((NSTimeInterval)sourceTime / 1000)]];
    NSString *currentZeroString = [ft stringFromDate:[NSDate date]];
    return [sourceZeroTimeStrng compare:currentZeroString] == NSOrderedSame;
    
}

#pragma mark - CloudRecord

/**
 读取设备某一天的云录像数据模型
 
 @param time 该天的零点时间戳,ms
 @param chano 通道号
 @param response callback
 */
- (void)loadCloudRecordVideoWithTime:(int64_t)time
                               chano:(NSInteger)chano
                             success:(void (^)(int code, NSMutableArray * recordCallBackArr))response {
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


/**
 根据选择的时间获取云录像播放信息实体
 
 @param sourceTime 选择的时间 s
 @param chano 通道号
 @param response 在回调中获得CloudRecordPlayModel
 */
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


@end
