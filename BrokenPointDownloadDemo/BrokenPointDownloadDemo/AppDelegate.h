//
//  AppDelegate.h
//  BrokenPointDownloadDemo
//
//  Created by mac on 2016/10/26.
//  Copyright © 2016年 LookTour. All rights reserved.
//

#import <UIKit/UIKit.h>
#define kDownloadProgressNotification @"downloadProgressNotification"
@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
//开始下载
- (void)beginDownloadWithUrl:(NSString *)downloadURLString;
//暂停下载
- (void)pauseDownload;
//继续下载
- (void)continueDownload;
@end

