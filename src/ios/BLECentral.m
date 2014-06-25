
#import <Foundation/Foundation.h>

#import "BLECentral.h"

@implementation BLECentral

@synthesize delegate;
@synthesize centralManager;
@synthesize peripherals;
@synthesize activePeripheral;

static bool ready = false;
static int state = -1;


#pragma mark - UUID Retrieval


+ (CBUUID*)uartServiceUUID{
    
    return [CBUUID UUIDWithString:@"6e400001-b5a3-f393-e0a9-e50e24dcca9e"];
}

+ (CBUUID*)txCharacteristicUUID{
    
    return [CBUUID UUIDWithString:@"6e400002-b5a3-f393-e0a9-e50e24dcca9e"];
}

+ (CBUUID*)rxCharacteristicUUID{
    
    return [CBUUID UUIDWithString:@"6e400003-b5a3-f393-e0a9-e50e24dcca9e"];
}

+ (CBUUID*)deviceInformationServiceUUID{
    
    return [CBUUID UUIDWithString:@"180A"];
}

+ (CBUUID*)hardwareRevisionStringUUID{
    
    return [CBUUID UUIDWithString:@"2A27"];
}


#pragma mark - init

- (id)init {
  self = [super init];
  return self;
}

- (void)initCentral {
  self.centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
}

- (void)deinitCentral {
  [self.centralManager stopScan];
}



#pragma mark - Central Methods



/** centralManagerDidUpdateState is a required protocol method.
 *  Usually, you'd check for other states to make sure the current device supports LE, is powered on, etc.
 *  In this instance, we're just using it to wait for CBCentralManagerStatePoweredOn, which indicates
 *  the Central is ready to be used.
 */
- (void)centralManagerDidUpdateState:(CBCentralManager *)central {
    
    if (central.state != CBCentralManagerStatePoweredOn) {
        NSLog(@"CoreBluetooth not correctly initialized !");
        NSLog(@"State = %d (%s)\r\n", central.state, [self centralManagerStateToString:central.state]);
        ready = false;
        return;
    }
    
    // The state must be CBCentralManagerStatePoweredOn...
    
#if TARGET_OS_IPHONE
    NSLog(@"Status of CoreBluetooth central manager changed %d (%s)", central.state, [self centralManagerStateToString:central.state]);
#else
    [self isLECapableHardware];
#endif
    state = central.state;
    ready = true;
}


- (const char *) centralManagerStateToString: (int)_state
{
    switch(_state)
    {
        case CBCentralManagerStateUnknown:
            return "State unknown (CBCentralManagerStateUnknown)";
        case CBCentralManagerStateResetting:
            return "State resetting (CBCentralManagerStateUnknown)";
        case CBCentralManagerStateUnsupported:
            return "State BLE unsupported (CBCentralManagerStateResetting)";
        case CBCentralManagerStateUnauthorized:
            return "State unauthorized (CBCentralManagerStateUnauthorized)";
        case CBCentralManagerStatePoweredOff:
            return "State BLE powered off (CBCentralManagerStatePoweredOff)";
        case CBCentralManagerStatePoweredOn:
            return "State powered up and ready (CBCentralManagerStatePoweredOn)";
        default:
            return "State unknown";
    }
    
    return "Unknown state";
}

#if TARGET_OS_IPHONE
//-- no need for iOS
#else
- (BOOL) isLECapableHardware {
    
    NSString * state = nil;
    
    switch ([self.centralManager state])
    {
        case CBCentralManagerStateUnsupported:
            state = @"The platform/hardware doesn't support Bluetooth Low Energy.";
            break;
            
        case CBCentralManagerStateUnauthorized:
            state = @"The app is not authorized to use Bluetooth Low Energy.";
            break;
            
        case CBCentralManagerStatePoweredOff:
            state = @"Bluetooth is currently powered off.";
            break;
            
        case CBCentralManagerStatePoweredOn:
            return TRUE;
            
        case CBCentralManagerStateUnknown:
        default:
            return FALSE;
            
    }
    
    NSLog(@"Central manager state: %@", state);
    
    NSAlert *alert = [[NSAlert alloc] init];
    [alert setMessageText:state];
    [alert addButtonWithTitle:@"OK"];
    [alert setIcon:[[NSImage alloc] initWithContentsOfFile:@"AppIcon"]];
    [alert beginSheetModalForWindow:nil modalDelegate:self didEndSelector:nil contextInfo:nil];
    
    return FALSE;
}
#endif





