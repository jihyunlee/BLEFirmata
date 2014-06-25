Bluetooth LE Plugin for PhoneGap
=============

This is work in progress. **Everything may change."<br/>
If you encounter bugs, please let me know <a href="https://github.com/jihyunlee/BLEFirmata/issues">here</a>. Thank you!


## Support
iOS devices with Bluetooth 4.0 (iPhone 4S and later, iPad (3rd generation) and later, iPad Mini, iPod Touch (5th generation)

## Installation
    $ cordova plugin add https://github.com/jihyunlee/BLEFirmata.git

## Methods
#### startScan
    bleFirmata.startScan(successCallback, failureCallback);
#### stopScan
    bleFirmata.stopScan(successCallback, failureCallback);
#### connect
    bleFirmata.connect(uuid, successCallback, failureCallback);
#### disconnect
    bleFirmata.disconnect(successCallback, failureCallback);
#### initPins
    bleFirmata.initPins(successCallback, failureCallback);
#### pinMode
    bleFirmata.pinMode(pin, mode, successCallback, failureCallback);
#### digitalWrite
    bleFirmata.digitalWrite(pin, value, successCallback, failureCallback);
#### digitalRead
    bleFirmata.digitalRead(pin, successCallback, failureCallback);
#### analogRead
    bleFirmata.analogRead(pin, successCallback, failureCallback);
#### analogWrite
    bleFirmata.analogWrite(pin, value, successCallback, failureCallback);
