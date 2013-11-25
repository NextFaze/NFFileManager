//
//  NFFIleManager.m
//  NFFileManagerDemo
//
//  Created by Ricardo Santos on 25/11/2013.
//  Copyright (c) 2013 NextFaze. All rights reserved.
//

#import "NFFileManager.h"

@implementation NFFileManager

+ (NFFileManager *)sharedManager
{
    static NFFileManager *sharedManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedManager = [[self alloc] init];
    });
    return sharedManager;
}

- (id)init
{
    if (self = [super init]) {

    }
    return self;
}

+ (void)sync
{
    
}

+ (NSData *)fileWithName:(NSString *)filename
{
    NFFileManager *fileManager = [NFFileManager sharedManager];
    return [fileManager fileWithName:filename];
}

- (NSData *)fileWithName:(NSString *)filename
{
    // first try the documents directory
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *documentsPath = [documentsDirectory stringByAppendingPathComponent:filename];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:documentsPath]) {
        if (self.printDebugMessages) {
            NSLog(@"SUCCESS. Found '%@' in the documents directory.", filename);
            
            NSURL *url = [NSURL fileURLWithPath:documentsPath];
            NSData *data = [[NSData alloc] initWithContentsOfURL:url];
            return data;
        }
        
    } else {
        // try the main bundle
        NSString *resourceType = [filename pathExtension];
        NSString *resourceName = [filename stringByDeletingPathExtension];
        
        NSLog(@"resource name: %@", resourceName);
        NSLog(@"resource type: %@", resourceType);
        
        NSString *bundlePath = [[NSBundle mainBundle] pathForResource:resourceName ofType:resourceType];
        if (bundlePath) {
            NSLog(@"SUCCESS. Found '%@' in the main bundle.", filename);

            NSData *data = [[NSData alloc] initWithContentsOfFile:bundlePath];
            [data writeToFile:documentsPath atomically:YES];
            
            return data;
        }

    }
    
    if (self.printDebugMessages) {
        NSLog(@"WARNING: Could not locate file named '%@'", filename);
    }
    
    return nil;
}

@end
