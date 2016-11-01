//
//  AppDelegate.m
//  BrokenPointDownloadDemo
//
//  Created by mac on 2016/10/26.
//  Copyright © 2016年 LookTour. All rights reserved.
//

#import "AppDelegate.h"
#import "NSURLSession+CorrectedResumeData.h"
#import <UserNotifications/UserNotifications.h>
#define IS_IOS10ORLATER ([[[UIDevice currentDevice] systemVersion] floatValue] >= 10)

typedef void (^CompletionHandleType)();

@interface AppDelegate ()<NSURLSessionDownloadDelegate>

@property (nonatomic,strong)NSMutableDictionary *completionHandleDictionary;
@property (nonatomic,strong)NSURLSessionDownloadTask *downloadTask;
@property (nonatomic,strong)NSURLSession *backgroundSession;
@property (nonatomic,strong)NSData *resumeData;

@property (nonatomic,strong)UILocalNotification *localNotification;
@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    self.backgroundSession = [self backgroundURLSession];
    
    if ([[UIDevice currentDevice].systemVersion floatValue] >= 10.0) {
        //ios10 特有
        UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
        //必须写代理，不然无法监听通知的接收与点击事件
        center.delegate = self;
        [center requestAuthorizationWithOptions:(UNAuthorizationOptionAlert | UNAuthorizationOptionBadge | UNAuthorizationOptionSound) completionHandler:^(BOOL granted, NSError * _Nullable error) {
            
            if (granted) {
                // 点击允许
                NSLog(@"注册成功");
                // 可以通过 getNotificationSettingsWithCompletionHandler 获取权限设置
                //之前注册推送服务，用户点击了同意还是不同意，以及用户之后又做了怎样的更改我们都无从得知，现在 apple 开放了这个 API，我们可以直接获取到用户的设定信息了。注意UNNotificationSettings是只读对象哦，不能直接修改！
                [center getNotificationSettingsWithCompletionHandler:^(UNNotificationSettings * _Nonnull settings) {
                    NSLog(@"settings = %@", settings);
                }];
            } else {
                // 点击不允许
                NSLog(@"注册失败");
            }
            
        }];
        
    }else if ([[UIDevice currentDevice].systemVersion floatValue] >8.0){
        //iOS8 - iOS10
        [application registerUserNotificationSettings:[UIUserNotificationSettings settingsForTypes:UIUserNotificationTypeAlert | UIUserNotificationTypeSound | UIUserNotificationTypeBadge categories:nil]];
        
    }else if ([[UIDevice currentDevice].systemVersion floatValue] < 8.0) {
        //iOS8系统以下
        [application registerForRemoteNotificationTypes:UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeAlert | UIRemoteNotificationTypeSound];
    }
    
    return YES;
}
// iOS 10收到通知
- (void)userNotificationCenter:(UNUserNotificationCenter *)center willPresentNotification:(UNNotification *)notification withCompletionHandler:(void (^)(UNNotificationPresentationOptions options))completionHandler{
    
    NSDictionary * userInfo = notification.request.content.userInfo;//收到用户的基本信息
    
    UNNotificationRequest *request = notification.request; // 收到推送的请求
    UNNotificationContent *content = request.content; // 收到推送的消息内容
    NSNumber *badge = content.badge;  // 推送消息的角标
    NSString *body = content.body;    // 推送消息体
    UNNotificationSound *sound = content.sound;  // 推送消息的声音
    NSString *subtitle = content.subtitle;  // 推送消息的副标题
    NSString *title = content.title;  // 推送消息的标题

    
    if([notification.request.trigger isKindOfClass:[UNPushNotificationTrigger class]]) {
        NSLog(@"iOS10 前台收到远程通知");
    }
    else {
        // 判断为本地通知
        NSLog(@"iOS10 前台收到本地通知:{\nbody:%@，\ntitle:%@,\nsubtitle:%@,\nbadge：%@，\nsound：%@，\nuserInfo：%@\n}",body,title,subtitle,badge,sound,userInfo);
    }
    completionHandler(UNNotificationPresentationOptionAlert); // 需要执行这个方法，选择是否提醒用户，有Badge、Sound、Alert三种类型可以设置
    
}
//发送通知
- (void)sendLocalNotification {
    //触发模式1（在2秒后提醒）
    UNTimeIntervalNotificationTrigger *trigger1 = [UNTimeIntervalNotificationTrigger triggerWithTimeInterval:2 repeats:NO];
    
    //创建本地通知
    UNMutableNotificationContent *content = [[UNMutableNotificationContent alloc]init];
    content.title = @"穷笑天的通知";
    content.body = @"下载完成了";
    content.badge = @1;
    NSError *error = nil;
        NSString *path = [[NSBundle mainBundle]pathForResource:@"1" ofType:@"png"];
    
    
    UNNotificationAttachment *att = [UNNotificationAttachment attachmentWithIdentifier:@"att1" URL:[NSURL fileURLWithPath:path] options:nil error:&error];
    if (error) {
        NSLog(@"attachment error %@",error);
    }
    content.attachments = @[att];
    content.launchImageName = @"1.png";
    
    //这里设置category1，是与之前设置的category对应
    content.categoryIdentifier = @"category1";
    //设置声音
    UNNotificationSound *sound = [UNNotificationSound defaultSound];
    content.sound = sound;
    
    NSString *requestidentifer = @"TestRequestww1";//创建通知标示
    UNNotificationRequest *request = [UNNotificationRequest requestWithIdentifier:requestidentifer content:content trigger:trigger1];
    //把通知加到UNUserNotificationCenter,到指定触发点会被触发
    [[UNUserNotificationCenter currentNotificationCenter]addNotificationRequest:request withCompletionHandler:^(NSError * _Nullable error) {
    }];
}
//handleEventsForBackgroundURLSession方法是在后台下载的所有任务完成后才会调用。如果当后台传输完成时，如果应用程序已经被杀掉，iOS将会在后台启动该应用程序，下载相关的委托方法会在 application:didFinishLaunchingWithOptions:方法被调用之后被调用。
- (void)application:(UIApplication *)application handleEventsForBackgroundURLSession:(NSString *)identifier completionHandler:(void (^)())completionHandler{
    //3.在appDelegate中实现handleEventsForBackgroundURLSession，要注意的是，需要在handleEventsForBackgroundURLSession中必须重新建立一个后台 session 的参照（可以用之前dispatch_once创建的对象），否则 NSURLSessionDownloadDelegate 和 NSURLSessionDelegate 方法会因为没有 对 session 的 delegate 设置而不会被调用。
    
    NSURLSession *backgroundSession = [self backgroundURLSession];
    NSLog(@"Rejoining session with identifier %@ %@", identifier, backgroundSession);

    //保存completion handler 以在处理session时间后更新
    [self addCompletionHandel:completionHandler forSession:identifier];
}
#pragma mark Save completionHandler
- (void)addCompletionHandel:(CompletionHandleType)handel forSession:(NSString *)identifier{
    if ([self.completionHandleDictionary objectForKey:identifier]) {
        NSLog(@"Error: Got multiple handlers for a single session identifier.  This should not happen.\n");
    }
    [self.completionHandleDictionary setObject:handel forKey:identifier];
}
- (void)callCompletionHandlerForSession:(NSString *)identifier{
    CompletionHandleType handle = [self.completionHandleDictionary objectForKey:identifier];
    if (handle) {
        [self.completionHandleDictionary removeObjectForKey:identifier];
        NSLog(@"Calling completion handler for session %@", identifier);
        handle();
    }
}

