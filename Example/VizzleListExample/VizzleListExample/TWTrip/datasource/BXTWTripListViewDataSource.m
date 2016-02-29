  
//
//  BXTWTripListViewDataSource.m
//  BX
//
//  Created by Jayson.xu@foxmail.com on 2015-07-14 21:28:18 +0800.
//  Copyright (c) 2015年 VizLab. All rights reserved.
//



#import "BXTWTripListViewDataSource.h"
#import "BXTWTripCollectionCell.h"
#import "BXTWTripListCell.h"
#import "BXTWTripConfig.h"
#import "BXTWTripListViewController.h"
#import "BXTWTripAsyncCollectionCell.h"

@interface BXTWTripListViewDataSource()

@end

@implementation BXTWTripListViewDataSource

- (Class)cellClassForItem:(id)item AtIndex:(NSIndexPath *)indexPath{

    return [BXTWTripCollectionCell class];
    
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}

- (void)fitLayout:(LAYOUT)type
{
    int w = [UIScreen mainScreen].bounds.size.width;
    NSArray* items = [self itemsForSection:0];
    for (VZCollectionItem* item in items) {
        
        if (type == kWaterflow) {
//            item.itemWidth = 0.5*w;
            item.itemWidth = w / 3.0f;
        }
        else
        {
            item.itemWidth = w;
        }
    }
}




@end  
