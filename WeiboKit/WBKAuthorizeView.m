//
//  WBKAuthorizeView.m
//  ShareKit
//
//  Created by Heyward Fann on 12-8-16.
//  Copyright (c) 2012年 Heyward Fann. All rights reserved.
//

#import "WBKAuthorizeView.h"

#import <QuartzCore/QuartzCore.h>

#define kViewWidthIPhone    280
#define kViewHeightIPhone   420
#define kViewWidthIPad      480
#define kViewHeightIPad     640

#define kWBAuthorizeURL     @"https://api.weibo.com/oauth2/authorize?client_id=%@&redirect_uri=%@&display=mobile&response_type=token"

@interface WBKAuthorizeView () <UIWebViewDelegate>

@property (strong, nonatomic) UIView *panelView;
@property (strong, nonatomic) UIView *containerView;
@property (strong, nonatomic) UIActivityIndicatorView *indicatorView;
@property (strong, nonatomic) UIWebView *mainWebView;

@property (nonatomic) UIInterfaceOrientation previousOrientation;

@property (nonatomic, copy) AuthorizeSuccess authSuccess;
@property (nonatomic, copy) AuthorizeFailure authFailure;

@property (nonatomic, copy) NSString *redirectURI;

@end

@implementation WBKAuthorizeView

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

- (id)init
{
    self = [super init];
    if (self) {
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

#pragma mark - 
- (void)authorizeWithAppKey:(NSString *)key
                     secret:(NSString *)secret
                redirectURI:(NSString *)uri
                    success:(AuthorizeSuccess)sucess
                    failure:(AuthorizeFailure)failure
{
    self.redirectURI = uri;
    self.authSuccess = sucess;
    self.authFailure = failure;

    NSString *url = [NSString stringWithFormat:kWBAuthorizeURL, key, uri];
    [_mainWebView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:url]]];
    [self show];
}

- (void)cancelAuthorize
{
    if (_authFailure) {
        NSDictionary *dict = [NSDictionary dictionaryWithObject:@"User Cancel OAuth"
                                                         forKey:@"ErrorKey"];
        NSError *error = [NSError errorWithDomain:@"ErrorDomain"
                                             code:0
                                         userInfo:dict];
        _authFailure(error);
    }

    [self hide];
}

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
    [self hide];

    if (str.length < _redirectURI.length+2) {
        if (_authFailure) {
            _authFailure(nil);
        }
        return;
    }

    NSDictionary *dict = [self queryContentStr:[str substringFromIndex:_redirectURI.length+2]];
    NSString *token = [[dict objectForKey:@"access_token"] objectAtIndex:0];
    NSString *uid = [[dict objectForKey:@"uid"] objectAtIndex:0];
    NSInteger seconds = [[[dict objectForKey:@"expires_in"] objectAtIndex:0] integerValue];
    if (_authSuccess) {
        _authSuccess(token, uid, seconds);
    }
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
        [self cancelAuthorize];
        return NO;
    }
    
    return YES;
}

@end