#pragma mark - backgroundURLSession
- (NSURLSession *)backgroundURLSession{
   // 1. 创建一个后台下载对象 用dispatch_once创建一个用于后台下载对象，目的是为了保证identifier的唯一，文档不建议对于相同的标识符 (identifier) 创建多个会话对象。这里创建并配置了NSURLSession，将通过backgroundSessionConfiguration其指定为后台session并设定delegate。
    static NSURLSession *session = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSString *identifier = @"com.yourcompany.appid.BackgroundSession";
        NSURLSessionConfiguration * sessionConfig = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:identifier];
        session = [NSURLSession sessionWithConfiguration:sessionConfig
                                                delegate:self
                                           delegateQueue:[NSOperationQueue mainQueue]];
    });
    return session;
}
#pragma mark - Public Mehtod
- (void)beginDownloadWithUrl:(NSString *)downloadURLString {
    //2.向其中加入对应的传输用的NSURLSessionTask，并调用resume启动下载。
    NSURL *downloadURL = [NSURL URLWithString:downloadURLString];
    NSURLRequest *request = [NSURLRequest requestWithURL:downloadURL];
    NSURLSession *session = [self backgroundURLSession];
    NSURLSessionDownloadTask *downloadTask = [session downloadTaskWithRequest:request];
    [downloadTask resume];//启动下载
}
//暂停下载
- (void)pauseDownload{
    __weak __typeof(self) wSelf = self;
    /* 对某一个NSURLSessionDownloadTask取消下载，取消后会回调给我们 resumeData，
    * resumeData包含了下载任务的一些状态，之后可以用户恢复下载
     - (void)cancelByProducingResumeData:(void (^)(NSData * resumeData))completionHandler;
    */
    [self.downloadTask cancelByProducingResumeData:^(NSData * _Nullable resumeData) {
         __strong __typeof(wSelf) sSelf = wSelf;
        sSelf.resumeData = resumeData;
    }];
}
//继续下载
- (void)continueDownload{
    if (self.resumeData) {
        if (IS_IOS10ORLATER) {
            self.downloadTask = [self.backgroundSession downloadTaskWithCorrectResumeData:self.resumeData];
        }else{
              self.downloadTask = [self.backgroundSession downloadTaskWithResumeData:self.resumeData];
        }
        [self.downloadTask resume];
        self.resumeData = nil;
    }
}
- (BOOL)isValideResumeData:(NSData *)resumeData
{
    if (!resumeData || resumeData.length == 0) {
        return NO;
    }
    return YES;
}
#pragma mark - NSURLSessionDownloadDelegate
/**
 任务下载完成，下载失败，或者是应用被杀掉后，中心启动应用并创建相关identifier的session时调用
 * 该方法下载成功和失败都会回调，只是失败的是error是有值的，
 * 在下载失败时，error的userinfo属性可以通过NSURLSessionDownloadTaskResumeData
 * 这个key来取到resumeData(和上面的resumeData是一样的)，再通过resumeData恢复下载
 */
