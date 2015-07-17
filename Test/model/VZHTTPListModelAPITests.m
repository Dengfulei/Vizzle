//
//  VZHTTPListModelAPITests.m
//  VizzleTest
//
//  Created by moxin on 15/7/17.
//  Copyright (c) 2015年 VizLab. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "BXTWTripListModel.h"
#import "BXTWTripListItem.h"


@interface VZHTTPListModelAPITests : XCTestCase<VZModelDelegate>

@property(nonatomic,strong)BXTWTripListModel* model;

@end

@implementation VZHTTPListModelAPITests
{
    XCTestExpectation* _expecation;
}

- (void)setUp {
    [super setUp];
    
    self.model = [BXTWTripListModel new];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
    self.model = nil;
    _expecation = nil;
}

- (void)testLoadAll
{
    _expecation = [self expectationWithDescription:NSStringFromSelector(_cmd)];
    self.model.delegate = self;
    [self.model loadAll];
    NSTimeInterval t = self.model.requestConfig.requestTimeoutSeconds;
    [self waitForExpectationsWithTimeout:t handler:^(NSError *error) {
        if (error) {
            XCTFail(@"\xE2\x9D\x8C[Timeout]:%@",error.userInfo[NSLocalizedDescriptionKey]);
        }
        else
        {
            
        }
    }];
}

- (void)testLoadAllWithCompletion
{
    self.model.delegate=nil;
    [self.model loadAllWithCompletion:^(VZModel *model, NSError *error) {
        
    }];
    NSTimeInterval t = 10.0f;
    [self delay:t completion:^{
       
        if (self.model.error) {
            XCTAssertEqual(self.model.state, VZModelStateError);
        }
        else
        {
            XCTAssertEqual(self.model.state, VZModelStateFinished);
            XCTAssertEqual(self.model.hasMore, NO);
        }
        
    }];
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark - callback


- (void)modelDidStart:(VZModel *)model
{
    XCTAssertEqual(model.state, VZModelStateLoading);
}

- (void)modelDidFinish:(VZHTTPListModel *)model
{
    XCTAssertEqual(model.state, VZModelStateFinished);
    XCTAssertEqual(model.hasMore , NO);
    [_expecation fulfill];
}

- (void)modelDidFail:(VZModel *)model withError:(NSError *)error
{
    XCTAssertEqual(model.state, VZModelStateError);
    [_expecation fulfill];
}

- (void)modelDidCancel:(VZModel *)model
{
    XCTAssertEqual(model.state, VZModelStateReady);
    [_expecation fulfill];
}
////////////////////////////////////////////////////////////////////////////////
#pragma mark - tool

- (void)delay:(NSTimeInterval)t completion:(void(^)(void))block
{
    NSDate* date = [NSDate dateWithTimeIntervalSinceNow:t];
    while ([date timeIntervalSinceNow] > 0) {
        
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:date];
    }
    if (block) {
        block();
    }
}

@end
