//
//  CDVBLEFirmata.h
//  Bluetooth LE Cordova Plugin
//
//  Created by jihyun on 6/24/14.
//
//

#ifndef CDVBLEFirmata_h
#define CDVBLEFirmata_h

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <Cordova/CDVPlugin.h>
#import <CoreBluetooth/CoreBluetooth.h>

#import "BLECentral.h"

#define PORT_COUNT 3

@class CDVBLEFirmata;

@protocol BLEFirmataDelegate
@end

@interface CDVBLEFirmata : CDVPlugin <BLECentralDelegate> {
    NSString* _scanCallbackId;
    NSString* _connectCallbackId;
    uint8_t portMasks[PORT_COUNT];   //port # as index
}

@property (nonatomic,assign) id <BLEFirmataDelegate> delegate;
@property (strong, nonatomic) BLECentral *CM;

- (void)startScan:(CDVInvokedUrlCommand*)command;
- (void)stopScan:(CDVInvokedUrlCommand*)command;

- (void)connect:(CDVInvokedUrlCommand *)command;
- (void)disconnect:(CDVInvokedUrlCommand *)command;

@end

#endif