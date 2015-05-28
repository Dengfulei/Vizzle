//
//  VZHTTPRequestGenerator.m
//  ETLibSDK
//
//  Created by moxin.xt on 12-12-18.
//  Copyright (c) 2013年 VizLab. All rights reserved.
//

#import "VZHTTPRequestGenerator.h"
#import "NSString+VZHTTPNetworkUtil.h"
#import "VZHTTPNetworkAssert.h"


@interface VZHTTPRequestQueryStringPair : NSObject

@property (readwrite, nonatomic, strong) id field;
@property (readwrite, nonatomic, strong) id value;

- (id)initWithField:(id)field value:(id)value;

- (NSString *)encodedStringValueWithEncoding:(NSStringEncoding)stringEncoding;

@end

@implementation VZHTTPRequestQueryStringPair

- (id)initWithField:(id)field value:(id)value {
    self = [super init];
    if (!self) {
        return nil;
    }
    
    self.field = field;
    self.value = value;
    
    return self;
}

- (NSString *)encodedStringValueWithEncoding:(NSStringEncoding)stringEncoding {
   
    if (!self.value || [self.value isEqual:[NSNull null]])
    {
        NSString* ret = [[self.field description] VZHTTP_escapedQueryStringKeyFromStringWithEncoding:stringEncoding];
        return ret;
    }
    else
    {
        NSString* k = [[self.field description] VZHTTP_escapedQueryStringKeyFromStringWithEncoding:stringEncoding];
        NSString* v = [[self.value description] VZHTTP_escapedQueryStringValueFromStringWithEncoding:stringEncoding];
        
        return [NSString stringWithFormat:@"%@=%@",k,v];
    }
}


@end

@interface VZHTTPRequestGenerator()

@property (readwrite, nonatomic, strong) NSMutableDictionary *requestHeaders;
@property (nonatomic,strong) NSSet* needEncodingMethods;

@end


@implementation VZHTTPRequestGenerator


///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - life cycle

+(instancetype) generator
{
    return [[self class] new];
}

- (instancetype)init
{
    self = [super  init];

    if (self) {
        
        _stringEncoding = NSUTF8StringEncoding;
        _requestHeaders = [NSMutableDictionary new];
        _needEncodingMethods = [NSSet setWithObjects:@"GET",@"HEAD",@"DELETE", nil];
        
        //set default header value
        [self setDefaultValueForHTTPHeaderField];
        
    }
    return self;
}

///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - set header field

- (void)setDefaultValueForHTTPHeaderField
{
    /**
     *  Accept-Language:
     *  http://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html#sec14.4
     */
    NSMutableArray *acceptLanguagesComponents = [NSMutableArray array];
    [[NSLocale preferredLanguages] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        float q = 1.0f - (idx * 0.1f);
        [acceptLanguagesComponents addObject:[NSString stringWithFormat:@"%@;q=%0.1g", obj, q]];
        *stop = q <= 0.5f;
    }];
    //add to header
    [self setValue:[acceptLanguagesComponents componentsJoinedByString:@","] forHTTPHederField:@"Accept-Language"];
    
    /**
     * User-Agent
     * http://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html#sec14.43
     *
     */
    NSString* userAgent = [NSString stringWithFormat:@"%@/%@ (%@; iOS %@; Scale/%0.2f)", [[[NSBundle mainBundle] infoDictionary] objectForKey:(__bridge NSString *)kCFBundleExecutableKey] ?: [[[NSBundle mainBundle] infoDictionary] objectForKey:(__bridge NSString *)kCFBundleIdentifierKey], (__bridge id)CFBundleGetValueForInfoDictionaryKey(CFBundleGetMainBundle(), kCFBundleVersionKey) ?: [[[NSBundle mainBundle] infoDictionary] objectForKey:(__bridge NSString *)kCFBundleVersionKey], [[UIDevice currentDevice] model], [[UIDevice currentDevice] systemVersion], ([[UIScreen mainScreen] respondsToSelector:@selector(scale)] ? [[UIScreen mainScreen] scale] : 1.0f)];
    
    if (userAgent) {
        if (![userAgent canBeConvertedToEncoding:NSASCIIStringEncoding]) {
            NSMutableString *mutableUserAgent = [userAgent mutableCopy];
            CFStringTransform((__bridge CFMutableStringRef)(mutableUserAgent), NULL, kCFStringTransformToLatin, false);
            userAgent = mutableUserAgent;
        }
        //add to header
        [self setValue:userAgent forHTTPHederField:@"User-Agent"];
    }
}

- (void)setAuthHeaderWithUserName:(NSString*)aName Password:(NSString*)aPassword
{
    NSString *basicAuthCredentials = [NSString stringWithFormat:@"%@:%@", aName, aPassword];
    NSString* base64 = [basicAuthCredentials VZHTTP_base64Encoding];
    [self setValue:[NSString stringWithFormat:@"Basic %@",base64] forHTTPHederField:@"Authorization"];
}

- (void)setAuthHeaderFieldWithToken:(NSString *)token {
    [self setValue:[NSString stringWithFormat:@"Token token=\"%@\"", token] forHTTPHederField:@"Authorization"];
}


