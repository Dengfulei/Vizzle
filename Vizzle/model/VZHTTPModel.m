//
//  VZHTTPModel.m
//  Vizzle
//
//  Created by Jayson Xu on 14-9-15.
//  Copyright (c) 2014年 VizLab. All rights reserved.
//

#import "VZHTTPModel.h"
#import "VZHTTPRequest.h"
#import "VZHTTPNetworkConfig.h"

@interface VZHTTPModel()<VZHTTPRequestDelegate>

@property(nonatomic,strong) id<VZHTTPRequestInterface> request;
@property(nonatomic,strong)NSMutableDictionary* requestParams;

@end

@implementation VZHTTPModel

////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - getters

- (NSMutableDictionary* )requestParams
{
    if (!_requestParams) {
        
        _requestParams =[ NSMutableDictionary new ];
    }
    return _requestParams;
}

////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - life cycle

- (void)dealloc {
    
    [self cancel];
    NSLog(@"[%@]--->dealloc", self.class);
}


////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - @override methods


- (void)load
{
    [super load];
    [self loadInternal];
}

- (void)cancel
{
    if (self.request)
    {
        [self.request cancel];
        self.request = nil;
    }
    [super cancel];
}

////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - public methods



////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - private methods

- (void)loadInternal {
    
    if (self.requestType == VZModelCustom)
    {
        NSString* clzName = [self customRequestClassName];
        
        if (clzName.length > 0) {
            self.request = [[NSClassFromString(clzName) alloc]init];
        }
        else
        {
            self.request = [[VZHTTPRequest alloc]init];
        }
    }
    else
    {
        self.request = [self createRequest];
    }
    
    
    //1, prepareRequest
    [self prepareRequest];
    
    
    //2, set delegate
    self.request.delegate    = self;
    
    //3, init request
    [self.request initWithBaseURL:[self methodName]
                    RequestConfig:[self requestConfig]
                   ResponseConfig:[self responseConfig]];
    
    
    //4, add request data
    [self.request addHeaderParams:[self headerParams]];
    [self.request addQueries:[self dataParams]];
    self.request.cachedKey = [self cacheKey];
    
    //5, load data
    [self.request load];
}

////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - subclassing methods

- (NSDictionary *)dataParams {
    
    return self.requestParams;
}

- (NSDictionary* )headerParams{
    return nil;
}

- (NSString *)methodName {
    return nil;
}

- (BOOL)parseResponse:(id)JSON{
    
    return YES;
}

- (VZHTTPRequestConfig)requestConfig
{
    return vz_defaultHTTPRequestConfig();
}

- (VZHTTPResponseConfig)responseConfig
{
    return vz_defaultHTTPResponseConfig();
}

- (NSString* )customRequestClassName
{
    return @"VZHTTPRequest";
}

- (NSString* )cacheKey
{
    NSString* method = [self methodName];
    NSMutableArray* list = [NSMutableArray new];
    [self.dataParams enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
       
        NSString* str = [NSString stringWithFormat:@"%@:%@",key,obj];
        [list addObject:str];
    }];
    
    NSString* cachedKey  = method;
    for (NSString* key in list) {
        [cachedKey stringByAppendingString:key];
    }
    return cachedKey;
}



////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - subclassing hooks

- (id<VZHTTPRequestInterface>)createRequest
{
    return [VZHTTPRequest new];
}


- (void)prepareRequest
{
    
}


////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - request callback


- (void)requestDidStart:(id<VZHTTPRequestInterface>)request
{
    NSLog(@"[%@]-->REQUEST_START:%@",self.class,request.requestURL);
    
    [self didStartLoading];
}


- (void)request:(id<VZHTTPRequestInterface>) request DidFinish:(id)JSON
{
    _responseString = request.responseString;
    _responseObject = request.responseObject;
    _isResponseObjectFromCache = request.isCachedResponse;
    
    NSLog(@"[%@]-->REQUEST_FINISH:%@",self.class,JSON);

    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
       
        if ([self parseResponse:JSON]) {
        
            dispatch_async(dispatch_get_main_queue(), ^{
                [self didFinishLoading];
            });
        
        }
        else
        {
            NSError* err = [NSError errorWithDomain:VZHTTPErrorDomain code:kVZHTTPParseResponseError userInfo:@{NSLocalizedDescriptionKey:@"Parse Response Error"}];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [self didFailWithError:err];

            });
        }
    });
}
- (void)request:(id<VZHTTPRequestInterface>) request DidFailWithError:(NSError *)error
{
    NSLog(@"[%@]-->REQUEST_FAILED:%@",self.class,error);
    
    
    _responseString = request.responseString;
    _responseObject = request.responseObject;

    [self didFailWithError:error];
}




@end
