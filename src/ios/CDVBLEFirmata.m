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

typedef enum {
    kPinStateLow  = 0,
    kPinStateHigh,
} PinState;

typedef enum {
    kPinModeUnknown = -1,
    kPinModeInput,
    kPinModeOutput,
    kPinModeAnalog,
    kPinModePWM,
    kPinModeServo
} PinMode;


- (void)pluginInitialize {

    NSLog(@"-------------------------------------");
    NSLog(@" Bluetooth LE Firmata Cordova Plugin");
    NSLog(@" (c)2014 Jihyun Lee");
    NSLog(@"-------------------------------------");

    [super pluginInitialize];
    
    self.CM = [[BLECentral alloc] init];
    self.CM.delegate = self;
    [self.CM initCentral];

    portMasks[0] = 0;
    portMasks[1] = 0;
    portMasks[2] = 0;
}

- (void)sendData:(NSData*)newData{
    
    //Output data to UART peripheral
    
    NSString *hexString = [newData hexRepresentationWithSpaces:YES];
    NSLog(@"Sending: %@", hexString);
    
    // [currentPeripheral writeRawData:newData];
    
}

- (void)setDigitalStateReportingforPin:(int)digitalPin enabled:(BOOL)enabled{
    
    NSLog(@"CDVBLEFirmata::setDigitalStateReportingforPin");
    
    //Enable input/output for a digital pin
    
    //port 0: digital pins 0-7
    //port 1: digital pins 8-15
    //port 2: digital pins 16-23
    
    //find port for pin
    uint8_t port;
    uint8_t pin;
    
    //find pin for port
    if (digitalPin <= 7){       //Port 0 (aka port D)
        port = 0;
        pin = digitalPin;
    }
    
    else if (digitalPin <= 15){ //Port 1 (aka port B)
        port = 1;
        pin = digitalPin - 8;
    }
    
    else{                       //Port 2 (aka port C)
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

- (void)writePinMode:(PinMode)newMode forPin:(int)pin{
    
    NSLog(@"CDVBLEFirmata::writePinMode");
    
    //Set a pin's mode
    
    uint8_t data0 = 0xf4;        //Status byte == 244
    uint8_t data1 = pin;        //Pin#
    uint8_t data2 = newMode;    //Mode
    
    uint8_t bytes[3] = {data0, data1, data2};
    NSData *newData = [[NSData alloc ]initWithBytes:bytes length:3];
    
    [self sendData:newData];
}

- (void)setAnalogValueReportingforAnalogPin:(int)pin enabled:(BOOL)enabled{
    
    NSLog(@"CDVBLEFirmata::setAnalogValueReportingforAnalogPin");
    
    //Enable analog read for a pin
    
    //Enable by pin
    uint8_t data0 = 0xc0 + pin;          //start analog reporting for pin (192 + pin#)
    uint8_t data1 = (uint8_t)enabled;    //Enable
    uint8_t bytes[2] = {data0, data1};
    NSData *newData = [[NSData alloc ]initWithBytes:bytes length:2];
    
    [self sendData:newData];
}



#pragma mark - Cordova Plugin Methods

- (void)initPins:(CDVInvokedUrlCommand *)command {
    
    NSLog(@"CDVBLEFirmata::initPins");
    
    for (int pin = FIRST_DIGITAL_PIN; pin <= LAST_DIGITAL_PIN; pin++) {
        
        //Set all pin read reports
        [self setDigitalStateReportingforPin:pin enabled:YES];
    }
    for (int pin = FIRST_ANALOG_PIN; pin <= LAST_ANALOG_PIN; pin++) {
        
        //Set all pin read reports
        [self setDigitalStateReportingforPin:pin enabled:YES];
    }
    
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)pinMode:(CDVInvokedUrlCommand *)command {
    
    int pin = [[command.arguments objectAtIndex:0] intValue];
    NSString *mode = [command.arguments objectAtIndex:1];

    NSLog(@"CDVBLEFirmata::pinMode -- %d -- %@", pin, mode);
    
    PinMode pinMode = kPinModeUnknown;
    
    if ([mode compare:@"INPUT"] == NSOrderedSame) {
        pinMode = kPinModeInput;
    }
    else if ([mode compare:@"OUTPUT"] == NSOrderedSame) {
        pinMode = kPinModeOutput;
    }
    else if ([mode compare:@"ANALOG"] == NSOrderedSame) {
        pinMode = kPinModeAnalog;
    }
    else if ([mode compare:@"PWM"] == NSOrderedSame) {
        pinMode = kPinModePWM;
    }
    else if ([mode compare:@"SERVO"] == NSOrderedSame) {
        pinMode = kPinModeServo;
    }
    
    //Write pin
    [self writePinMode:pinMode forPin:pin];
    
    //Update reporting for Analog pins
    if (pinMode == kPinModeAnalog) {
        [self setAnalogValueReportingforAnalogPin:pin enabled:YES];
    }
    
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

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