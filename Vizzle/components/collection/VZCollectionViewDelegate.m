//
//  VZCollectionViewDelegate.m
//  VizzleListExample
//
//  Created by moxin on 15/11/15.
//  Copyright © 2015年 VizLab. All rights reserved.
//

#import "VZCollectionViewDelegate.h"
#import "VZCollectionViewController.h"
#import "VZPullToRefreshControl.h"
#import "VZCollectionCell.h"
#import "VZCollectionItem.h"

@interface VZCollectionViewDelegate()<VZCellActionInterface>

@property(nonatomic,strong) VZPullToRefreshControl* pullRefreshView;

@end

@implementation VZCollectionViewDelegate

///////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - getters

- (VZPullToRefreshControl* )pullRefreshView
{
    if (!_pullRefreshView) {
        _pullRefreshView = [[VZPullToRefreshControl alloc]init];
        // _pullRefreshViewInternal.backgroundColor = self.controller.tableView.backgroundColor;
        // 如果设置背景色，位置将会随着下拉改变，否则定在原地
        __weak typeof(self)weakSelf = self;
        _pullRefreshView.pullRefreshDidTrigger = ^(void){
            [weakSelf.controller performSelector:@selector(pullRefreshDidTrigger) withObject:nil];
        };
        
        if (self.controller.needPullRefresh) {
            [self.controller.collectionView addSubview:(UIView* )_pullRefreshView];
        }
        
        
    }
    return _pullRefreshView;
}

// Methods for notification of selection/deselection and highlight/unhighlight events.
// The sequence of calls leading to selection from a user touch is:
//
// (when the touch begins)
// 1. -collectionView:shouldHighlightItemAtIndexPath:
// 2. -collectionView:didHighlightItemAtIndexPath:
//
// (when the touch lifts)
// 3. -collectionView:shouldSelectItemAtIndexPath: or -collectionView:shouldDeselectItemAtIndexPath:
// 4. -collectionView:didSelectItemAtIndexPath: or -collectionView:didDeselectItemAtIndexPath:
// 5. -collectionView:didUnhighlightItemAtIndexPath:
- (BOOL)collectionView:(UICollectionView *)collectionView shouldHighlightItemAtIndexPath:(NSIndexPath *)indexPath
{
    return NO;
}
- (void)collectionView:(UICollectionView *)collectionView didHighlightItemAtIndexPath:(NSIndexPath *)indexPath
{
    
}
- (void)collectionView:(UICollectionView *)collectionView didUnhighlightItemAtIndexPath:(NSIndexPath *)indexPath
{
    
}
- (BOOL)collectionView:(UICollectionView *)collectionView shouldSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

// called when the user taps on an already-selected item in multi-select mode
- (BOOL)collectionView:(UICollectionView *)collectionView shouldDeselectItemAtIndexPath:(NSIndexPath *)indexPath
{
    return NO;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    [self.controller collectionView:collectionView didSelectItemAtIndexPath:indexPath];
    
}
- (void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath
{
    
}

- (void)collectionView:(UICollectionView *)collectionView didEndDisplayingCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath
{
    
}
- (void)collectionView:(UICollectionView *)collectionView didEndDisplayingSupplementaryView:(UICollectionReusableView *)view forElementOfKind:(NSString *)elementKind atIndexPath:(NSIndexPath *)indexPath
// These methods provide support for copy/paste actions on cells.
// All three should be implemented if any are.
{
    
}
- (BOOL)collectionView:(UICollectionView *)collectionView shouldShowMenuForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return NO;
}
- (BOOL)collectionView:(UICollectionView *)collectionView canPerformAction:(SEL)action forItemAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender
{
    return YES;
}
- (void)collectionView:(UICollectionView *)collectionView performAction:(SEL)action forItemAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender
{
    
}
// support for custom transition layout
- (UICollectionViewTransitionLayout *)collectionView:(UICollectionView *)collectionView transitionLayoutForOldLayout:(UICollectionViewLayout *)fromLayout newLayout:(UICollectionViewLayout *)toLayout
{
    return nil;
}

/////////////////////////////////////////////////////////////////////////////////////
#pragma mark - scrollview 

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - scrollview's delegate


- (void)scrollViewDidEndDragging:(UIScrollView*)scrollView willDecelerate:(BOOL)decelerate
{
    //下拉刷新
    if (self.controller.needPullRefresh && [self.pullRefreshView respondsToSelector:@selector(scrollviewDidEndDragging:)]) {
        [self.pullRefreshView scrollviewDidEndDragging:scrollView];
        
    }
    
    [self.controller scrollViewDidEndDragging:scrollView willDecelerate:decelerate];
}

- (void)scrollViewDidEndDecelerating:(UIScrollView*)scrollView
{
    if (self.controller.needPullRefresh && [self.pullRefreshView respondsToSelector:@selector(scrollViewDidEndDecelerating:)]) {
        [self.pullRefreshView scrollViewDidEndDecelerating:scrollView];
    }
    
    [self.controller scrollViewDidEndDecelerating:scrollView];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if (self.controller.needPullRefresh && [self.pullRefreshView respondsToSelector:@selector(scrollviewDidScroll:)]) {
        [self.pullRefreshView scrollviewDidScroll:scrollView];
    }
    
    [self.controller scrollViewDidScroll:scrollView];
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    
    [self.controller scrollViewWillBeginDragging:scrollView];
}



/////////////////////////////////////////////////////////////////////////////////////
#pragma mark - cell delegate

- (void)onCellComponentClickedAtIndex:(NSIndexPath *)indexPath Bundle:(NSDictionary *)extra
{
//    self.controller col
}

/////////////////////////////////////////////////////////////////////////////////////
#pragma mark - message forwarding

- (BOOL) respondsToSelector:(SEL)aSelector
{
    if([super respondsToSelector:aSelector])
    {
        return YES;
    }
    else
    {
        UICollectionViewLayout* layout = self.controller.collectionView.collectionViewLayout;
        if ([layout isKindOfClass:[UICollectionViewFlowLayout class]]) {
            
            if ([layout respondsToSelector:aSelector]) {
                return YES;
            }
            else
                return NO;
        }
        return NO;
    }
}
- (NSMethodSignature*)methodSignatureForSelector:(SEL)selector
{
    NSMethodSignature* signature = [super methodSignatureForSelector:selector];
    if (!signature) {
        
        UICollectionViewLayout* layout = self.controller.collectionView.collectionViewLayout;
        if ([layout isKindOfClass:[UICollectionViewFlowLayout class]]) {
            signature = [layout methodSignatureForSelector:selector];
        }
    }
    return signature;
}

- (void)forwardInvocation:(NSInvocation *)anInvocation
{
    UICollectionViewLayout* layout = self.controller.collectionView.collectionViewLayout;
    if ([layout isKindOfClass:[UICollectionViewFlowLayout class]])
    {
        if ([layout respondsToSelector:[anInvocation selector]]) {
            
            [anInvocation invokeWithTarget:layout];
        }
        else
            [super forwardInvocation:anInvocation];
    }
    else
        [super forwardInvocation:anInvocation];
    
}


@end
