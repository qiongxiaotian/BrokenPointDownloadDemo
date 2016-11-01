//
//  ViewController.m
//  BrokenPointDownloadDemo
//
//  Created by mac on 2016/10/26.
//  Copyright © 2016年 LookTour. All rights reserved.
//

#import "ViewController.h"
#import "AppDelegate.h"
@interface ViewController ()
@property (weak, nonatomic) IBOutlet UILabel *progressLabel;
@property (weak, nonatomic) IBOutlet UIProgressView *downloadProgress;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(updateDownloadProgress:) name:kDownloadProgressNotification object:nil];
}
- (void)updateDownloadProgress:(NSNotification *)notification{
    NSDictionary *userInfo = notification.userInfo;
    CGFloat fProgress = [userInfo[@"progress"]floatValue];
    self.progressLabel.text = [NSString stringWithFormat:@"%2.f%%",fProgress * 100];
    self.downloadProgress.progress = fProgress;
}
- (IBAction)download:(id)sender {
    AppDelegate *delegate = [[UIApplication sharedApplication]delegate];
    [delegate beginDownloadWithUrl:@"http://sw.bos.baidu.com/sw-search-sp/software/797b4439e2551/QQ_mac_5.0.2.dmg"];
}
- (IBAction)pauseDownload:(id)sender {
    AppDelegate *delegate = [[UIApplication sharedApplication] delegate];
    [delegate pauseDownload];
}
- (IBAction)continueDownload:(id)sender {
    AppDelegate *delegate = [[UIApplication sharedApplication] delegate];
    [delegate continueDownload];
}

- (void)dealloc{
    [[NSNotificationCenter defaultCenter]removeObserver:self];
}
@end
