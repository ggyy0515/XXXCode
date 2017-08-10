//
//  DNCloudAndSDDataLoader.h
//  NDanale
//
//  Created by Tristan on 2017/8/10.
//  Copyright © 2017年 Danale. All rights reserved.
//

#import <Foundation/Foundation.h>

@class UserDeviceModel;
@class CloudRecordModel;
@class CloudRecordPlayModel;
@class DeviceBaseInfoModel;
@class SDRecordModel;

@interface DNCloudAndSDDataLoader : NSObject

@property (nonatomic, strong) UserDeviceModel *deviceModel;

//-------------------------云录像方法--------------------------//
/**
 构造方法

 @param deviceModel userdeviceModel
 @return 实例对象
 */
- (instancetype)initWithUserDeviceModel:(UserDeviceModel *)deviceModel;

/**
 读取设备某一天的云录像数据模型
 
 @param time 该天的零点时间戳,ms
 @param chano 通道号
 @param response callback
 */
- (void)loadCloudRecordVideoWithTime:(int64_t)time
                               chano:(NSInteger)chano
                             success:(void (^)(int code, NSMutableArray * recordCallBackArr))response;

/**
 获取将要播放的那一段云录像对应的cloudRecordModel
 
 @param chano 通道号
 @param sourceTime 滑动到的时间
 @return model
 */
- (CloudRecordModel *)getPlayCloudRecordModelWithChano:(NSInteger)chano
                                            sourceTime:(NSTimeInterval)sourceTime;

/**
 根据选择的时间获取云录像播放信息实体
 
 @param sourceTime 选择的时间 s
 @param chano 通道号
 @param response 在回调中获得CloudRecordPlayModel
 */
- (void)getCloudRecordPlayModelWithTime:(NSTimeInterval)sourceTime
                                  chano:(NSInteger)chano
                                success:(void (^)(int code, CloudRecordPlayModel *cloudEntity))response;


//-------------------------SD卡录像方法--------------------------//

/**
 根据通道号读取设备及SD卡信息
 
 @param chano 通道号
 @param result 结果回调
 */
- (void)loadDeviceBaseInfoWithChano:(NSInteger)chano
                         completion:(void (^)(int32_t code,DeviceBaseInfoModel * model))result;

/**
 根据时间和通道号读取SD卡录像数据模型
 
 @param time 如果是当天，time为当前时刻  如果是前一天，time为前一天24点的时间戳
 @param chano 通道号
 @param result 回调
 */
- (void)loadSDRecordModelWithTime:(int64_t)time
                            chano:(NSInteger)chano
                           result:(void (^)(int32_t code,NSMutableArray * recordList))result;

/**
 获取将要播放的那一段云录像对应的sdRecordModel
 
 @param chano 通道
 @param sourceTime 选择的时间
 @return
 */
- (SDRecordModel *)getPlaySDRecordModelWithChano:(NSInteger)chano
                                      sourceTime:(NSTimeInterval)sourceTime;




@end
