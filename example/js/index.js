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
    app.startScan();
  },
  startScan: function() {
    console.log('\n\nstartScan ----------\n\n');

    var didDiscover = function(peripheral) {
      var name = '',
          uuid = '';
      if(peripheral.hasOwnProperty('localname')) name = peripheral.localname;
      if(peripheral.hasOwnProperty('uuid')) uuid = peripheral.uuid;

      console.log('didDiscover -- ', name, uuid);

      if(name == 'UART') {
        app.stopScan();
        app.connect(uuid);
      }
    };

    bleFirmata.startScan(didDiscover, function(err){console.log('startScan Failed');});
  },
  stopScan: function() {
    console.log('stopScan ----------\n\n');
    bleFirmata.stopScan(function(res){}, function(err){console.log('stopScan Failed');});
  },
  connect: function(uuid) {
    console.log('connect --- ');

    var didConnect = function(peripheral) {
      console.log('didConnect --- ', peripheral.name, peripheral.uuid);
      if(peripheral.uuid == uuid) {
        console.log('\n\nbox is connected\n\n');
      }
    };

    bleFirmata.connect(uuid, didConnect, function(err){console.log('connect Failed',uuid);});      
  }
};