- (void)startScan {
    
    NSLog(@"\n\nBLECentral::startScan\n\n");

  if (self.activePeripheral) {
    if(self.activePeripheral.isConnected) {
      [self.centralManager cancelPeripheralConnection:self.activePeripheral];
      return;
    }
  }

  if (self.peripherals) {
    self.peripherals = nil;
  }

  [self.centralManager scanForPeripheralsWithServices:nil   //@[[CBUUID UUIDWithString:@"0x2901"], [CBUUID UUIDWithString:@"0x2A3F"]]
                                              options:nil]; //@{ CBCentralManagerScanOptionAllowDuplicatesKey : @YES }];
}

- (void)stopScan {
  NSLog(@"\n\nBLECentral::stopScan\n\n");
  [self.centralManager stopScan];
}

- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI {
    
  if (peripheral.identifier == NULL) {
    NSLog(@"BLECentral::didDiscoverPeripheral -- peripheral.identifier not found");
    return;
  }
  
  NSLog(@"BLECentral::didDiscoverPeripheral -- %@ -- %@ -- (%ld)", peripheral.name, [peripheral.identifier UUIDString], (long)RSSI.integerValue);
  
  NSString* localName = [advertisementData objectForKey:@"kCBAdvDataLocalName"];

  NSDictionary* dic = [NSDictionary dictionaryWithObjectsAndKeys: peripheral.name, @"name", [peripheral.identifier UUIDString], @"uuid", localName, @"localname", nil];
  [[self delegate] didDiscoverPeripheral:dic];
  
  // [peripheral setAdvertisementData:advertisementData RSSI:RSSI];

  if (!self.peripherals) self.peripherals = [[NSMutableArray alloc] initWithObjects:peripheral,nil];
  else [self.peripherals addObject:peripheral];
}

- (void)connect:(NSString*)uuid {
  NSLog(@"BLECentral::connect -- %@", uuid);
  CBPeripheral *peripheral = [self getPeripheralByUUID:uuid];
  if(!peripheral) [[self delegate] didFailToConnect];
  else [self.centralManager connectPeripheral:peripheral options:nil];
}

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral {
  NSLog(@"BLECentral::didConnectPeripheral -- %@", peripheral.name);
  self.activePeripheral = peripheral;
  [self.activePeripheral setDelegate:self];
    
    [peripheral discoverServices:@[self.class.uartServiceUUID, self.class.deviceInformationServiceUUID]];
}

- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
  NSLog(@"BLECentral::didFailToConnectPeripheral -- %@", peripheral.name);
  [[self delegate] didFailToConnect];
}

- (void)disconnect {
  NSLog(@"BLECentral::disconnect");
  [self.centralManager cancelPeripheralConnection:activePeripheral];
  self.activePeripheral = nil;
}

- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
  NSLog(@"BLECentral::didDisconnectPeripheral");
  [[self delegate] didDisconnect];
}

- (void)peripheral:(CBPeripheral*)peripheral didDiscoverServices:(NSError*)error{
    
    NSLog(@"BLECentral::didDiscoverServices");
    
    if (!error) {
        
        for (CBService *s in [peripheral services]){
            
            if (s.characteristics){ //already discovered characteristic before, DO NOT do it again
                
                [self peripheral:peripheral didDiscoverCharacteristicsForService:s error:nil];
                
            } else if([s.UUID isEqual:self.class.uartServiceUUID]) {
                
                printf("UART service Found\r\n");
                uartService = s;
                [peripheral discoverCharacteristics:@[self.class.txCharacteristicUUID, self.class.rxCharacteristicUUID] forService:uartService];
                
            } else if([s.UUID isEqual:self.class.deviceInformationServiceUUID]) {

                [peripheral discoverCharacteristics:@[self.class.hardwareRevisionStringUUID] forService:s];
                
            }
        }
    } else{
        
        printf("Error discovering services\r\n");
//        [_delegate uartDidEncounterError:@"Error discovering services"];
        return;
    }
}

