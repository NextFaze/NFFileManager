//
//  NFAddViewController.m
//  NFFileManagerDemo
//
//  Created by Ricardo Santos on 21/05/2014.
//  Copyright (c) 2014 NextFaze. All rights reserved.
//

#import "NFAddViewController.h"
#import "NFFileManager.h"

@interface NFAddViewController ()

@property (nonatomic, strong) UITextField *filenameTextField;
@property (nonatomic, strong) UITextView *textView;

@end

@implementation NFAddViewController

- (id)init
{
    return [self initWithNibName:nil bundle:nil];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.title = @"Add File";
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor lightGrayColor];

    UIBarButtonItem *saveButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(save:)];
    self.navigationItem.rightBarButtonItem = saveButton;
    
    UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancel:)];
    self.navigationItem.leftBarButtonItem = cancelButton;
    
    self.filenameTextField = [[UITextField alloc] initWithFrame:CGRectZero];
    self.filenameTextField.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:self.filenameTextField];
    
    self.textView = [[UITextView alloc] initWithFrame:CGRectZero];
    [self.view addSubview:self.textView];
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    
    CGFloat padding = 10.0;
    
    self.filenameTextField.frame = CGRectMake(padding, padding + 64, self.view.frame.size.width - 2*padding, 40);
    self.textView.frame = CGRectMake(padding, 120, self.filenameTextField.frame.size.width, 240);
}

- (void)save:(id)sender
{
    if (self.textView.text == nil || self.filenameTextField.text.length == 0) {
        return;
    }
    
    NSData *data = [self.textView.text dataUsingEncoding:NSUTF8StringEncoding];
    [[NFFileManager sharedManager] saveFileWithName:self.filenameTextField.text andData:data];
    
    NSArray *existingFilenames = [[NFFileManager sharedManager] filenames];
    [NFFileManager sharedManager].filenames = [existingFilenames arrayByAddingObject:self.filenameTextField.text];
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)cancel:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
