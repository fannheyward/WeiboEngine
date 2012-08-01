//
//  WBEngine.m
//  AppRankHD
//
//  Created by Heyward Fann on 12-5-9.
//  Copyright (c) 2012年 Appwill Inc. All rights reserved.
//

#import "WBEngine.h"

#import "WBAuthorizeView.h"
#import "WBSDKGlobal.h"
#import "WBRequest.h"
#import "SSKeychain.h"

#define kWBKeychainServiceName          @"WeiboApp"
#define kWBKeychainUserID               @"WeiboUserID"
#define kWBKeychainAccessToken          @"WeiboAccessToken"
#define kWBKeychainExpireTime           @"WeiboExpireTime"

#define kWBRequestStringBoundary        @"293iosfksdfkiowjksdf31jsiuwq003s02dsaffafass3qw"

#error Set weibo app key, secret&redirectURL.
#define kWeiboAppKey        @""
#define kWeiboAppSecret     @""
#define kWeiboRedirectURL   @""

@interface WBEngine () <WBAuthorizeDelegate, WBRequestDelegate>

@property (strong, nonatomic) NSString *appKey;
@property (strong, nonatomic) NSString *appSecret;
@property (strong, nonatomic) NSString *userID;
@property (strong, nonatomic) NSString *accessToken;
@property (strong, nonatomic) NSString *redirectURI;
@property (strong, nonatomic) WBRequest *request;
@property (strong, nonatomic) WBAuthorizeView *authView;
@property (nonatomic) NSTimeInterval expireTime;

@end

@implementation WBEngine

@synthesize appKey, appSecret, userID, accessToken, redirectURI;
@synthesize request = _request;
@synthesize authView = _authView;
@synthesize delegate;
@synthesize expireTime;

+ (WBEngine *)sharedWBEngine
{
    static WBEngine *sharedWBEngine;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedWBEngine = [[WBEngine alloc] init];
    });

    return sharedWBEngine;
}

- (id)init
{
    self = [super init];
    if (self) {
        self.appKey = kWeiboAppKey;
        self.appSecret = kWeiboAppSecret;
        self.redirectURI = kWeiboRedirectURL;

        [self readAuthorizeDataFromKeychain];
    }

    return self;
}

#pragma mark - Public Methods
#pragma mark - Authorization
- (void)logIn
{
    self.authView = [[WBAuthorizeView alloc] initWithAppKey:appKey
                                                     secret:appSecret
                                                redirectURI:redirectURI];
    _authView.delegate = self;
    [_authView startAuthorize];
}

- (void)logOut
{
    [self deleteAuthorizeDataInKeychain];
}

- (void)resignOAuth
{
    _authView.delegate = nil;
    [_authView hide];
}

- (BOOL)isLoggedIn
{
    return userID && accessToken && ![self isAuthorizeExpired];
}

- (BOOL)isAuthorizeExpired
{
    if ([[NSDate date] timeIntervalSince1970] > expireTime) {
        [self deleteAuthorizeDataInKeychain];
        return YES;
    }
    return NO;
}

#pragma mark - Private Methods
#pragma mark - Keychain Methods
- (NSString *)serviceName
{
    return [NSString stringWithFormat:@"%@_%@", kWBKeychainServiceName, appKey];
}

- (void)saveAuthorizeDataFromKeychain
{
    [SSKeychain setPassword:userID
                 forService:[self serviceName]
                    account:kWBKeychainUserID];
    [SSKeychain setPassword:accessToken
                 forService:[self serviceName]
                    account:kWBKeychainAccessToken];
    [SSKeychain setPassword:[NSString stringWithFormat:@"%lf", expireTime]
                 forService:[self serviceName]
                    account:kWBKeychainExpireTime];
}

- (void)readAuthorizeDataFromKeychain
{
    self.userID = [SSKeychain passwordForService:[self serviceName]
                                         account:kWBKeychainUserID];
    self.accessToken = [SSKeychain passwordForService:[self serviceName]
                                              account:kWBKeychainAccessToken];
    self.expireTime = [[SSKeychain passwordForService:[self serviceName]
                                              account:kWBKeychainExpireTime] doubleValue];
}

- (void)deleteAuthorizeDataInKeychain
{
    self.userID = nil;
    self.accessToken = nil;
    self.expireTime = 0;

    [SSKeychain deletePasswordForService:[self serviceName]
                                 account:kWBKeychainUserID];
    [SSKeychain deletePasswordForService:[self serviceName]
                                 account:kWBKeychainAccessToken];
    [SSKeychain deletePasswordForService:[self serviceName]
                                 account:kWBKeychainExpireTime];
}