- (void)peripheral:(CBPeripheral*)peripheral didDiscoverCharacteristicsForService:(CBService*)service error:(NSError*)error{
    
    NSLog(@"BLECentral::didDiscoverCharacteristicsForService");
    
    if (!error){
        
        CBService *s = [peripheral.services objectAtIndex:(peripheral.services.count - 1)];
        
        if([s.UUID isEqual:service.UUID]) {
            
            for (CBService *s in peripheral.services) {
            
                for (CBCharacteristic *c in [s characteristics]){

                    if([c.UUID isEqual:self.class.rxCharacteristicUUID]) {
                        
                        printf("RX characteristic Found\r\n");
                        rxCharacteristic = c;
                        [self.activePeripheral setNotifyValue:YES forCharacteristic:rxCharacteristic];
                        
                    } else if([c.UUID isEqual:self.class.txCharacteristicUUID]) {
                        
                        printf("TX characteristic Found \r\n");
                        txCharacteristic = c;
                        
                    } else if([c.UUID isEqual:self.class.hardwareRevisionStringUUID]) {
                        
                        printf("Found Hardware Revision String characteristic\r\n");
//                        [peripheral readValueForCharacteristic:c];
                        //Once hardware revision string is read connection will be complete …
                    }
                }
            }
            
            NSDictionary* dic = [NSDictionary dictionaryWithObjectsAndKeys: self.activePeripheral.name, @"name", [self.activePeripheral.identifier UUIDString], @"uuid", nil];
            [[self delegate] didConnect:dic];

        }
    } else{
        
        printf("Error discovering characteristics: %s\r\n", [error.description UTF8String]);
//        [_delegate uartDidEncounterError:@"Error discovering characteristics"];
        return;
    }
}

- (void)peripheral:(CBPeripheral*)peripheral didUpdateValueForCharacteristic:(CBCharacteristic*)characteristic error:(NSError*)error{
    
    NSLog(@"BLECentral::didUpdateValueForCharacteristic");
    
    //Respond to value change on peripheral
    
    if (!error){
        if (characteristic == rxCharacteristic){
            
            NSLog(@"Received: %@", [characteristic value]);
            
            [self.delegate didReceiveData:[characteristic value]];
            
        }
    } else{
        printf("Error receiving notification for characteristic %s: %s\r\n", [characteristic.description UTF8String], [error.description UTF8String]);
//        [_delegate uartDidEncounterError:@"Error receiving notification for characteristic"];
        return;
    }
}

- (CBPeripheral*)getPeripheralByUUID:(NSString*)uuid {

  NSLog(@"BLECentral::getPeripheralByUUID -- %@", uuid);

  CBPeripheral *peripheral = nil;
  for (CBPeripheral *p in peripherals) {
    if ([uuid isEqualToString:p.identifier.UUIDString]) {
      peripheral = p;
      break;
    }
  }
  return peripheral;
}

- (void)writeRawData:(NSData*)data{
    
    //Send data to peripheral
    [self.activePeripheral writeValue:data forCharacteristic:txCharacteristic type:CBCharacteristicWriteWithoutResponse];
}



-(NSString *) CBUUIDToString:(CBUUID *)cbuuid {
  NSData *d = cbuuid.data;
  
  if ([d length] == 2) {
    const unsigned char *tokenBytes = [d bytes];
    return [NSString stringWithFormat:@"%02x%02x", tokenBytes[0], tokenBytes[1]];
  } else if ([d length] == 16) {
    NSUUID* nsuuid = [[NSUUID alloc] initWithUUIDBytes:[d bytes]];
    return [nsuuid UUIDString];
  }
  
  return [cbuuid description];
}

-(UInt16) swap:(UInt16)s {
  UInt16 temp = s << 8;
  temp |= (s >> 8);
  return temp;
}

-(int) compareCBUUID:(CBUUID *)UUID1 UUID2:(CBUUID *)UUID2 {   
  char b1[16];
  char b2[16];
  [UUID1.data getBytes:b1];
  [UUID2.data getBytes:b2];
  
  if (memcmp(b1, b2, UUID1.data.length) == 0) return 1;
  else return 0;
}

-(int) compareCBUUIDToInt:(CBUUID *)UUID1 UUID2:(UInt16)UUID2 {
  char b1[16];  
  [UUID1.data getBytes:b1];
  UInt16 b2 = [self swap:UUID2];
  
  if (memcmp(b1, (char *)&b2, 2) == 0) return 1;
  else return 0;
}

-(UInt16) CBUUIDToInt:(CBUUID *)UUID {
  char b1[16];
  [UUID.data getBytes:b1];
  return ((b1[0] << 8) | b1[1]);
}

-(CBUUID *) IntToCBUUID:(UInt16)UUID {
  char t[16];
  t[0] = ((UUID >> 8) & 0xff); t[1] = (UUID & 0xff);
  NSData *d = [[NSData alloc] initWithBytes:t length:16];
  return [CBUUID UUIDWithData:d];
}

- (BOOL) UUIDSAreEqual:(NSUUID *)UUID1 UUID2:(NSUUID *)UUID2 {  
  if ([UUID1.UUIDString isEqualToString:UUID2.UUIDString]) return TRUE;
  else return FALSE;
}

@end