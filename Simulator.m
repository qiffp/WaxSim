//
//   
//  Sim
//
//  Created by ProbablyInteractive on 7/28/09.
//  Copyright 2009 Probably Interactive. All rights reserved.
//

#import "Simulator.h"

#include <sys/param.h>
#include <objc/runtime.h>

#define WaxLog(format, args...) \
    fprintf(stderr, "%s\n", [[NSString stringWithFormat:(format), ## args] UTF8String])

@implementation Simulator

- (id)initWithAppPath:(NSString *)appPath sdk:(NSString *)sdk device:(NSString *)device env:(NSDictionary *)env args:(NSArray *)args
{
    self = [super init];

    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([appPath isAbsolutePath] == NO) {
        appPath = [[fileManager currentDirectoryPath] stringByAppendingPathComponent:appPath];
    }   
    
    _appPath = appPath;

    if ([fileManager fileExistsAtPath:_appPath] == NO) {
        WaxLog(@"App path '%@' does not exist!", _appPath);
        exit(EXIT_FAILURE);
    }

    if (sdk) {
        _sdk = [DTiPhoneSimulatorSystemRoot rootWithSDKVersion:sdk];
    } else {
        _sdk = [DTiPhoneSimulatorSystemRoot defaultRoot];
    }
    
    if (!_sdk) {
        WaxLog(@"Unknown sdk '%@'", sdk);
        WaxLog(@"Available sdks are...");
        for (id root in [DTiPhoneSimulatorSystemRoot knownRoots]) {
            WaxLog(@"  %@", [root sdkVersion]);
        }
        
        exit(EXIT_FAILURE);
    }
	
	_device = [self validateDevice:device];
	_env = env;
	_args = args;

    return self;
}

+ (NSArray *)availableSDKs
{
    NSMutableArray *sdks = [NSMutableArray array];
    for (DTiPhoneSimulatorSystemRoot *root in [DTiPhoneSimulatorSystemRoot knownRoots]) {
        [sdks addObject:[root sdkVersion]];
    }
    
    return sdks;
}

- (int)launch
{
    WaxLog(@"Launching '%@' on'%@'", _appPath, [_sdk sdkDisplayName]);
    
    DTiPhoneSimulatorApplicationSpecifier *appSpec = [DTiPhoneSimulatorApplicationSpecifier specifierWithApplicationPath:_appPath];
    if (!appSpec) {
        WaxLog(@"Could not load application specifier for '%@'", _appPath);
        return EXIT_FAILURE;
    }
    
    DTiPhoneSimulatorSystemRoot *sdkRoot = [DTiPhoneSimulatorSystemRoot defaultRoot];
    
    DTiPhoneSimulatorSessionConfig *config = [[DTiPhoneSimulatorSessionConfig alloc] init];
    [config setApplicationToSimulateOnStart:appSpec];
    [config setSimulatedSystemRoot:sdkRoot];
    [config setSimulatedDeviceInfoName:_device];
    [config setSimulatedApplicationShouldWaitForDebugger:NO];    
    [config setSimulatedApplicationLaunchArgs:_args];
    [config setSimulatedApplicationLaunchEnvironment:_env];
    [config setLocalizedClientName:@"WaxSim"];

    // Make the simulator output to the current STDERR
	// We mix them together to avoid buffering issues on STDOUT
    char path[MAXPATHLEN];

    fcntl(STDERR_FILENO, F_GETPATH, &path);
    [config setSimulatedApplicationStdOutPath:@(path)];
    [config setSimulatedApplicationStdErrPath:@(path)];
    
    _session = [[DTiPhoneSimulatorSession alloc] init];
    [_session setDelegate:self];
    
    NSError *error;
    if ([_session requestStartWithConfig:config timeout:30 error:&error] == NO) {
        WaxLog(@"Could not start simulator session: %@", [error localizedDescription]);
        return EXIT_FAILURE;
    }
    
    return EXIT_SUCCESS;
}

- (void)end
{
    [_session requestEndWithTimeout:0];
}

- (NSString *)validateDevice:(NSString *)device
{
	NSArray *validDevices = @[@"iPhone", @"iPad"];
	for (NSString *validDevice in validDevices) {
		if ([device compare:validDevice options:NSCaseInsensitiveSearch] == NSOrderedSame) {
			return validDevice;
		}
	}
	
	return @"iPhone";
}

// DTiPhoneSimulatorSession Delegate
// ---------------------------------
- (void)session:(DTiPhoneSimulatorSession *)session didStart:(BOOL)started withError:(NSError *)error
{
    if (started == NO) {
        WaxLog(@"Session failed to start. %@", [error localizedDescription]);
        exit(EXIT_FAILURE);
    }
}

- (void)session:(DTiPhoneSimulatorSession *)session didEndWithError:(NSError *)error
{
    if (error) {
        WaxLog(@"Session ended with error. %@", [error localizedDescription]);
        if ([error code] != 2) {
			// if it is a timeout error, that's cool. We are probably rebooting
			exit(EXIT_FAILURE);
		}
    } else {
        exit(EXIT_SUCCESS);
    }
}

@end
