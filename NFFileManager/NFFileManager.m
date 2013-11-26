//
//  NFFIleManager.m
//  NFFileManager
//
//  Created by Ricardo Santos on 25/11/2013.
//  Copyright (c) 2013 NextFaze. All rights reserved.
//

#import "NFFileManager.h"
#import <MobileCoreServices/MobileCoreServices.h>

NSString *const NFFileManagerSyncFinishedNotification = @"NFFileManagerSyncFinishedNotification";

NSString *const NFFileManagerKeyEtags = @"NFFileManagerEtags";

@interface NFFileManager () <NSURLConnectionDelegate>
@property (nonatomic, strong) NSOperationQueue *operationQueue;
@property (nonatomic, assign) BOOL syncInProgress;
@property (nonatomic, strong) NSMutableDictionary *etags;
@end

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

+ (NSString *)mimeTypeForFilename:(NSString *)filename
{
    CFStringRef UTI = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, (__bridge CFStringRef)[filename pathExtension], NULL);
    CFStringRef MIMEType = UTTypeCopyPreferredTagWithClass (UTI, kUTTagClassMIMEType);
    CFRelease(UTI);
    return (__bridge NSString *)MIMEType;
}

- (id)init
{
    if (self = [super init]) {
        // setup the url cache http://nshipster.com/nsurlcache/
        NSURLCache *URLCache = [[NSURLCache alloc] initWithMemoryCapacity:4 * 1024 * 1024
                                                             diskCapacity:20 * 1024 * 1024
                                                                 diskPath:nil];
        [NSURLCache setSharedURLCache:URLCache];
        
        self.operationQueue = [[NSOperationQueue alloc] init];
        self.operationQueue.maxConcurrentOperationCount = 1;
        
        NSDictionary *savedEtags = [[NSUserDefaults standardUserDefaults] objectForKey:NFFileManagerKeyEtags];
        self.etags = [NSMutableDictionary dictionaryWithDictionary:savedEtags];
    }
    return self;
}

- (void)setMaxConcurrentDownloads:(NSInteger)maxConcurrentDownloads
{
    self.operationQueue.maxConcurrentOperationCount = maxConcurrentDownloads;
    _maxConcurrentDownloads = maxConcurrentDownloads;
}

- (void)sync
{
    if (self.syncInProgress) {
        if (self.printDebugMessages) {
            NSLog(@"Sync already in progress.");
        }
        return;
    }
    
    if (self.filenames.count == 0) {
        NSLog(@"No filenames set, nothing to sync.");
        return;
    }
    
    if (self.serverPath.length == 0) {
        NSLog(@"No server path set, cannot sync.");
        return;
    }
    
    self.syncInProgress = YES;
    
    NSDate *syncStartDate = [NSDate date];
    
    for (NSString *filename in self.filenames) {
        
        BOOL isLastFile = filename == [self.filenames lastObject];
        
        NSString *path = [self.serverPath stringByAppendingPathComponent:filename];
        
        if (self.printDebugMessages) {
            NSLog(@"Requesting file with path: %@", path);
        }
        
        NSURL *URL = [NSURL URLWithString:path];
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:URL
                                                               cachePolicy:NSURLRequestReloadRevalidatingCacheData
                                                           timeoutInterval:30.0];
        
        NSString *etag = [self.etags objectForKey:filename];
        if (etag) {
            [request setValue:etag forHTTPHeaderField:@"If-None-Match"];
        }
        
        if (self.printDebugMessages) {
            NSLog(@"Request Header Fields:");
            NSDictionary *headers = [request allHTTPHeaderFields];
            for (NSString *key in [headers allKeys]) {
                NSLog(@"%@ : %@", key, [headers objectForKey:key]);
            }
        }
        
        [NSURLConnection sendAsynchronousRequest:request
                                           queue:self.operationQueue
                               completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
                                   
                                   NSHTTPURLResponse * httpResponse = (NSHTTPURLResponse*)response;
                                   
                                   if (self.printDebugMessages) {
                                       NSLog(@"Response Code %d for file %@", httpResponse.statusCode, filename);

                                       NSLog(@"\n\nResponse Header Fields:");
                                       NSDictionary *headers = [httpResponse allHeaderFields];
                                       for (NSString *key in [headers allKeys]) {
                                           NSLog(@"%@ : %@", key, [headers objectForKey:key]);
                                       }
                                   }
                                   
                                   if (connectionError) {
                                       NSLog(@"ERROR (%d): %@", httpResponse.statusCode, [connectionError localizedDescription]);
                                   }
                                   
                                   if (httpResponse.statusCode == 200) {
                                       NSString *documentsPath = [[self documentsDirectory] stringByAppendingPathComponent:filename];
                                       [data writeToFile:documentsPath atomically:YES];
                                       
                                       NSDictionary *headers = [httpResponse allHeaderFields];
                                       NSString *etag = [headers valueForKey:@"Etag"];
                                       if (etag) {
                                           [self.etags setValue:etag forKey:filename];
                                       }
                                       
                                   }
                                   
                                   if (isLastFile) {
                                       self.syncInProgress = NO;
                                       [[NSNotificationCenter defaultCenter] postNotificationName:NFFileManagerSyncFinishedNotification object:nil];
                                       
                                       if (self.printDebugMessages) {
                                           NSTimeInterval timeTaken = [[NSDate date] timeIntervalSinceDate:syncStartDate];
                                           NSLog(@"Sync complete. Time taken: %f s.", timeTaken);
                                       }
                                       
                                       [[NSUserDefaults standardUserDefaults] setObject:self.etags forKey:NFFileManagerKeyEtags];
                                       [[NSUserDefaults standardUserDefaults] synchronize];
                                   }
                                   
                               }];
    }
}

- (NSData *)fileWithName:(NSString *)filename
{
    // first try the documents directory
    NSString *documentsPath = [[self documentsDirectory] stringByAppendingPathComponent:filename];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:documentsPath]) {
        if (self.printDebugMessages) {
            NSLog(@"SUCCESS. Found '%@' in the documents directory.", filename);
        }
        
        NSURL *url = [NSURL fileURLWithPath:documentsPath];
        NSData *data = [[NSData alloc] initWithContentsOfURL:url];
        return data;

    } else {
        // then try the main bundle
        NSString *resourceType = [filename pathExtension];
        NSString *resourceName = [filename stringByDeletingPathExtension];
        
        NSString *bundlePath = [[NSBundle mainBundle] pathForResource:resourceName ofType:resourceType];
        if (bundlePath) {
            NSLog(@"SUCCESS. Found '%@' in the main bundle.", filename);

            NSData *data = [[NSData alloc] initWithContentsOfFile:bundlePath];
            [data writeToFile:documentsPath atomically:YES];
            
            return data;
        }
    }
    
    NSLog(@"WARNING: Could not locate file named '%@'", filename);
    return nil;
}

- (NSString *)documentsDirectory
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    return documentsDirectory;
}

@end
