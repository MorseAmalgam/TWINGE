TWINGE (TWitch INtegration for Godot Engine) aims to simplify getting chat, redeems, and other streaming input into a Godot project by offering a class that streamlines the process of setting up OAuth and permission scopes.

I'll write more on how it's supposed to do that later.

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
- **Chat**: Permission options for various chat-related features.
  - Allow Chat: 
  - Allow Whisper:
  - Allow Shoutout:
  - Allow Announcements:
- **Follows**: ***INCOMPLETE*** Uses ``moderator:read:followers`` to get follower metrics and listen to new follower events. No permission dropdowns as it only implements a single scope, with no Manage level.
- **Monetization**: Creates event listeners and endpoints for all Twitch features that involve monetization (Ads, Subscribers, Bit cheers, Hype Trains)
  - Allow Ads:
  - Allow Bits:
  - Allow Subscriptions:
  - Allow Hype Trains:
- **Moderation**: ***INCOMPLETE*** Endpoints and event listeners for moderation tools. Bans, unbans, suspicious activity notifications, etc.
- **Polls / Predictions**:
  - Allow Polls:
  - Allow Predictions:
- **Raids**: Uses ``channel:manage:raids`` to start and cancel raiding other channels, and listens to the channel.raid event (This does not require a permission scope).
- **Redeems**:
	- Allow Redeems:

#### Third Party Integrations ###
All modules in this section do not directly communicate with Twitch, but use data (namely the broadcaster and user names/IDs) to cross-reference information.

- Alejo Pronouns: Automatically enrich user objects with their chosen pronouns, if they have set them at https://pronouns.alejo.io/.
- SGarner Heat: Listens for interactions from the Heat Twitch extension to capture clicks on the stream area.

## Known Issues ##
Not all modules and endpoints are currently fully implemented. 

There exists a short list of endpoints that I have no plans to implement solely because I don't see a 'safe' use case for them.

But I lost them :)