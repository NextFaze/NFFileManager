NFFileManager
=============

An iOS file updater. Give it a remote server path, and a list of files that live there, and ask it to `sync`. NFFileManager will go along and download each file if necessary, and save that file to the Documents dir. 

NB: Because NSURLConnection is used with caching, the files are also saved in a sqlite db by NSURL, but so be it.

If you don't need any server functionality, you can still use the NFFileManager to read files locally. It will read from the documents dir, and if the file doesn't exist there it will read from the main bundle. If the file is found in the main bundle it will also write it to the documents dir for next time.

## Installation

### Via CocoaPods

1. Add to your Podfile:

	`pod 'NFFileManager', :git => 'https://github.com/NextfazeSD/NFFileManager.git`

2. Run Install:
	
	`$ pod install'

### Via Git Submodules

1. Add submodule to your project:

    `$ git submodule add git@github.com:NextfazeSD/NFFileManager.git ThirdParty/NFFileManager`
    
2. Drag the `NFFileManager` folder from Finder to the ThirdParty folder in your project tree. It should contain two files, `NFFileManager.h` and `NFFileManger.m`.
3. NFFileManager uses ARC, so if your project doesn't use ARC, add the `-fobjc-arc` compiler flag to `NFFileManager.m` in the Build Phases tab.

## Usage

Setup like so, usually in `application:didfinishLaunchingWithOptions`:

    NFFileManager *fileManager = [NFFileManager sharedManager];
    fileManager.printDebugMessages = YES;
    fileManager.serverPath = @"http://files.faze.biz/nffilemanager";
    fileManager.filenames = @[@"blank.html",
                              @"blank2.html",
                              @"doesntexist.html",
                              @"nextfaze-SQ-512x512.png",
                              @"wallpaper.png"];


## Contact

[NextFaze](http://nextfaze.com)

## License

Copyright 2013 [NextFaze](http://nextfaze.com).

NFFileManager is licensed under the terms of the [Apache License, version 2.0](http://www.apache.org/licenses/LICENSE-2.0.html). Please see the [LICENSE](https://github.com/NextfazeSD/NFFileManager/blob/master/LICENSE) file for full details.
