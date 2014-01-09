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
        
        if (filename.length == 0) {
            continue;
        }
        
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
        
        [NSURLConnection sendAsynchronousRequest:request
                                           queue:self.operationQueue
                               completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
                                   
                                   NSHTTPURLResponse * httpResponse = (NSHTTPURLResponse*)response;
                                   
                                   if (self.printDebugMessages) {
                                       NSLog(@"Response Code %d for file %@", httpResponse.statusCode, filename);
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

- (UIImage *)imageWithName:(NSString *)filename
{
    CGFloat scale = [[UIScreen mainScreen] scale];
    
    NSData *data = [self fileWithName:filename];
    UIImage *image = [[UIImage alloc] initWithData:data scale:scale];
    
    return image;
}

- (NSString *)fullPathForFileWithName:(NSString *)filename
{
    // first try the documents directory
    NSString *documentsPath = [[self documentsDirectory] stringByAppendingPathComponent:filename];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:documentsPath]) {
        return documentsPath;
        
    } else {
        // then try the main bundle
        NSString *resourceType = [filename pathExtension];
        NSString *resourceName = [filename stringByDeletingPathExtension];
        
        NSString *bundlePath = [[NSBundle mainBundle] pathForResource:resourceName ofType:resourceType];
        if (bundlePath) {
            return bundlePath;
        }
    }
    
    NSLog(@"WARNING: Could not determine path for file named '%@'", filename);
    return nil;
}

- (NSString *)documentsDirectory
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    return documentsDirectory;
}

- (NSString *)retinaStringForFilename:(NSString *)nonRetinaFilename
{
    // http://stackoverflow.com/questions/6404410/how-should-retina-normal-images-be-handled-when-loading-from-url
    
    // Find the range (location and length of ".")
    // Use options parameter to start from the back.
    NSRange extDotRange = [nonRetinaFilename rangeOfString:@"." options:NSBackwardsSearch];
    // You can check whether the "." is there or not like this:
    if (extDotRange.location == NSNotFound){
        // Handle trouble
        return nil;
    }
    
    // We can use NSString's stringByReplacingCharactersInRange:withString: method to insert the "@2x".
    // To do this we first calculate the range to 'replace'.
    // For location we use the location of the ".".
    // We use 0 for length since we do not want to replace anything.
    NSRange insertRange = NSMakeRange(extDotRange.location, 0);
    
    // Lastly simply use the stringByReplacingCharactersInRange:withString: method to insert "@2x" in the insert range.
    NSString *retinaAddress = [nonRetinaFilename stringByReplacingCharactersInRange:insertRange withString:@"@2x"];
    return retinaAddress;
}

@end
