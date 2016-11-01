//
//  NSURLSession+CorrectedResumeData.h
//  BrokenPointDownloadDemo
//
//  Created by mac on 2016/10/26.
//  Copyright © 2016年 LookTour. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSURLSession (CorrectedResumeData)
- (NSURLSessionDownloadTask *)downloadTaskWithCorrectResumeData:(NSData *)resumeData;
@end
