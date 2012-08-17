//
//  WBKHTTPClient.h
//  ShareKit
//
//  Created by Heyward Fann on 12-8-16.
//  Copyright (c) 2012年 Heyward Fann. All rights reserved.
//

#import "AFHTTPClient.h"

typedef void(^SuccessBlock)(NSDictionary *dict);
typedef void(^FailureBlock)(NSError *error);

@interface WBKHTTPClient : AFHTTPClient

+ (WBKHTTPClient *)sharedClient;

- (BOOL)isLoggedIn;
- (void)loginSuccess:(void (^)())success failure:(void (^)(NSError *error))failure;
- (void)logout;

#pragma mark - weibo request
- (void)getLoggedInUserInfoSuccess:(SuccessBlock)success
                           failure:(FailureBlock)failure;

- (void)updateStatus:(NSString *)text
         withSuccess:(SuccessBlock)success
             failure:(FailureBlock)failure;

- (void)updateStatus:(NSString *)text
               image:(UIImage *)img
         withSuccess:(SuccessBlock)success
             failure:(FailureBlock)failure;

- (void)getHomeTimelineWithSuccess:(void (^)(NSArray *statuses))success
                           failure:(FailureBlock)failure;

@end
