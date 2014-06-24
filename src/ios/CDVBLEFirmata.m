//
//  CDVBLEFirmata.m
//  Bluetooth LE Cordova Plugin
//
//  Created by jihyun on 6/24/14.
//
//

#import "CDVBLEFirmata.h"
#import "NSData+hex.h"

@interface CDVBLEFirmata()
@end

@implementation CDVBLEFirmata

@synthesize delegate;
@synthesize CM;


- (void)pluginInitialize {

    NSLog(@"------------------------------");
    NSLog(@" Bluetooth LE Firmata Cordova Plugin");
    NSLog(@" (c)2014 Jihyun Lee");
    NSLog(@"------------------------------");

    [super pluginInitialize];
    
    self.CM = [[BLECentral alloc] init];
    self.CM.delegate = self;
    [self.CM initCentral];

    portMasks[0] = 0;
    portMasks[1] = 0;
    portMasks[2] = 0;

    for (int pin = FIRST_DIGITAL_PIN; pin <= LAST_DIGITAL_PIN; pin++) {
        [self setupPinmode:pin enabled:YES];
    }
    for (int pin = FIRST_ANALOG_PIN; pin <= LAST_ANALOG_PIN; pin++) {
        [self setupPinmode:pin enabled:YES];
    }
}

- (void)setupPinmode:(int)digitalPin enabled:(BOOL)enabled{

    //Enable input/output for a digital pin
    
    //port 0: digital pins 0-7
    //port 1: digital pins 8-15
    //port 2: digital pins 16-23

    //find port for pin
    uint8_t port;
    uint8_t pin;
    
    //find pin for port
    if (digitalPin <= 7){           //Port 0 (aka port D)
        port = 0;
        pin = digitalPin;
    } else if (digitalPin <= 15){   //Port 1 (aka port B)
        port = 1;
        pin = digitalPin - 8;
    } else{                         //Port 2 (aka port C)
        port = 2;
        pin = digitalPin - 16;
    }
    
    uint8_t data0 = 0xd0 + port;        //start port 0 digital reporting (0xd0 + port#)
    uint8_t data1 = portMasks[port];    //retrieve saved pin mask for port;
    
    if (enabled)
        data1 |= (1<<pin);
    else
        data1 ^= (1<<pin);
    
    uint8_t bytes[2] = {data0, data1};
    NSData *newData = [[NSData alloc ]initWithBytes:bytes length:2];
    
    portMasks[port] = data1;    //save new pin mask
    
    [self sendData:newData];
}

- (void)sendData:(NSData*)newData{
    
    //Output data to UART peripheral
    
    NSString *hexString = [newData hexRepresentationWithSpaces:YES];
    NSLog(@"Sending: %@", hexString);
    
    [currentPeripheral writeRawData:newData];
    
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