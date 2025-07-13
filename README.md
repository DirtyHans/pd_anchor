# QB-Core Anchor Script with Dynamic QB-Target Support

## Features
- Drop and raise anchors on boats
- **Dynamic QB-Target integration** - labels update in real-time
- Command support for when not using target
- Job restrictions (optional)
- Configurable settings
- Works when in driver seat or near boat
- Real-time target option updates

## Installation
1. Place the script in your resources folder
2. Add `ensure pd_anchor` to your server.cfg
3. Configure the script in config.lua

## Usage
- **Command**: Use `/anchor` command when in driver seat or near a boat
- **QB-Target**: Look at a boat and use the target option to toggle anchor
- **Driver Seat**: When in driver seat, both command and target work (if enabled in config)

## Key Features
- **Dynamic Updates**: QB-Target options now update immediately when anchor state changes
- **Smart Targeting**: Only shows target options for relevant boats
- **State Tracking**: Properly tracks anchor state across all clients

## Configuration
Edit `config.lua` to customize:
- Command settings and job restrictions
- QB-Target settings and labels
- Notification messages
- Debug mode

## Key Settings
- `Config.Target.ShowWhenInDriverSeat`: Set to true to show target option when in driver seat
- `Config.Debug`: Enable debug prints for troubleshooting
- `Config.Target.Distance`: Interaction distance for QB-Target

## What's Fixed
- QB-Target options now update dynamically when anchor state changes
- "Drop Anchor" changes to "Raise Anchor" immediately after use
- Better target cleanup and management
- Improved state synchronization

## Troubleshooting
- Enable `Config.Debug = true` to see debug information in console
- Check that qb-target is properly installed and working
- Ensure you're close enough to the boat (within Config.Target.Distance)
