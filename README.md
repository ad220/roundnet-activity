# <p align="center"> <br/> <img src="doc/roundnetapp.png" alt="roundnet icon" width="128"/> <br/> <br/> Roundnet Activity <br/> </p>
Roundnet activity tracker for Garmin smartwatches. Allows you to keep score so you don't forget the game's progress. Comes with customizable data records and fields, plus an alarm to remind you to switch sides every X rounds.

## Features
- records score, heartrate, calories, steps, distance and temperature
- customizable dynamic datafield
- shows up as roundnet activity in Garmin Connect
- custom datafields per point and per game in activity summary / details
- alarm to rotate starting positions every X rounds

## Planned features
- better large screen support (scalable fonts)
- custom activity summary
- service position helper

## Installation
The app is available on the [Garmin Connect IQ Store](https://apps.garmin.com/fr-FR/apps/25832203-f7ed-40a7-977d-0a9172b68ee4).

You can also build it from source for your specific device with the VSCode extension. This process is described [here](https://developer.garmin.com/connect-iq/connect-iq-basics/getting-started/) and [here](https://developer.garmin.com/connect-iq/connect-iq-basics/your-first-app/#ariaid-title7).

## Getting started
When starting the app, you get a menu similar to Garmin's native activity starting screen. Pressing the start button will start the activity, pressing the "menu" button will open the settings (on touchscreen devices, it's usually a long press or a down swipe).

The settings menu lets you configure which data you want to see in the app's dynamic field and which sensor you wish to enable for the activity.

On the activity view, from top to bottom you have the timer, the dynamic field and the heartrate field. Pressing the up button will increase your opponent's score in grey and pressing the down button will increase yours in yellow. Pressing the lap button will save the game state to the activity file and start a new one. 

## Screenshots
![](doc/start_menu.png)
![](doc/activity_view.png)

## Changelog

### v0.6:
- fix menu labels overflow
- fix battery drain
- handle session not starting

### v0.5:
- add configurable rotate starting positons alarm
- add configurable auto win/loose

### v0.4:
- add configurable double click speed, datafield auto scrolling, swipe scrolling and scrolling speed
- fix crash on physical vivoactive3 when restarting a new game

### v0.3:
- add confirmation screen when restarting a new game
- add dynamic field interaction on swipe for touchscreen devices
- add vibrating feedback on input
- enable decrementing score with double press
- fix touchscreen behaviour for venu and vivoactive series

### v0.2:
- improve ui behaviour for touchscreen devices
- fix game (lap) stats not showing up in Garmin Connect
- remove compatibility for 2-color screen devices

### v0.1
- first version of the app