#pragma mark - Request Methods
- (void)requestWithURL:(NSString *)url
            httpMethod:(NSString *)method
                params:(NSDictionary *)params
              postType:(WBRequestPostDataType)postType
           requestType:(WBRequestType)requestType
{
    [_request disconnect];

    NSString *newURL = [NSString stringWithFormat:@"%@%@", kWBSDKAPIDomain, url];
    self.request = [WBRequest requestWithAccessToken:accessToken
                                                 url:newURL
                                          httpMethod:method
                                              params:params
                                        postDataType:postType
                                         requestType:requestType
                                    httpHeaderFields:nil
                                            delegate:self];
    [_request connect];
}

- (void)sendWeiboWithText:(NSString *)text image:(UIImage *)image
{
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    [params setObject:(text ? text : @"") forKey:@"status"];
    
    if (image && [image isKindOfClass:[UIImage class]]) {
        [params setObject:image forKey:@"pic"];

        [self requestWithURL:@"statuses/upload.json"
                  httpMethod:@"POST"
                      params:params
                    postType:kWBRequestPostDataTypeMultipart
                 requestType:WBRequestTypeStatusesUpload];
    } else {
        [self requestWithURL:@"statuses/update.json"
                  httpMethod:@"POST"
                      params:params
                    postType:kWBRequestPostDataTypeNormal
                 requestType:WBRequestTypeStatusesUpdate];
    }
}

- (void)loggedInUserInfo
{
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    [params setObject:userID forKey:@"uid"];
    [self requestWithURL:@"users/show.json"
              httpMethod:@"GET"
                  params:params
                postType:kWBRequestPostDataTypeNormal
             requestType:WBRequestTypeUsersShow];
}

- (void)followByUserName:(NSString *)name
{
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    [params setObject:name forKey:@"screen_name"];
    [self requestWithURL:@"friendships/create.json"
              httpMethod:@"POST"
                  params:params
                postType:kWBRequestPostDataTypeNormal
             requestType:WBRequestTypeFriendshipsCreate];
}

- (void)followByUserID:(long long)uid
{
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    [params setObject:[NSString stringWithFormat:@"%lld", uid] forKey:@"uid"];
    [self requestWithURL:@"friendships/create.json"
              httpMethod:@"POST"
                  params:params
                postType:kWBRequestPostDataTypeNormal
             requestType:WBRequestTypeFriendshipsCreate];
}

- (void)bilateralFriendsList
{
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    [params setObject:userID forKey:@"uid"];
    [params setObject:[NSNumber numberWithInt:200] forKey:@"count"];
    [self requestWithURL:@"friendships/friends/bilateral.json"
              httpMethod:@"GET"
                  params:params
                postType:kWBRequestPostDataTypeNormal
             requestType:WBRequestTypeFriendshipsFriendsBilateral];
}

- (void)followedFriendsListFromCursor:(NSInteger)cursor
{
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    [params setObject:userID forKey:@"uid"];
    [params setObject:@"200" forKey:@"count"];
    if (cursor != 0) {
        [params setObject:[NSString stringWithFormat:@"%d", cursor] forKey:@"cursor"];
    }
    [self requestWithURL:@"friendships/friends.json"
              httpMethod:@"GET"
                  params:params
                postType:kWBRequestPostDataTypeNormal
             requestType:WBRequestTypeFriendshipsFriends];
}

- (void)checkFriendShipWithUID:(NSString *)target_id
{
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    [params setObject:userID forKey:@"source_id"];
    [params setObject:target_id forKey:@"target_id"];
    [self requestWithURL:@"friendships/show.json"
              httpMethod:@"GET"
                  params:params
                postType:kWBRequestPostDataTypeNormal
             requestType:WBRequestTypeFriendshipsShow];
}

#pragma mark - WBAuthorizeDelegate
- (void)authorizeDidFailedWithError:(NSError *)error
{
    if (delegate && [delegate respondsToSelector:@selector(engineDidFailLogInWithError:)]) {
        [delegate engineDidFailLogInWithError:error];
    }
}

- (void)authorizeDidSucceedWithToken:(NSString *)token
                              userID:(NSString *)uid
                           expiresIn:(NSInteger)seconds
{
    self.accessToken = token;
    self.userID = uid;
    self.expireTime = [[NSDate date] timeIntervalSince1970]+seconds;

    [self saveAuthorizeDataFromKeychain];

    if (delegate && [delegate respondsToSelector:@selector(engineDidLogIn)]) {
        [delegate engineDidLogIn];
    }
}

#pragma mark - WBRequestDelegate
- (void)request:(WBRequest *)request didFailWithError:(NSError *)error
{
    if (delegate && [delegate respondsToSelector:@selector(engineRequest:didFailWithError:)]) {
        [delegate engineRequest:request.requestType didFailWithError:error];
    }
}

- (void)request:(WBRequest *)request didFinishLoadingWithResult:(id)result
{
    if (delegate && [delegate respondsToSelector:@selector(engineRequest:didSucceedWithResult:)]) {
        [delegate engineRequest:request.requestType didSucceedWithResult:result];
    }
}

@end
