//
//  BLECentral.h
//
//  Created by jihyun on 3/19/14.
//
//

#import <CoreBluetooth/CoreBluetooth.h>

@class BLECentral;

@protocol BLECentralDelegate
@optional
- (void)didDiscoverPeripheral:(NSDictionary *)dic;
- (void)didConnect:(NSDictionary *)dic;
- (void)didFailToConnect;
- (void)didDisconnect;
@required
@end

@interface BLECentral : NSObject <CBCentralManagerDelegate, CBPeripheralDelegate> {
    NSString* _serviceUUID;
    NSString* _characteristicUUID;
    
    CBService *uartService;
    CBCharacteristic *rxCharacteristic;
    CBCharacteristic *txCharacteristic;
}

@property (nonatomic,assign) id <BLECentralDelegate> delegate;
@property (strong, nonatomic) CBCentralManager      *centralManager;
@property (strong, nonatomic) NSMutableArray        *peripherals;
@property (strong, nonatomic) CBPeripheral          *activePeripheral;

- (void)initCentral;
- (void)deinitCentral;


// ready
- (void)centralManagerDidUpdateState:(CBCentralManager *)central;

// scan
- (void)startScan;
- (void)stopScan;

// peripheral
- (CBPeripheral*)getPeripheralByUUID:(NSString*)uuid;

// connect
- (void)connect:(NSString*)uuid;
- (void)disconnect;

- (void)writeRawData:(NSData*)data;

- (UInt16)swap:(UInt16) s;
- (int)compareCBUUID:(CBUUID *) UUID1 UUID2:(CBUUID *)UUID2;
- (int)compareCBUUIDToInt:(CBUUID *) UUID1 UUID2:(UInt16)UUID2;
- (UInt16)CBUUIDToInt:(CBUUID *) UUID;
- (BOOL)UUIDSAreEqual:(NSUUID *)UUID1 UUID2:(NSUUID *)UUID2;

@end