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
- (void)bleDidDiscoverServices;
- (void)bleDidDiscoverCharacteristic:(NSDictionary *)dic;
- (void)bleDidReadValueForCharacteristic:(NSDictionary *)dic;
- (void)bleDidWriteValueForCharacteristic;
@required
@end

@interface BLECentral : NSObject <CBCentralManagerDelegate, CBPeripheralDelegate> {
    NSString* _serviceUUID;
    NSString* _characteristicUUID;
}

@property (nonatomic,assign) id <BLECentralDelegate> delegate;
@property (strong, nonatomic) CBCentralManager      *centralManager;
@property (strong, nonatomic) NSMutableArray        *peripherals;
@property (strong, nonatomic) CBPeripheral          *activePeripheral;

- (void)initCentral;
- (void)deinitCentral;


// ready
- (void)centralManagerDidUpdateState:(CBCentralManager *)central;
- (BOOL)isReady;
- (int)getState;

// scan
- (void)startScan;
- (void)stopScan;

// peripheral
- (CBPeripheral*)getPeripheralByUUID:(NSString*)uuid;

// connect
- (void)connect:(NSString*)uuid;
- (void)disconnect;

// service
- (void)doDiscoverServiceByUUID:(NSString *)serviceUUID characteristicUUID:(NSString *)characteristicUUID;
- (void)doDiscoverServices:(CBPeripheral *)peripheral;
- (CBService *)doDiscoverServices:(CBPeripheral *)peripheral UUID:(NSString *)UUID;

// characteristic
- (void)doDiscoverCharacteristicsForService:(CBPeripheral *)peripheral service:(CBService *)service;
-(CBCharacteristic *) doDiscoverCharacteristic:(CBService*)service UUID:(NSString *)UUID;

- (void)doReadValueForCharacteristic:(NSString *)serviceUUID characteristicUUID:(NSString *)characteristicUUID;
- (void)doReadValueForCharacteristic:(CBPeripheral *)peripheral characteristic:(CBCharacteristic *)characteristic;

- (void)doWriteValueForCharacteristic:(NSString *)serviceUUID characteristicUUID:(NSString *)characteristicUUID data:(NSData *)data;
- (void)doWriteValueForCharacteristic:(CBUUID *)serviceUUID characteristicUUID:(CBUUID *)characteristicUUID peripheral:(CBPeripheral *)peripheral data:(NSData *)data;

- (void)cleanup;

- (UInt16)swap:(UInt16) s;
- (int)compareCBUUID:(CBUUID *) UUID1 UUID2:(CBUUID *)UUID2;
- (int)compareCBUUIDToInt:(CBUUID *) UUID1 UUID2:(UInt16)UUID2;
- (UInt16)CBUUIDToInt:(CBUUID *) UUID;
- (BOOL)UUIDSAreEqual:(NSUUID *)UUID1 UUID2:(NSUUID *)UUID2;

@end