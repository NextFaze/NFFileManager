//
//  NFMasterViewController.m
//  NFFileManagerDemo
//
//  Created by Ricardo Santos on 25/11/2013.
//  Copyright (c) 2013 NextFaze. All rights reserved.
//

#import "NFMasterViewController.h"
#import "NFDetailViewController.h"
#import "NFFileManager.h"

@interface NFMasterViewController () {
    
}
@end

@implementation NFMasterViewController

- (void)awakeFromNib
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        self.clearsSelectionOnViewWillAppear = NO;
        self.preferredContentSize = CGSizeMake(320.0, 600.0);
    }
    [super awakeFromNib];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.

    UIBarButtonItem *syncButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(sync:)];
    self.navigationItem.rightBarButtonItem = syncButton;
    self.detailViewController = (NFDetailViewController *)[[self.splitViewController.viewControllers lastObject] topViewController];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)sync:(id)sender
{
    [NFFileManager sync];
}

#pragma mark - Table View

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [NFFileManager sharedManager].filenames.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];

    NSArray *filenames = [NFFileManager sharedManager].filenames;
    NSString *filename = filenames[indexPath.row];
    cell.textLabel.text = filename;
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        NSArray *filenames = [NFFileManager sharedManager].filenames;
        NSString *filename = filenames[indexPath.row];
        self.detailViewController.filename = filename;
        self.detailViewController.data = [NFFileManager fileWithName:filename];
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([[segue identifier] isEqualToString:@"showDetail"]) {
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        
        NSArray *filenames = [NFFileManager sharedManager].filenames;
        NSString *filename = filenames[indexPath.row];
        NSData *data = [NFFileManager fileWithName:filename];
        [[segue destinationViewController] setFilename:filename];
        [[segue destinationViewController] setData:data];
    }
}

@end