///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - public methods

- (NSURLRequest *)generateRequestWithConfig:(VZHTTPRequestConfig) config
                                  URLString:(NSString *)aURLString
                                     Params:(NSDictionary *)aParams
{
    NSParameterAssert(aURLString);
    NSURL *url = [NSURL URLWithString:aURLString];
    NSParameterAssert(url);
    NSMutableURLRequest *mutableRequest = [[NSMutableURLRequest alloc] initWithURL:url];
    NSString* method = vz_httpMethod(config.requestMethod);
    NSParameterAssert(method);
    
    [mutableRequest setHTTPMethod:method];
    [mutableRequest setTimeoutInterval:config.requestTimeoutSeconds];
    
     return[[self generateRequest:mutableRequest withParams:aParams error:nil]mutableCopy];
}

- (NSURLRequest*)generateRequest:(NSMutableURLRequest *)aRequest withParams:(NSDictionary *)aParam error:(NSError *__autoreleasing *)aError
{
    NSParameterAssert(aRequest);
    
    NSMutableURLRequest* mutableRequest = aRequest;
    
    [self.requestHeaders enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        [mutableRequest setValue:obj forHTTPHeaderField:key];
    }];
    
    if (!aParam) {
        return mutableRequest;
    }
    
    NSString* query = nil;
    if (self.requestStringGenerator) {
        query = self.requestStringGenerator(aRequest,aParam,aError);
    }
    else
    {
        //use default generator
        query = [self queryStringFromParams:aParam WithEncoding:self.stringEncoding];
    }
    
    NSString* httpMethod = [[aRequest HTTPMethod] uppercaseString];
    //包含"GET,HEAD,DELETE"
    if ([self.needEncodingMethods containsObject:httpMethod]) {
        
        NSString* hasQuery = [NSString stringWithFormat:@"&%@",query];
        NSString* noQuery = [NSString stringWithFormat:@"?%@",query];
        
        NSString* queryString = [[mutableRequest.URL absoluteString] stringByAppendingString:mutableRequest.URL.query ? hasQuery : noQuery];
        
        mutableRequest.URL = [NSURL URLWithString:queryString];
    
    }
    else
    {
        NSString *charset = (__bridge NSString *)CFStringConvertEncodingToIANACharSetName(CFStringConvertNSStringEncodingToEncoding(self.stringEncoding));
        [mutableRequest setValue:[NSString stringWithFormat:@"application/x-www-form-urlencoded; charset=%@", charset] forHTTPHeaderField:@"Content-Type"];
        [mutableRequest setHTTPBody:[query dataUsingEncoding:self.stringEncoding]];
    
    }
    
    return mutableRequest;
    
}



///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - private tool methods

- (void)setValue:(NSString* )value forHTTPHederField:(NSString* )field
{
    [self.requestHeaders setObject:value forKey:field];
}

- (void)removeValuefromHTTPHeaderField:(NSString*)aValue
{
    [self.requestHeaders removeObjectForKey:aValue];
}


- (NSString*)queryStringFromParams:(NSDictionary* )params WithEncoding:(NSStringEncoding) stringEncoding
{
    NSMutableArray *mutablePairs = [NSMutableArray array];
    
    NSArray* pairs = [self queryStringPairsFromKey:nil Value:params];
    
    for (VZHTTPRequestQueryStringPair *pair in pairs) {
        [mutablePairs addObject:[pair encodedStringValueWithEncoding:stringEncoding]];
    }
    
    return [mutablePairs componentsJoinedByString:@"&"];
}


- (NSArray *)queryStringPairsFromKey:(NSString*)key Value:(id)value
{
    NSMutableArray *mutableQueryStringComponents = [NSMutableArray array];
    
    if ([value isKindOfClass:[NSDictionary class]])
    {
        NSDictionary *dictionary = value;

        NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"description" ascending:YES selector:@selector(caseInsensitiveCompare:)];
        for (id nestedKey in [dictionary.allKeys sortedArrayUsingDescriptors:@[ sortDescriptor ]]) {
            id nestedValue = [dictionary objectForKey:nestedKey];
            if (nestedValue) {
                [mutableQueryStringComponents addObjectsFromArray:[self queryStringPairsFromKey:(key ? [NSString stringWithFormat:@"%@[%@]", key, nestedKey] : nestedKey) Value:nestedValue]];
            }
        }
    } else if ([value isKindOfClass:[NSArray class]])
    {
        NSArray *array = value;
        for (id nestedValue in array) {
            [mutableQueryStringComponents addObjectsFromArray:[self queryStringPairsFromKey:[NSString stringWithFormat:@"%@[]", key] Value:nestedValue]];
        }
    } else if ([value isKindOfClass:[NSSet class]])
    {
        NSSet *set = value;
        for (id obj in set) {
            [mutableQueryStringComponents addObjectsFromArray:[self queryStringPairsFromKey:key Value:obj]];
        }
    }
    else
    {
        [mutableQueryStringComponents addObject:[[VZHTTPRequestQueryStringPair alloc] initWithField:key value:value]];
    }
    
    return mutableQueryStringComponents;
}

@end