- (void)URLSession:(NSURLSession *)session
              task:(NSURLSessionTask *)task
didCompleteWithError:(NSError *)error{
    if (error) {
        if ([error.userInfo objectForKey:NSURLSessionDownloadTaskResumeData]) {
            NSData *resumeData = [error.userInfo objectForKey:NSURLSessionDownloadTaskResumeData];
             //通过之前保存的resumeData，获取断点的NSURLSessionTask，调用resume恢复下载
            self.resumeData = resumeData;
        }
    }else{
//        [self sendlo]
        [self postDownloadProgressNotification:@"1"];
    }
}
/**
 应用在后台 而且后台所有下载任务完成后，
 在所有其他NSURLSession和NSURLSessionDownloadTask委托方法执行完后回调
 可以在该方法中做下载数据管理和UI刷新
 @param session <#session description#>
 */
-(void)URLSessionDidFinishEventsForBackgroundURLSession:(NSURLSession *)session{

//    4. 实现URLSessionDidFinishEventsForBackgroundURLSession，待所有数据处理完成，UI刷新之后在改方法中在调用之前保存的completionHandler()。
     NSLog(@"Background URL session %@ finished events.\n", session);
    if (session.configuration.identifier) {
        // 调用在 -application:handleEventsForBackgroundURLSession: 中保存的 handler
        [self callCompletionHandlerForSession:session.configuration.identifier];
    }
}


/**
 下载过程中调用，用于跟踪下载进度
 @param session                   <#session description#>
 @param downloadTask              <#downloadTask description#>
 @param bytesWritten              为单次下载大小
 @param totalBytesWritten         为当前一共下载大小
 @param totalBytesExpectedToWrite 为文件大小
 */
-(void)URLSession:(NSURLSession *)session
     downloadTask:(NSURLSessionDownloadTask *)downloadTask
     didWriteData:(int64_t)bytesWritten
totalBytesWritten:(int64_t)totalBytesWritten
totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite{
    NSLog(@"downloadTask:%lu percent:%.2f%%",(unsigned long)downloadTask.taskIdentifier,(CGFloat)totalBytesWritten / totalBytesExpectedToWrite * 100);
    NSString *strProgress = [NSString stringWithFormat:@"%.2f",(CGFloat)totalBytesWritten/totalBytesExpectedToWrite];
    [self postDownloadProgressNotification:strProgress];
}

/**
 下载恢复时调用
 在使用downloadTaskWithResumenData:方法获取到对应NSURLSessionDownloadTask,
 并该task调用resume的时候调用
 @param session            <#session description#>
 @param downloadTask       <#downloadTask description#>
 @param fileOffset         <#fileOffset description#>
 @param expectedTotalBytes <#expectedTotalBytes description#>
 */
-(void)URLSession:(NSURLSession *)session
     downloadTask:(NSURLSessionDownloadTask *)downloadTask
didResumeAtOffset:(int64_t)fileOffset
expectedTotalBytes:(int64_t)expectedTotalBytes{
     NSLog(@"fileOffset:%lld expectedTotalBytes:%lld",fileOffset,expectedTotalBytes);
}

/**
 下载完调用
 @param session      <#session description#>
 @param downloadTask <#downloadTask description#>
 @param location     <#location description#>
 */
- (void)URLSession:(NSURLSession *)session
      downloadTask:(NSURLSessionDownloadTask *)downloadTask
didFinishDownloadingToURL:(NSURL *)location{
    //注:在URLSession:downloadTask:didFinishDownloadingToURL方法中，location只是一个磁盘上该文件的临时 URL，只是一个临时文件，需要自己使用NSFileManager将文件写到应用的目录下（一般来说这种可以重复获得的内容应该放到cache目录下），因为当你从这个委托方法返回时，该文件将从临时存储中删除。
     NSLog(@"downloadTask:%lu didFinishDownloadingToURL:%@", (unsigned long)downloadTask.taskIdentifier, location);
    
    NSString *locationString = [location path];
    NSString *finalLocation = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)lastObject] stringByAppendingPathComponent:[NSString stringWithFormat:@"%lufile",(unsigned long)downloadTask.taskIdentifier]];
    NSError *error;
    [[NSFileManager defaultManager]moveItemAtPath:locationString toPath:finalLocation error:&error];

    // 用 NSFileManager 将文件复制到应用的存储中
    // ...
    
    // 通知 UI 刷新
}

//通知下载进度
- (void)postDownloadProgressNotification:(NSString *)strProgress{
    NSDictionary *userInfo = @{@"progress":strProgress};
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter]postNotificationName:kDownloadProgressNotification object:nil userInfo:userInfo];
    });
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
}


- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}


- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}


- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}


@end
