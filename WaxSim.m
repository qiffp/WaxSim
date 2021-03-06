#import <AppKit/AppKit.h>
#import "iPhoneSimulatorRemoteClient.h"
#import "Simulator.h"
#import "termios.h"

static BOOL gReset = false;

void printUsage();
void resetSignal(int sig);

int main(int argc, char *argv[]) {
    signal(SIGQUIT, resetSignal);
    
    int c;
    char *sdk = nil;
	char *device = nil;
    char *appPath = nil;
	NSMutableArray *additionalArgs = [NSMutableArray array];
	NSMutableDictionary *environment = [NSMutableDictionary dictionary];
	NSString *environment_variable;
	NSArray *environment_variable_parts;
    
	//	Load the platform SDKs
	NSError *error;
	if ([DVTPlatform loadAllPlatformsReturningError:&error] == NO) {
		fprintf(stderr, "Failed to load platform SDKs: %s\n", [[error localizedDescription] UTF8String]);
		return 1;
	}

    while ((c = getopt(argc, argv, "e:s:d:v:ah")) != -1) {
        switch(c) {
			case 'e':
				environment_variable = @(optarg);
				environment_variable_parts = [environment_variable componentsSeparatedByString:@"="];

				environment[environment_variable_parts[0]] = environment_variable_parts[1];
				break;
            case 's':
                sdk = optarg;
                break;
			case 'd':
				device = optarg;
				break;
            case 'a':
                fprintf(stdout, "Available SDK Versions:\n");
                for (NSString *sdkVersion in [Simulator availableSDKs]) {
                    fprintf(stderr, "  %s\n", [sdkVersion UTF8String]);
                }
                return 1;
            case 'h':
                printUsage();
                return 1;
            case '?':
                if (optopt == 's' || optopt == 'd') {
                    fprintf(stderr, "Option -%c requires an argument.\n", optopt);
                    printUsage();
                } else {
                    fprintf(stderr, "Unknown option `-%c'.\n", optopt);
                    printUsage();
                }
                return 1;
                break;
            default:
                abort();
        }
        
    }
    
    if (argc > optind) {
        appPath = argv[optind++];

		// Additional args are sent to app
		for (int i = optind; i < argc; i++) {
			[additionalArgs addObject:@(argv[i])];
		}
	} else {
        fprintf(stderr, "No app-path was specified!\n");
        printUsage();
        return 1;
    }
    
    NSString *sdkString = sdk ? @(sdk) : nil;
	NSString *deviceString = device ? @(device) : nil;
    NSString *appPathString = @(appPath);

    Simulator *simulator = [[Simulator alloc] initWithAppPath:appPathString sdk:sdkString device:deviceString env:environment args:additionalArgs];
    [simulator launch];

    [[NSRunLoop mainRunLoop] run];
    return 0;
}

void printUsage() {
    fprintf(stderr, "\nusage: waxsim [options] app-path\n");
    fprintf(stderr, "example: waxsim -s 2.2 /path/to/app.app\n");
    fprintf(stderr, "Available options are:\n");    
    fprintf(stderr, "\t-s sdk\tVersion number of sdk to use (-s 6.1). Defaults to the latest SDK available.\n");
    fprintf(stderr, "\t-d device\tDevice to use (-d iPad). Options are 'iPad' and 'iPhone'. Defaults to iPhone.\n");
    fprintf(stderr, "\t-e VAR=value\tEnvironment variable to set (-e CFFIXED_HOME=/tmp/iphonehome)\n");
    fprintf(stderr, "\t-a \tLists the available SDKs.\n");
    fprintf(stderr, "\t-h \tPrints out this wonderful documentation!\n");    
}

void resetSignal(int sig) {
    gReset = true;
}
