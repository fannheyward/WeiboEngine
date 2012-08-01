//
//  WBAuthorizeView.m
//  AppRankHD
//
//  Created by Heyward Fann on 12-6-27.
//  Copyright (c) 2012年 Appwill Inc. All rights reserved.
//

#import "WBAuthorizeView.h"

#import "WBSDKGlobal.h"

#import <QuartzCore/QuartzCore.h>

#define kViewWidthIPhone    280
#define kViewHeightIPhone   420
#define kViewWidthIPad      480
#define kViewHeightIPad     640

#define kWBAuthorizeURL     @"https://api.weibo.com/oauth2/authorize"

@interface WBAuthorizeView () <UIWebViewDelegate>

@property (strong, nonatomic) UIView *panelView;
@property (strong, nonatomic) UIView *containerView;
@property (strong, nonatomic) UIActivityIndicatorView *indicatorView;
@property (strong, nonatomic) UIWebView *mainWebView;
@property (nonatomic) UIInterfaceOrientation previousOrientation;

@property (strong, nonatomic) NSString *appKey;
@property (strong, nonatomic) NSString *appSecret;
@property (strong, nonatomic) NSString *redirectURI;

@end

@implementation WBAuthorizeView

@synthesize panelView = _panelView;
@synthesize containerView = _containerView;
@synthesize mainWebView = _mainWebView;
@synthesize indicatorView = _indicatorView;
@synthesize previousOrientation = _previousOrientation;
@synthesize appKey = _appKey;
@synthesize appSecret = _appSecret;
@synthesize redirectURI = _redirectURI;
@synthesize delegate = _delegate;

- (CGFloat)viewWidth
{
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        return kViewWidthIPhone;
    } else {
        return kViewWidthIPad;
    }
}

- (CGFloat)viewHeight
{
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        return kViewHeightIPhone;
    } else {
        return kViewHeightIPad;
    }
}

- (id)initWithAppKey:(NSString *)key secret:(NSString *)secret redirectURI:(NSString *)uri
{
    self = [super init];
    if (self) {
        self.appKey = key;
        self.appSecret = secret;
        self.redirectURI = uri;

        self.backgroundColor = [UIColor clearColor];
        self.frame = CGRectMake(0, 0, [self viewWidth], [self viewHeight]);
        self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        
        CGRect rect = CGRectMake(0, 0, [self viewWidth], [self viewHeight]);
        self.panelView = [[UIView alloc] initWithFrame:rect];
        _panelView.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.55];
        _panelView.layer.masksToBounds = YES;
        _panelView.layer.cornerRadius = 10.0f;
        [self addSubview:_panelView];
        
        rect = CGRectMake(10, 10, _panelView.bounds.size.width-20,
                          _panelView.bounds.size.height-20);
        self.containerView = [[UIView alloc] initWithFrame:rect];
        _containerView.layer.borderColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.7f].CGColor;
        _containerView.layer.borderWidth = 1.0f;
        [_panelView addSubview:_containerView];
        
        self.mainWebView = [[UIWebView alloc] initWithFrame:_containerView.bounds];
        _mainWebView.delegate = self;
        [_containerView addSubview:_mainWebView];
        
        self.indicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        _indicatorView.hidesWhenStopped = YES;
        _indicatorView.center = self.center;
        [self addSubview:_indicatorView];
    }

    return self;
}

#pragma mark - Orientations
- (UIInterfaceOrientation)currentOrientation
{
    return [[UIApplication sharedApplication] statusBarOrientation];
}

- (void)sizeToFitOrientation:(UIInterfaceOrientation)orientation
{
    [self setTransform:CGAffineTransformIdentity];
    
    if (UIInterfaceOrientationIsLandscape(orientation))
    {
        self.frame = CGRectMake(0, 0, [self viewHeight], [self viewWidth]);
    } else {
        self.frame = CGRectMake(0, 0, [self viewWidth], [self viewHeight]);
    }
    
    _panelView.frame = CGRectMake(0, 0, self.bounds.size.width,
                                  self.bounds.size.height);
    _containerView.frame = CGRectMake(10, 10, _panelView.bounds.size.width-20,
                                      _panelView.bounds.size.height-20);
    _mainWebView.frame = _containerView.bounds;
    _indicatorView.center = self.center;
    
    self.center = CGPointMake([UIScreen mainScreen].bounds.size.width/2,
                              [UIScreen mainScreen].bounds.size.height/2+20);
    
    [self setTransform:[self transformForOrientation:orientation]];
    
    self.previousOrientation = orientation;
}

