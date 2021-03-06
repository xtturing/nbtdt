/*
 COPYRIGHT 2011 ESRI
 
 TRADE SECRETS: ESRI PROPRIETARY AND CONFIDENTIAL
 Unpublished material - all rights reserved under the
 Copyright Laws of the United States and applicable international
 laws, treaties, and conventions.
 
 For additional information, contact:
 Environmental Systems Research Institute, Inc.
 Attn: Contracts and Legal Services Department
 380 New York Street
 Redlands, California, 92373
 USA
 
 email: contracts@esri.com
 */

#import <Foundation/Foundation.h>
@class AGSWebMapFeatureCollection;
@class AGSPopupInfo;

/** @file AGSWebMapLayerInfo.h */ //Required for Globals API doc

/** @brief Information about top-level layers in a webmap
 
 Instances of this class represent information about top-level layers (such as map service layer, bing maps layer, openstreetmap layer, feature layer, feature collection, wms layer, etc) in the web map. 
 
 @since 2.2
 */
@interface AGSWebMapLayerInfo : NSObject <AGSCoding> {
@private
	NSString *_layerId;
    NSString *_itemId;
	NSString *_title;
	NSURL *_URL;
	float _opacity;
	NSString * _layerType;
	BOOL _visibility;
	AGSAuthenticationType _authType;
	BOOL _isReference;
	AGSWebMapFeatureCollection *_featureCollection;
	NSInteger _mode;
	AGSPopupInfo *_popupInfo;
	NSArray *_layers;
	NSArray *_visibleLayers;
	NSDictionary *_layerDefinition;
}

/** The id of the layer in the webmap.
 @since 2.2
 */
@property (nonatomic, retain, readonly) NSString *layerId;

/** The id of an item containing default information for the layer. The item resides on the same portal as the webmap.
 @since 2.2
 */
@property (nonatomic, retain, readonly) NSString *itemId;

/** The title of the layer in the webmap.
 @since 2.2
 */
@property (nonatomic, retain, readonly) NSString *title;

/** URL of the layer's backing service.
 @since 2.2
 */
@property (nonatomic, retain, readonly) NSURL *URL; 

/** If the value is 1, the layer is fully opaque. If 0, the layer is fully transparent.
 @since 2.2
 */
@property (nonatomic, readonly) float opacity;

/** The type of the layer. For example, OpenStreetMap, BingMapsAerial, BingMapsRoad, BingMapsHybrid, WMS, CSV, etc
 @since 2.2
 */
@property (nonatomic, retain, readonly) NSString *layerType;

/** Whether the layer is visible or not.
 @since 2.2
 */
@property (nonatomic, readonly) BOOL visibility;

/** If YES, then the layer should be drawn on top of all other layers in the web map. Else, it should be drawn
 based on the order it was stored in the web map. This property only applies to basemap layers, not to operational layers.
 @since 2.2
 */
@property (nonatomic, assign, readonly) BOOL isReference;

/** Only applicable if the layer is a feature collection. A feature collection is a representation of one or more feature layers, where each layer contains the definition of that layer and the features that belong to that layer.
 @since 2.2
 */
@property (nonatomic, retain, readonly) AGSWebMapFeatureCollection *featureCollection;

/** Only applies if the layer is a feature layer. A value of 0 implies @c AGSFeatureLayerModeSnapshot, 1 implies @c AGSFeatureLayerModeOnDemand, and 2 implies @c AGSFeatureLayerModeSelection. 
 @since 2.2
 */
@property (nonatomic, assign, readonly) NSInteger mode;

/** A popup definition for the layer.
 @since 2.2
 */
@property (nonatomic, retain, readonly) AGSPopupInfo *popupInfo;

/** An array of @c AGSWebMapSubLayerInfo objects representing the sublayers of the layer. 
 For example, if the layer is based on an ArcGIS map service. Each sublayer will have an id and optionally a popup definition.
 @since 2.2
 */
@property (nonatomic, retain, readonly) NSArray *layers;

/** An array of sub-layer ids that should be visible
 @since 2.2
 */
@property (nonatomic, retain, readonly) NSArray *visibleLayers;

/** Only applicable if the layer is a feature layer. This is the JSON returned by a Map or Feature Service for one of its layers, for example, http://sampleserver3.arcgisonline.com/ArcGIS/rest/services/SanFrancisco/311Incidents/FeatureServer/0?f=pjson. 
 @since 2.2
 */
@property (nonatomic, retain, readonly) NSDictionary *layerDefinition;

@end
