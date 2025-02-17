TWINGE (TWitch INtegration for Godot Engine) aims to simplify getting chat, redeems, and other streaming input into a Godot project by offering a class that streamlines the process of setting up OAuth and permission scopes.

This project started off as a fork of Erodozer's https://github.com/erodozer/tmi.gd and the bones of tmi.gd still reside in some of the core classes. Much of TWINGE would not be as complete as it is currently without Erodozer's work, both on tmi and from input and thoughts provided personally.

Documentation primarily exists at https://github.com/MorseAmalgam/TWINGE/wiki.

## SETUP ##
*NOTE: You will first need to go through the steps of [Registering Your App](https://dev.twitch.tv/docs/authentication/register-app/) to get a Client ID and Client Secret.*

Upon load, TWINGE should create a section in your Project Settings.

Put the created Client ID and Client Secret into their respective fields in this section.

The Encryption Key is used for local encryption of token data - It is recommended that you change this from the default.

## USAGE ##
An instance of Twinge should be created by dragging and dropping twinge.tscn into your project. 

*TWINGE was created with the intent that you may want to use multiple connections to the API (In much the way that some integration applications like StreamerBot allow you to have a main account and a bot account connected). Due to this, it cannot be used as an Autoload singleton directly.*

While TWINGE has a limited set of built-in functions, most functionality comes from adding modules to an instance. Modules should be added as child nodes to the TWINGE instance. Each module has a set of dropdowns to define what you want to implement from it.

### Modules ###
Check [the wiki](https://github.com/MorseAmalgam/TWINGE/wiki/Core-Modules) for a full explanation of each module's settings and what endpoints/events it implements.
- **Chat**: Chat, Whispers, Shoutouts and Announcements.
- **Follows**: Follower events.
- **Moderation**: Bans, unbans, suspicious activity notifications, etc.
- **Monetization**: All Twitch features that involve monetization (Ads, Subscribers, Bit cheers, Hype Trains)
- **Polls / Predictions**: Polls and Predictions.
- **Raids**: Raid in events and raid out commands.
- **Redeems**: Manages redeems and monitors redemptions.
- **Stream Info**: Details about the stream (I.E. Current title and game) and the streamer account (I.E. Who they are following)

#### Third Party Integrations ###
All modules in this section do not directly communicate with Twitch, but use data (namely the broadcaster and user names/IDs) to cross-reference information.

- Alejo Pronouns: Automatically enrich user objects with their chosen pronouns, if they have set them at https://pronouns.alejo.io/.
- SGarner Heat: Listens for interactions from the Heat Twitch extension to capture clicks on the stream area.
- Better Twitch TV?
- 7TV?
- FrankerFaceZ?

## Known Issues ##
Not all modules and endpoints are currently fully implemented.

The current system doesn't have good support for handling emoji in messages. tmi.gd implements imagemagick to handle emoji *and* animated emoji, both of which sound useful to have.

There exists a short list of scopes/endpoints that I have no plans to implement solely because I don't see a 'safe' use case for them, but the list has been lost in computer shuffles over the development of the plugin up to this point.