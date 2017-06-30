//
//  DNTimeViewModel.h
//  NDanale
//
//  Created by Tristan on 2017/6/29.
//  Copyright © 2017年 Danale. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, DNTimeViewAlertType) {
    DNTimeViewAlertTypeMove,
    DNTimeViewAlertTypeSound
};

@interface DNTimeViewModel : NSObject

@property (nonatomic, assign) DNTimeViewAlertType alertType;
@property (nonatomic, assign) int64_t beginTime;
@property (nonatomic, assign) int64_t length;


@end
