//
//  NFFIleManager.h
//  NFFileManagerDemo
//
//  Created by Ricardo Santos on 25/11/2013.
//  Copyright (c) 2013 NextFaze. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString *const NFFileManagerSyncFinishedNotification;

@interface NFFileManager : NSObject

@property (nonatomic, strong) NSString *serverPath;
@property (nonatomic, strong) NSArray *filenames;
@property (nonatomic, assign) BOOL printDebugMessages;
@property (nonatomic, readonly) BOOL syncInProgress;
@property (nonatomic, assign) NSInteger maxConcurrentDownloads;

+ (NFFileManager *)sharedManager;
+ (NSString *)mimeTypeForFilename:(NSString *)filename;

- (void)sync;
- (NSData *)fileWithName:(NSString *)filename;

@end