- (CGAffineTransform)transformForOrientation:(UIInterfaceOrientation)orientation
{
    if (orientation == UIInterfaceOrientationLandscapeLeft)
    {
		return CGAffineTransformMakeRotation(-M_PI / 2);
	}
    else if (orientation == UIInterfaceOrientationLandscapeRight)
    {
		return CGAffineTransformMakeRotation(M_PI / 2);
	}
    else if (orientation == UIInterfaceOrientationPortraitUpsideDown)
    {
		return CGAffineTransformMakeRotation(-M_PI);
	}
    else
    {
		return CGAffineTransformIdentity;
	}
}

- (BOOL)shouldRotateToOrientation:(UIInterfaceOrientation)orientation
{
    if (orientation == _previousOrientation) {
        return NO;
    } else {
        return orientation == UIInterfaceOrientationLandscapeLeft
        || orientation == UIInterfaceOrientationLandscapeRight
		|| orientation == UIInterfaceOrientationPortrait
		|| orientation == UIInterfaceOrientationPortraitUpsideDown;
    }
}

#pragma mark - Obeservers
- (void)deviceOrientationDidChange
{
    UIInterfaceOrientation orientation = [self currentOrientation];
    if ([self shouldRotateToOrientation:orientation]) {
        NSTimeInterval duration = [UIApplication sharedApplication].statusBarOrientationAnimationDuration;
        
        [UIView beginAnimations:nil context:nil];
        [UIView setAnimationDuration:duration];
        [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
        [self sizeToFitOrientation:orientation];
        [UIView commitAnimations];
    }
}

- (void)addObservers
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(deviceOrientationDidChange)
                                                 name:UIDeviceOrientationDidChangeNotification
                                               object:nil];
}

- (void)removeObservers
{
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIDeviceOrientationDidChangeNotification
                                                  object:nil];
}

#pragma mark - Animations
- (void)bounceOutAnimationStopped
{
    [UIView beginAnimations:nil context:nil];
	[UIView setAnimationDuration:0.13];
	[UIView setAnimationDelegate:self];
	[UIView setAnimationDidStopSelector:@selector(bounceInAnimationStopped)];
    [_panelView setAlpha:0.8];
	[_panelView setTransform:CGAffineTransformScale(CGAffineTransformIdentity, 0.9, 0.9)];
	[UIView commitAnimations];
}

- (void)bounceInAnimationStopped
{
    [UIView beginAnimations:nil context:nil];
	[UIView setAnimationDuration:0.13];
    [_panelView setAlpha:1.0];
	[_panelView setTransform:CGAffineTransformScale(CGAffineTransformIdentity, 1.0, 1.0)];
	[UIView commitAnimations];
}

#pragma mark - Dismiss
- (void)hideAndCleanUp
{
    self.delegate = nil;
    [_mainWebView stopLoading];
    _mainWebView.delegate = nil;

    [self removeObservers];
    [self removeFromSuperview];
}

- (void)show
{
    [self sizeToFitOrientation:[self currentOrientation]];
    
    UIWindow *window = [[UIApplication sharedApplication] keyWindow];
    if (window == nil) {
        window = [[UIApplication sharedApplication].windows objectAtIndex:0];
    }
    [window addSubview:self];
    self.center = CGPointMake([UIScreen mainScreen].bounds.size.width/2,
                              [UIScreen mainScreen].bounds.size.height/2+20);
    
    [_panelView setAlpha:0];
    CGAffineTransform transform = CGAffineTransformIdentity;
    [_panelView setTransform:CGAffineTransformScale(transform, 0.3, 0.3)];
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:0.2];
    [UIView setAnimationDelegate:self];
    [UIView setAnimationDidStopSelector:@selector(bounceOutAnimationStopped)];
    [_panelView setAlpha:0.5];
    [_panelView setTransform:CGAffineTransformScale(transform, 1.1, 1.1)];
    [UIView commitAnimations];
    
    [self addObservers];
}

- (void)hide
{
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:0.3];
    [UIView setAnimationDelegate:self];
    [UIView setAnimationDidStopSelector:@selector(hideAndCleanUp)];
    [self setAlpha:0];
    [UIView commitAnimations];
}

#pragma mark - startAuthorize
- (NSString *)stringByAddPercentEscapes:(NSString *)str
{
    
    CFStringRef buffer =
    CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault,
                                            (__bridge CFStringRef)str,
                                            NULL,
                                            (__bridge CFStringRef)@";/?:@&=+$,",
                                            kCFStringEncodingUTF8);
    
    NSString *result = [NSString stringWithString:(__bridge NSString *)buffer];
    
    CFRelease(buffer);
    
    return result;
}

