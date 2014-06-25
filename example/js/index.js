/*
 * Licensed to the Apache Software Foundation (ASF) under one
 * or more contributor license agreements.  See the NOTICE file
 * distributed with this work for additional information
 * regarding copyright ownership.  The ASF licenses this file
 * to you under the Apache License, Version 2.0 (the
 * "License"); you may not use this file except in compliance
 * with the License.  You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied.  See the License for the
 * specific language governing permissions and limitations
 * under the License.
 */

var bleFirmata;

var HIGH = 1;
var LOW = 0;
var LED_PIN = 4;
var SWITCH_PIN = 5;

var app = {
    
    initialize: function() {
        this.bindEvents();
    },
    bindEvents: function() {
        document.addEventListener('deviceready', this.onDeviceReady, false);
    },
    onDeviceReady: function() {
        
        if(window.cordova.logger) window.cordova.logger.__onDeviceReady();
        
        bleFirmata = new BLEFirmata();
        
        $('#myonoffswitch').click(function() {
            if($('#myonoffswitch').prop('checked'))
                 bleFirmata.digitalWrite(LED_PIN, HIGH);
            else bleFirmata.digitalWrite(LED_PIN, LOW);
        });
        
        app.startScan();
    },
    startScan: function() {

        var didDiscover = function(peripheral) {
            var name = '',
                uuid = '';
            if(peripheral.hasOwnProperty('localname')) name = peripheral.localname;
            if(peripheral.hasOwnProperty('uuid')) uuid = peripheral.uuid;
                        
            if(name == 'UART') {
                app.stopScan();
                app.connect(uuid);
            }
        };
        
        bleFirmata.startScan(didDiscover, function(err){console.log('startScan Failed');});
    },
    stopScan: function() {

        bleFirmata.stopScan(function(res){}, function(err){console.log('stopScan Failed');});
    },
    connect: function(uuid) {  

        var didConnect = function(peripheral) {
            if(peripheral.uuid == uuid) {
                console.log('\n\nconnected\n\n');
            }
            app.setup();
        };
        
        bleFirmata.connect(uuid, didConnect, function(err){console.log('connect Failed',uuid);});
    },
    disconnect: function() {

        var didDisconnect = function() {
        };
        bleFirmata.disconnect(didDisconnect, function(err){console.log('disconnect Failed');});
    },
    setup: function() {

        var didsetupSwitch = function() {
            app.loop();
        };
        
        var didSetupPins = function() {
            bleFirmata.pinMode(SWITCH_PIN, 'INPUT', didsetupSwitch, function(err){console.log('pinMode Failed');});
        };
        
        var didInit = function() {
            bleFirmata.pinMode(LED_PIN, 'OUTPUT', didSetupPins, function(err){console.log('pinMode Failed');});
        };

        bleFirmata.initPins(didInit, function(err){console.log('initPins Failed');});
    },
    loop: function() {

        var toggleLED = function() {
            app.loop();
        };
        var readSwitch = function(value) {
            value = parseInt(value);
            if(value != LOW && value != HIGH) {
                console.log('invalid value');
                app.loop();
                return;
            }
            
            bleFirmata.digitalWrite(LED_PIN, value, toggleLED);
        };
        
        bleFirmata.digitalRead(SWITCH_PIN, readSwitch, function(err){console.log('readSwitch Failed');});
    }
};