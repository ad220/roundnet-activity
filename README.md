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

## Screenshots
![](doc/start_menu.png)
![](doc/activity_view.png)

## Installation
The app is available on the [Garmin Connect IQ Store](https://apps.garmin.com/fr-FR/apps/25832203-f7ed-40a7-977d-0a9172b68ee4).

You can also build it from source for your specific device with the VSCode extension. This process is described [here](https://developer.garmin.com/connect-iq/connect-iq-basics/getting-started/) and [here](https://developer.garmin.com/connect-iq/connect-iq-basics/your-first-app/#ariaid-title7).

## Getting started
When starting the app, you get a menu similar to Garmin's native activity starting screen. Pressing the start button will start the activity, pressing the "menu" button will open the settings (on touchscreen devices, it's usually a long press or a down swipe).

### Settings
The app allows you to customize a few things:

- Sensors -- enable sensors for the activity recording
    * Toggle location (GPS)
    * Toggle temperature

- Datafield -- settings for the dynamic datafield
    - Fields -- enable or disable distance, calories, score, daytime and temperature datafields

    - Scrolling -- define dynamic field scrolling behavior
        * Toggle Auto Scroll
            + enables the datafield to automatically skip to the next data regularly
        * Set auto scroll speed
            + very fast: 1s, fast: 3s, normal: 5s, slow: 7s, very slow: 11s ; defaults to normal
        * Toggle Swipe Scroll
            + allows the dynamic field to be scrolled using a left or right swipe on touchscreen devices.

- Game Settings -- settings for score based app-behaviour
    * Toggle auto win / loose
        + enables the app to automatically ends a game when the target score is reached by one of the two teams.
    * Toggle two points difference
        + checks if a team is 2 points ahead of its opponents to win
    * Set points to win game
        + set the target score to a number between 5 and 51, defaults to 21
    * Toggle rotate start positions alarm
        + enables an alarm reminding you to rotate starting positions every X points
    * Set points to rotate
        + set the number of points to play between each start position rotation, between 3 and 10, defaults to 5

* Set double click speed
    + very fast: 160ms, fast: 240ms, normal: 320ms, slow: 400ms, very slow: 560ms 

### Activity

On the activity view, you have the timer, the score, the dynamic field and the heartrate field. Pressing the up button will increase your opponent's score in grey and pressing the down button will increase yours in yellow. If enabled in the settings, swipping left or right on touchscreen devices will skip to the next or previous data in the dynamic field.Pressing the lap button will save the game state to the activity file and start a new one. Press the start button to stop the activity and save or discard it.

## Changelog

### v0.8:
- fix adding game won/lost on draw
- fix mean time and distance per point data

### v0.7:
- fix crash on older devices and on watches that can't vibrate or play a sound
- performance fixes

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
