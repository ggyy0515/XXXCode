//
//  DNCloudAndSDDataManager.h
//  NDanale
//
//  Created by Tristan on 2017/7/29.
//  Copyright © 2017年 Danale. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DanaleEnumDefine.h"

@class UserDeviceModel;
@class DNCloudAndSDDataManager;
@class CloudRecordPlayModel;
@class DeviceBaseInfoModel;
@class DNTimeViewModel;

typedef NS_ENUM(NSInteger, CloudRecordVsersionType) {
    CloudRecordVsersion_Unkown,
    CloudRecordVsersion_Old,
    CloudRecordVsersion_New,
};

typedef NS_ENUM(NSInteger, CurrentVideoType) {
    CurrentVideoType_live = 100,
    CurrentVideoType_cloud,
    CurrentVideoType_SD
};

/**
 播放完成类型

 - playerInterruptType_userInterrupt: 用户中断
 - playerInterruptType_finish: 播放结束
 - playerInterruptType_error: 发生错误
 */
typedef NS_ENUM(NSInteger, playerInterruptType) {
    playerInterruptType_userInterrupt,
    playerInterruptType_finish,
    playerInterruptType_error,
    playerInterruptType_changeVideoType
};

@protocol DNCloudAndSDDataManagerDelegate <NSObject>

@optional

/**
 某通道已经加载完全部云录像记录数据模型时触发

 @param manager manager
 @param chano 通道号
 */
- (void)cloudAndSDDataManager:(DNCloudAndSDDataManager *)manager hasLoadAllCloudRecordDataWithChano:(NSInteger)chano;

/**
 某通道已经加载完全部SD卡记录数据模型时触发

 @param manager manager
 @param chano 通道号
 */
- (void)cloudAndSDDataManager:(DNCloudAndSDDataManager *)manager hasLoadAlSDRecordDataWithChano:(NSInteger)chano;

/**
 需要在此代理回调中断开视频连接
 */
- (void)shouldDoCloseVideoConnectionAction;


@end

@interface DNCloudAndSDDataManager : NSObject

/**
 当前播放视频的类型，每次切换时必须传入
 */
@property (nonatomic, assign) CurrentVideoType currtenVideoType;
@property (nonatomic, strong) UserDeviceModel *deviceModel;
@property (nonatomic, weak) id <DNCloudAndSDDataManagerDelegate> delegate;
@property (copy, nonatomic) void(^reloadDataBlock)(int code , NSMutableArray<DNTimeViewModel *> * models);

@property (nonatomic, assign) NSInteger currentChano;
/**
 表示绘制时间轴类型
 */
@property (nonatomic, assign) CurrentVideoType drawVideoType;

- (instancetype)initWithUserDeviceModel:(UserDeviceModel *)deviceModel;

//---------------时间轴------------------//

/**
 获取时间轴数据模型
 
 @param time 当天的0点
 @param chano 通道号
 @param clean 是否需要清除缓存（在查询设备状态失败的情况下使用）
 @param response 
 */
- (void)loadTimeViewModelsWithTime:(int64_t)time
                             chano:(NSInteger)chano
                         needClean:(BOOL)clean
                           success:(void (^)(int code, NSMutableArray<DNTimeViewModel *> * recordCallBackArr))response;

//---------------云录像------------------//

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
                             success:(void (^)(int code, NSMutableArray * recordCallBackArr))response;

/**
 根据选择的时间获取云录像播放信息实体

 @param sourceTime 选择的时间 s
 @param chano 通道号
 @param response 在回调中获得CloudRecordPlayModel
 */
- (void)getCloudRecordPlayModelWithTime:(NSTimeInterval)sourceTime
                                  chano:(NSInteger)chano
                                success:(void (^)(int code, CloudRecordPlayModel *cloudEntity))response;

/**
 查询云录像版本类型
 
 @param completionBlock 回调(目前仅支持 CloudRecordVsersion_Old)
 */
- (void)queryCloudRecordVersion:(void (^)(CloudRecordVsersionType))completionBlock;

//---------------SD卡------------------//

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
 根据SD卡状态重新刷新数据

 @param status status
 */
- (void)reloadDataWithSDCardStatus:(SDCardStatus)status;

//__________________________________________时间轴接口__________________________________________

@property (nonatomic, copy) void(^hasChangeDrawVideoType)();

/**
 滚动到某时刻

 @param timeLineTime 时间线上的时间 ms
 @param timeViewModel 可播放的timeViewModel
 */
- (void)didScrollToTime:(NSTimeInterval)timeLineTime timeViewModel:(DNTimeViewModel *)timeViewModel;

/**
 结束播放的回调
 */
@property (nonatomic, copy) void(^didFinishPlay)(DNTimeViewModel *timeViewModel, playerInterruptType intertuptType, CurrentVideoType videoType);

/**
 准备播放回调
 */
@property (nonatomic, copy) void(^shouldPlayVideo)(CurrentVideoType type);

/**
 滚动时间轴
 */
@property (nonatomic, copy) void(^timeViewShouldScrol)();



//__________________________________________playView接口__________________________________________

/**
 滚动到某时刻的block回调  timeLimeTime(s)
 */
@property (nonatomic, copy) void(^didScrollToTime)(NSTimeInterval timeLimeTime, DNTimeViewModel *timeViewModel);

/**
 将要播放某时刻的录像  timeLimeTime(s)
 */
@property (nonatomic, copy) void(^willPlayNextModelWithTime)(NSTimeInterval timeLimeTime, DNTimeViewModel *timeViewModel);

/**
 playView结束了播放

 @param timeViewModel 数据模型
 @param intertuptType 中断类型
 @param videoType 中断时的视屏类型
 */
- (void)didFinishPlayWithTimeViewModel:(DNTimeViewModel *)timeViewModel interruptType:(playerInterruptType)intertuptType videoType:(CurrentVideoType)videoType;

/**
 准备播放，在断开连接并且不是通过滚动时候调用

 @param type type
 */
- (void)shouldPlayWithVideoType:(CurrentVideoType)type;

/**
 滚动时间轴
 */
- (void)timeViewShouldScroll;

@end
