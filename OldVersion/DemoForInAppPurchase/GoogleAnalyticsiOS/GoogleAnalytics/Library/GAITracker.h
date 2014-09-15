/*!
 @header    GAITracker.h
 @abstract  Google Analytics iOS SDK Tracker Header
 @version   3.0
 @copyright Copyright 2013 Google Inc. All rights reserved.
*/

#import <Foundation/Foundation.h>

/*!
 Google Analytics tracking interface. Obtain instances of this interface from
 [GAI trackerWithTrackingId:] to track screens, events, transactions, timing,
 and exceptions. The implementation of this interface is thread-safe, and no
 calls are expected to block or take a long time.  All network and disk activity
 will take place in the background.
 */
@protocol GAITracker<NSObject>

/*!
 Name of this tracker.
 */
@property(nonatomic, readonly) NSString *name;

/*!
 Set a tracking parameter.

 @param parameterName The parameter name.

 @param value The value to set for the parameter. If this is nil, the
 value for the parameter will be cleared.
 */
- (void)set:(NSString *)parameterName
      value:(NSString *)value;

/*!
 Get a tracking parameter.

 @param parameterName The parameter name.

 @returns The parameter value, or nil if no value for the given parameter is
 set.
 */
- (NSString *)get:(NSString *)parameterName;

/*!
 Queue tracking information with the given parameter values.

 @param parameters A map from parameter names to parameter values which will be
 set just for this piece of tracking information, or nil for none.
 */
- (void)send:(NSDictionary *)parameters;

/****************************************************************************************************/

/*!
 Track an event.
 
 If [GAI optOut] is true, this will not generate any tracking information.
 
 @param category The event category, or `nil` if none.
 
 @param action The event action, or `nil` if none.
 
 @param label The event label, or `nil` if none.
 
 @param value The event value, to be interpreted as a 64-bit signed integer, or
 `nil` if none.
 
 @return `YES` if the tracking information was queued for dispatch, or `NO` if
 there was an error (e.g. the tracker was closed).
 */
- (BOOL)trackEventWithCategory:(NSString *)category
                    withAction:(NSString *)action
                     withLabel:(NSString *)label
                     withValue:(NSNumber *)value;


/*!
 Track that the current screen (as set in appScreen) was displayed. If appScreen
 has not been set, this will not generate any tracking information.
 
 If [GAI optOut] is true, this will not generate any tracking information.
 
 @return `YES` if the tracking information was queued for dispatch, or `NO` if
 there was an error (e.g. the tracker was closed or appScreen is not set).
 */
- (BOOL)trackView;

/*!
 Track that the specified view or screen was displayed. This call sets
 the appScreen property and generates tracking information to be sent to Google
 Analytics.
 
 If [GAI optOut] is true, this will not generate any tracking information.
 
 @param screen The name of the screen. Must not be `nil`.
 
 @return `YES` if the tracking information was queued for dispatch, or `NO` if
 there was an error (e.g. the tracker was closed).
 */
- (BOOL)trackView:(NSString *)screen;

@end
