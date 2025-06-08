# Ti.PushWoosh ![platforms](https://img.shields.io/badge/platforms-Android%20%7C%20iOS-yellowgreen.svg)

Allows for the integration of [PushWoosh](https://www.pushwoosh.com/) notifications in Titanium applications.


## Requirements
- [x] Titanium SDK 12.7.0+

### PushWoosh Integration
#### iOS - [here](https://docs.pushwoosh.com/developer/pushwoosh-sdk/ios-sdk/setting-up-pushwoosh-ios-sdk/quick-start/)
#### Android - [here](https://docs.pushwoosh.com/developer/pushwoosh-sdk/android-sdk/firebase-integration/quick-start/)
#### API_TOKEN - [here](https://docs.pushwoosh.com/developer/api-reference/api-access-token/#device-api-token)


## Setup

Integrate the module into the `modules` folder and define them into the `tiapp.xml` file:

```xml
    <modules>
      <module platform="iphone">ti.pushwoosh</module>
      <module platform="android">ti.pushwoosh</module>
    </modules>
```
### Android
To use PushWoosh on Android devices, register some meta-data in the <b>Application</b> node of you Android <b>manifest</b> in Tiapp.xml :

```xml
	<meta-data  android:name="com.pushwoosh.appid"  android:value="[APP-ID]"/>
	<meta-data  android:name="com.pushwoosh.senderid"  android:value="[FCM-SENDER-ID]"/>
	<meta-data  android:name="com.pushwoosh.apitoken"  android:value="[API-KEY]"  />
```

[PushWoosh Android DOC](https://docs.pushwoosh.com/developer/first-steps/connect-messaging-services/configure-android-platform)

### iOS
To use PushWoosh on iOS devices, register some meta-data in the <b>plist</b> node in Tiapp.xml :

```xml
<ios>
	<plist>
		<dict>
			<key>aps-environment</key>
			<string>production</string> <!-- or development -->
			<key>UIBackgroundModes</key>
			<array>
				<string>remote-notification</string>
				<string>fetch</string>
			</array>
			<!--PushWoosh-->
			<key>Pushwoosh_APPID</key>
			<string>[APP-ID]</string>
			<key>Pushwoosh_API_TOKEN</key>
			<string>[API-KEY]</string>
			<key>PW_APP_GROUPS_NAME</key>
			<string>group.ti.pushwoosh</string>
		</dict>
	</plist>
</ios>
```

Also, you need to create/edit <b>Entitlements.plist</b> in the root of your project, alongside Tiapp.xml, with the following fields:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE  plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist  version="1.0">
	<dict>
		<key>aps-environment</key>
		<string>production</string> <!-- or development -->
		<!--PushWoosh-->
		<key>com.apple.security.application-groups</key>
		<array>
			<string>group.ti.pushwoosh</string>
		</array>
	</dict>
</plist>
```
[PushWoosh iOS DOC](https://docs.pushwoosh.com/developer/first-steps/connect-messaging-services/ios-configuration/)

NOTE: Your <b>aps-environment</b> must match you PushWoosh <b>gateway</b> when setting the p.8 key. [Doc here](https://docs.pushwoosh.com/developer/first-steps/connect-messaging-services/ios-configuration/ios-token-based-configuration/).

### Usage

#### In your app.js
1. Add the following require
	```xml
	require('ti.pushwoosh');
	```

#### Push Notification
1. Register device for Push Notifications

   ```js
   const pushwoosh = require('ti.pushwoosh');
   ```
2. You can request permission to use notifications:
   ```js
   mainWindow.addEventListener('open', ()=>{
	   if(Ti.Platform.osname != "android"){ // iOS only
		   PushWoosh.processPendingPushMessage(); // Check if the app opened from a notification click.
	   }
	   PushWoosh.registerForPushNotifications();
   }
   
   PushWoosh.addEventListener(PushWoosh.ON_REGISTER_SUCCESS, (pw)=>{
	   Ti.API.warn("PushWoosh.ON_REGISTER_SUCCESS!");
	   Ti.API.info("Token: " + pw.token);
   });
   
   PushWoosh.addEventListener(PushWoosh.ON_REGISTER_ERROR, (pw)=>{
	   Ti.API.error("PushWoosh.ON_REGISTER_ERROR!");
	   Ti.API.error(pw);
   });
   
   PushWoosh.addEventListener(PushWoosh.ON_MESSAGE_RECEIVED, (pw)=>{
	   Ti.API.warn("PushWoosh.ON_MESSAGE_RECEIVED");
	   Ti.API.info(pw);
   });
   
   PushWoosh.addEventListener(PushWoosh.ON_MESSAGE_OPENED, (pw)=>{
	   Ti.API.warn("PushWoosh.ON_MESSAGE_OPENED");
	   if(Ti.Platform.osname == "android"){
			if (pw?.message?.customData) {
				const  customData  =  JSON.parse(pw.message.customData);
			}
		} else { // iOS
			if (pw?.payload?.u) {
				const  customData  =  JSON.parse(pw.payload.u);
			}
		}
	});
   ```

## Methods

### `registerForPushNotifications()`
Registers current device for push notifications.
```js
PushWoosh.registerForPushNotifications();
```

### `setTags`
You can set specific tags for the device.
```js
pushwoosh.setTags({
	"name": "John",
	"age": 35,
	"logged_in": false,
	"ids": [
		"123abc",
		"456def",
		"789ghi"
	]
})
```

### `getTagValue`
```js
pushwoosh.getTagValue("name", (pw)=>{
	Ti.API.info(pw);
});
```

### `processPendingPushMessage` ( iOS only )
Check if the app opened from a notification click, and if so, fires the <b>ON_MESSAGE_OPENED</b> event.
```js
PushWoosh.processPendingPushMessage();
```

## `Events`

|Types                |Description
|----------------|-------------------------------|
|_ON_REGISTER_SUCCESS_	|Device registered successfully. You can get notifications now.
|_ON_REGISTER_ERROR_ 	|Device was not registered.
|_ON_MESSAGE_RECEIVED_	|When a push notification arrives. Works only in foreground.
|_ON_MESSAGE_OPENED_	|When the user clicks on notification.
|_ON_SET_TAG_SUCCESS_ 	|When the tag is saved successfully.
|_ON_SET_TAG_ERROR_		|Not possible to save the tag.
