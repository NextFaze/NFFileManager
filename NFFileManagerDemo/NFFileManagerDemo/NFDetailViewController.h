//
//  NFDetailViewController.h
//  NFFileManagerDemo
//
//  Created by Ricardo Santos on 25/11/2013.
//  Copyright (c) 2013 NextFaze. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface NFDetailViewController : UIViewController <UISplitViewControllerDelegate, UIWebViewDelegate>

@property (strong, nonatomic) NSString *filename;
@property (strong, nonatomic) NSData *data;

@property (weak, nonatomic) IBOutlet UILabel *detailDescriptionLabel;
@property (weak, nonatomic) IBOutlet UIWebView *webView;

@end
