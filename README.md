TWINGE (TWitch INtegration for Godot Engine) aims to simplify getting chat, redeems, and other streaming input into a Godot project by offering a class that streamlines the process of setting up OAuth and permission scopes.

I'll write more on how it's supposed to do that later.

## SETUP ##
*NOTE: You will first need to go through the steps of [Registering your App](https://dev.twitch.tv/docs/authentication/register-app/) to get a Client ID and Client Secret.*

Upon load, TWINGE should create a Project Settings section.

Put the created Client ID and Client Secret into their respective fields in this section.

The Encryption Key is used for local encryption of token data - It is recommended that you change this from the default.

## USAGE ##
An instance of Twinge should be created by dragging and dropping twinge.tscn into your project. 
*TWINGE was created with the intent that you may want to use multiple connections to the API (In much the way that some integration applications like StreamerBot allow you to have a main account and a bot account connected). Due to this, it cannot be used as an Autoload singleton directly.*