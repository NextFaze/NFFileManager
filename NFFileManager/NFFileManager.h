//
//  NFFIleManager.h
//  NFFileManagerDemo
//
//  Created by Ricardo Santos on 25/11/2013.
//  Copyright (c) 2013 NextFaze. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NFFileManager : NSObject

@property (nonatomic, strong) NSString *serverPath;
@property (nonatomic, strong) NSArray *filenames;
@property (nonatomic, assign) BOOL printDebugMessages;

+ (NFFileManager *)sharedManager;
+ (void)sync;
+ (NSData *)fileWithName:(NSString *)filename;

@end