- (NSString*)stringByAddQueryDict:(NSDictionary*)query toStr:(NSString *)str
{
    NSMutableArray* pairs = [NSMutableArray array];
    for (NSString* key in [query keyEnumerator]) {
        NSString* value = [self stringByAddPercentEscapes:[query objectForKey:key]];
        NSString* pair = [NSString stringWithFormat:@"%@=%@", key, value];
        [pairs addObject:pair];
    }
    
    NSString* params = [pairs componentsJoinedByString:@"&"];
    if ([str rangeOfString:@"?"].location == NSNotFound) {
        return [str stringByAppendingFormat:@"?%@", params];
        
    } else {
        return [str stringByAppendingFormat:@"&%@", params];
    }
}

- (void)startAuthorize
{
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithCapacity:4];
    [params setObject:_appKey forKey:@"client_id"];
    [params setObject:@"token" forKey:@"response_type"];
    [params setObject:_redirectURI forKey:@"redirect_uri"];
    [params setObject:@"mobile" forKey:@"display"];

    NSString *url = [self stringByAddQueryDict:params toStr:kWBAuthorizeURL];
    [_mainWebView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:url]]];
    [self show];
}

#pragma mark - didSucceedAuthorizeWithToken
- (NSDictionary*)queryContentStr:(NSString *)str
{
    NSCharacterSet* delimiterSet = [NSCharacterSet characterSetWithCharactersInString:@"&;"];
    NSMutableDictionary* pairs = [NSMutableDictionary dictionary];
    NSScanner* scanner = [[NSScanner alloc] initWithString:str];
    while (![scanner isAtEnd]) {
        NSString* pairString = nil;
        [scanner scanUpToCharactersFromSet:delimiterSet intoString:&pairString];
        [scanner scanCharactersFromSet:delimiterSet intoString:NULL];
        NSArray* kvPair = [pairString componentsSeparatedByString:@"="];
        if (kvPair.count == 1 || kvPair.count == 2) {
            NSString* key = [[kvPair objectAtIndex:0]
                             stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
            NSMutableArray* values = [pairs objectForKey:key];
            if (nil == values) {
                values = [NSMutableArray array];
                [pairs setObject:values forKey:key];
            }
            if (kvPair.count == 1) {
                [values addObject:[NSNull null]];
                
            } else if (kvPair.count == 2) {
                NSString* value = [[kvPair objectAtIndex:1]
                                   stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
                [values addObject:value];
            }
        }
    }
    return [NSDictionary dictionaryWithDictionary:pairs];
}
- (void)didSucceedAuthorizeWithStr:(NSString *)str
{
    if ([str length] < [_redirectURI length]+2) {
        if (_delegate && [_delegate respondsToSelector:@selector(authorizeDidFailedWithError:)]) {
            [_delegate authorizeDidFailedWithError:nil];
        }
        [self hide];
        return;
    }

    NSDictionary *dict = [self queryContentStr:[str substringFromIndex:[_redirectURI length]+2]];
    DLog(@"auth dict:%@", [dict description]);
    if (_delegate && [_delegate respondsToSelector:@selector(authorizeDidSucceedWithToken:userID:expiresIn:)]) {
        NSString *token = [[dict objectForKey:@"access_token"] objectAtIndex:0];
        NSString *uid = [[dict objectForKey:@"uid"] objectAtIndex:0];
        NSInteger seconds = [[[dict objectForKey:@"expires_in"] objectAtIndex:0] integerValue];
        [_delegate authorizeDidSucceedWithToken:token
                                         userID:uid
                                      expiresIn:seconds];
    }

    [self hide];
}

- (void)cancelOAuth
{
    if (_delegate && [_delegate respondsToSelector:@selector(authorizeDidFailedWithError:)]) {
        NSDictionary *dict = [NSDictionary dictionaryWithObject:@"User Cancel OAuth"
                                                         forKey:kWBSDKErrorCodeKey];
        NSError *error = [NSError errorWithDomain:kWBSDKErrorDomain
                                             code:kWBSDKErrorCodeAuthorizeError
                                         userInfo:dict];
        [_delegate authorizeDidFailedWithError:error];
    }
    [self hide];
}

#pragma mark - UIWebViewDelegate
- (void)webViewDidStartLoad:(UIWebView *)webView
{
    [_indicatorView startAnimating];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    [_indicatorView stopAnimating];
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    [_indicatorView stopAnimating];
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    NSRange range = [request.URL.absoluteString rangeOfString:@"access_token="];
    if (range.location != NSNotFound) {
        DLog(@"request.URL.absoluteString: %@", [request.URL.absoluteString description]);
        [self didSucceedAuthorizeWithStr:request.URL.absoluteString];

        return NO;
    }
    range = [request.URL.absoluteString rangeOfString:@"error_code=21330"];
    if (range.location != NSNotFound) {
        [self cancelOAuth];
        return NO;
    }
    
    return YES;
}

@end
