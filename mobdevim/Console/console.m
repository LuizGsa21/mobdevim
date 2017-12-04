//
//  Console.m
//  mobdevim
//
//  Created by Derek Selander
//  Copyright © 2017 Selander. All rights reserved.
//

#import "console.h"
#import <sys/socket.h>

NSString *const kConsoleProcessName = @"com.selander.console.processname";

int console(AMDeviceRef d, NSDictionary* options) {

  AMDServiceConnectionRef connection = NULL;
  AMDeviceSecureStartService(d, @"com.apple.syslog_relay",
                                @{@"UnlockEscrowBag" : @YES},
                                &connection);
  
  
  int socket = (int)AMDServiceConnectionGetSocket(connection);
  AMDeviceStopSession(d);
  
  NSString *name = [options objectForKey:kConsoleProcessName];
  NSMutableString *bufferString = [NSMutableString string];
  while (1) {
    void *opt = NULL;
    socklen_t len = 0x8;
    char *buffer = calloc(1, len + 1);
    if (getsockopt(socket, SOL_SOCKET, SO_NREAD, &opt, &len) == 0) {
      AMDServiceConnectionReceive(connection, buffer, len);
      if (name) {
        [bufferString appendFormat:@"%s", buffer];
        if ( strstr(buffer, "\n\0")) {

          if ([bufferString containsString:name]) {
            dsprintf(stdout, "%s", [bufferString UTF8String]);
          }
          [bufferString setString:@""];
        }
      } else {
        dsprintf(stdout, "%s", buffer);
      }
      
    } else {
      dsprintf(stdout, "error, exiting\n");
      break;
    }
    free(buffer);
  }
  
  return 0;
}
