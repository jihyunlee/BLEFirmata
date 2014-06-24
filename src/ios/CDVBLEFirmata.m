//
//  CDVBLEFirmata.m
//  Bluetooth LE Cordova Plugin
//
//  Created by jihyun on 6/24/14.
//
//

#import "CDVBLEFirmata.h"

@interface CDVBLEFirmata()
@end

@implementation CDVBLEFirmata

@synthesize delegate;
@synthesize CM;


- (void)pluginInitialize {

    NSLog(@"------------------------------");
    NSLog(@" Bluetooth LE Cordova Plugin");
    NSLog(@" (c)2014 Jihyun Lee");
    NSLog(@"------------------------------");

    [super pluginInitialize];
    
    self.CM = [[BLECentral alloc] init];
    self.CM.delegate = self;
    [self.CM initCentral];

    portMasks[0] = 0;
    portMasks[1] = 0;
    portMasks[2] = 0;
}

#pragma mark - Cordova Plugin Methods

- (void)startScan:(CDVInvokedUrlCommand*)command {
    
    NSLog(@"CDVBLEFirmata::startScan");
    
    _scanCallbackId = [command.callbackId copy];

    [CM startScan];
    
    CDVPluginResult *pluginResult = nil;
    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_NO_RESULT];
    [pluginResult setKeepCallbackAsBool:TRUE];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)stopScan:(CDVInvokedUrlCommand*)command {
    
    NSLog(@"CDVBLEFirmata::stopScan");
    
    _scanCallbackId = nil;
    
    [CM stopScan];

    CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)connect:(CDVInvokedUrlCommand *)command {
    
    NSString *uuid = [command.arguments objectAtIndex:0];
    NSLog(@"CDVBLEFirmata::connect -- %@", uuid);
    
    _connectCallbackId = [command.callbackId copy];
    
    // if the uuid is null or blank, scan and
    // connect to the first available device
    
    if (uuid == (NSString*)[NSNull null]) {
        //            [self connectToFirstDevice];
    } else if ([uuid isEqualToString:@""]) {
        //            [self connectToFirstDevice];
    } else {
        [CM connect:uuid];
    }
}

- (void)disconnect:(CDVInvokedUrlCommand*)command {
    
    NSLog(@"CDVBLEFirmata::disconnect");
    
    _connectCallbackId = [command.callbackId copy];
    
    [self.CM disconnect];
}



#pragma mark - BLEDelegate 

- (void)didDiscoverPeripheral:(NSDictionary *)dic {
    
    NSLog(@"BLEDelegate::didDiscoverPeripheral");
    
    if(_scanCallbackId) {
        CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:dic];
        [pluginResult setKeepCallbackAsBool:TRUE];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:_scanCallbackId];
    } else {
        NSLog(@"_scanCallbackId not found");
    }
}

- (void)didConnect:(NSDictionary *)dic {

    NSLog(@"BLEDelegate::didConnect");
    
    if (_connectCallbackId) {
        CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:dic];
        [pluginResult setKeepCallbackAsBool:TRUE];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:_connectCallbackId];
    } else {
        NSLog(@"_connectCallbackId not found");
    }
}

- (void)didFailToConnect {
  NSLog(@"BLEDelegate::didFailToConnect");
  CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"uuid not found"];
  [self.commandDelegate sendPluginResult:pluginResult callbackId:_connectCallbackId];
  _connectCallbackId = nil;
}

- (void)didDisconnect {
    
    NSLog(@"BLEDelegate::didDisconnect");
    
    if(_connectCallbackId) {
        CDVPluginResult *pluginResult = nil;
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:_connectCallbackId];
        
        _connectCallbackId = nil;
    } else {
        NSLog(@"_connectCallbackId not found");
    }
}

@end