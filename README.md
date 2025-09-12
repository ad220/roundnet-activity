# <p align="center"> <br/> <img src="doc/roundnetapp.png" alt="drawing" width="128"/> <br/> <br/> Roundnet Activity <br/> </p>
Roundnet activity tracker for Garmin smartwatches. Allows you to keep score so you don't forget the game's progress. Comes with customizable data records and fields, plus an alarm to remind you to switch sides every X rounds (soonTM).

## Features
- records heartrate, calories, steps, distance, temperatures and score
- customizable dynamic datafield
- custom datafields per point / per game
- shows up as roundnet activity in ConnectIQ

## Planned features
- switching side alarm
- cancel add point
- cancel new game
- interactive loop field
- better touchscreen support
- better large screen support (scale fonts)

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

### v0.1
- first version of the app
