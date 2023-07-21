//
//  BLEAdvertise.h
//  iBridgeLib
//
//  Created by qiuwenqing on 15/11/16.
//  Copyright © 2015年 BRT. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BLEAdvertisementData : NSObject

+ (id)bleAdvertisementDatWithDictionary:(NSDictionary *)dictionary;

/*!
 *  @constant CBAdvertisementDataLocalNameKey
 *
 *  @discussion A <code>NSString</code> containing the local name of a peripheral.
 *
 */
@property NSString *localName;


/*!
 *  @constant CBAdvertisementDataTxPowerLevelKey
 *
 *  @discussion A <code>NSNumber</code> containing the transmit power of a peripheral.
 *
 */
@property NSNumber *txPowerLevel;


/*!
 *  @constant CBAdvertisementDataServiceUUIDsKey
 *
 *  @discussion A list of one or more <code>CBUUID</code> objects, representing <code>CBService</code> UUIDs.
 *
 */
@property NSArray *serviceUUIDs;


/*!
 *  @constant CBAdvertisementDataServiceDataKey
 *
 *  @discussion A dictionary containing service-specific advertisement data. Keys are <code>CBUUID</code> objects, representing
 *              <code>CBService</code> UUIDs. Values are <code>NSData</code> objects.
 *
 */
@property NSDictionary *serviceData;


/*!
 *  @constant CBAdvertisementDataManufacturerDataKey
 *
 *  @discussion A <code>NSData</code> object containing the manufacturer data of a peripheral.
 *
 */
@property NSData *manufacturerData;


/*!
 *  @constant CBAdvertisementDataOverflowServiceUUIDsKey
 *
 *  @discussion A list of one or more <code>CBUUID</code> objects, representing <code>CBService</code> UUIDs that were
 *              found in the "overflow" area of the advertising data. Due to the nature of the data stored in this area,
 *              UUIDs listed here are "best effort" and may not always be accurate.
 *
 *  @see        startAdvertising:
 *
 */
@property NSArray *overflowServiceUUIDs NS_AVAILABLE(NA, 6_0);


/*!
 *  @constant CBAdvertisementDataIsConnectable
 *
 *  @discussion A NSNumber (Boolean) indicating whether or not the advertising event type was connectable. This can be used to determine
 *				whether or not a peripheral is connectable in that instant.
 *
 */
@property NSNumber *isConnectable NS_AVAILABLE(NA, 7_0);


/*!
 *  @constant CBAdvertisementDataSolicitedServiceUUIDsKey
 *
 *  @discussion A list of one or more <code>CBUUID</code> objects, representing <code>CBService</code> UUIDs.
 *
 */
@property NSArray *solicitedServiceUUIDs NS_AVAILABLE(NA, 7_0);

@end
