#include <CoreFoundation/CoreFoundation.h>
#include "IOKit/IOKitLib.h"
#include "IOKit/IOCFSerialize.h"

// from Apple's hdik and comex's attach

int main(int argc, char *argv[]) {
	
	if (argc != 2) {
		printf("Usage: hdik image.dmg\n");
		return -1;
	}

	char *real_path = realpath(argv[1], NULL);

	CFStringRef uuid = CFUUIDCreateString(kCFAllocatorDefault, CFUUIDCreate(NULL));
    CFMutableDictionaryRef dict = CFDictionaryCreateMutable(kCFAllocatorDefault, 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
	CFDataRef path = CFDataCreateWithBytesNoCopy(kCFAllocatorDefault, (const unsigned char *)real_path, strlen(real_path), kCFAllocatorNull);

	CFDictionarySetValue(dict, CFSTR("hdik-unique-identifier"), uuid);
	CFDictionarySetValue(dict, CFSTR("image-path"), path);

	CFDataRef data = CFPropertyListCreateData(kCFAllocatorDefault, dict, 0x64, 0, 0);

	io_service_t service = IOServiceGetMatchingService(kIOMasterPortDefault, IOServiceMatching("IOHDIXController"));
    io_connect_t connect;

	if (IOServiceOpen(service, mach_task_self(), 0, &connect)) {
		printf("IOServiceOpen failed.\n");
		return -1;
	}

	// comex's Attach-and-Detach
	struct HDIImageCreateBlock64 {
        uint64_t magic;
        char *props;
        uint64_t props_size;
        char ignored[0xf8 - 16];
    } stru;
	
    memset(&stru, 0, sizeof(stru));
    stru.magic = 0x1beeffeed;
    stru.props = (char *) CFDataGetBytePtr(data);
    stru.props_size = CFDataGetLength(data);

    uint32_t val;
    size_t val_size = sizeof(val);

	if (IOConnectCallStructMethod(connect, 0, &stru, sizeof(stru), &val, &val_size)) {
		printf("IOConnectCallStructMethod failed.\n");
		return -1;
	}

	CFRelease(dict);
	IOObjectRelease(service);
	if(connect) IOServiceClose(connect);

	return 0;
}
