//
//  NFMasterViewController.h
//  NFFileManagerDemo
//
//  Created by Ricardo Santos on 25/11/2013.
//  Copyright (c) 2013 NextFaze. All rights reserved.
//

#import <UIKit/UIKit.h>

@class NFDetailViewController;

@interface NFMasterViewController : UITableViewController

@property (strong, nonatomic) NFDetailViewController *detailViewController;

@end
