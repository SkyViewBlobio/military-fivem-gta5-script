# Military FiveM Script

A comprehensive level-based military wave system for FiveM servers running OneSync Infinity.

## Features

- **10-Level System**: Progressive difficulty with increasingly powerful enemy waves
- **Intelligent AI**: Enemy units actively hunt players and NPCs with advanced combat behavior
- **Vehicle Combat**: Tanks and jets with functional weapons and chase AI
- **Automatic Respawning**: Units respawn after being destroyed (1 minute for most, 5 minutes for tanks)
- **Multi-player Support**: Set levels for yourself or other players
- **Custom Relationship Groups**: Military units fight everyone except each other

## Installation

1. Clone or download this repository
2. Place the `military-fivem-gta5-script` folder in your server's `resources` directory
3. Add `ensure military-fivem-gta5-script` to your `server.cfg`
4. Restart your server

## Usage

### Commands

#### Set Your Own Level
```
/level <1-10>
```
Example: `/level 3` - Activates military waves up to level 3

#### Set Another Player's Level
```
/level <playername> <1-10>
```
Example: `/level John 5` - Sets John's level to 5

**Note**: Setting the same level multiple times won't spawn duplicate units. Levels stack, so level 3 includes units from levels 1, 2, and 3.

## Level Breakdown

### Level 1: Ground Assault
- **4 Crusader vehicles**
- 2 soldiers per vehicle (s_m_m_chemsec_01)
- Armed with muskets and precision rifles
- Patrols and engages on sight

### Level 2: Heavy Infantry
- **2 Barracks transports**
- 4 soldiers per vehicle (s_m_m_chemsec_01)
- Armed with muskets
- Aggressive ground assault tactics

### Level 3: Armored Division
- **1 Rhino Tank**
- Juggernaut driver (u_m_y_juggernaut_01)
  - 2000 HP, heavy armor
  - Armed with Gusenberg Sweeper
- Spawns 1000m away from player
- Uses tank cannon in combat
- Actively chases targets
- **Special**: 5-minute respawn timer (instead of 1 minute)

### Level 4: Air Superiority
- **2 Lazer Fighter Jets**
- Pilot (s_m_m_chemsec_01)
- Armed with rockets and cannons
- Advanced aerial combat AI
- Hunts from the sky

## Technical Details

### Relationship Groups
Military units use a custom relationship group (`MILITARY_ENEMY`) that:
- Is hostile to all players
- Is hostile to all NPCs (civilians, gangs, police, etc.)
- Is friendly to other military units
- Prevents friendly fire between spawned units

### Respawn System
- **Standard Units** (Levels 1, 2, 4): Respawn 1 minute after death/destruction
- **Rhino Tank** (Level 3): Respawns 5 minutes after death/destruction
- Wreckage is removed after cleanup timer expires
- Units automatically respawn to maintain threat level

### AI Behavior
- Units actively seek and engage players within range
- Units also attack nearby NPCs (except other military units)
- Tank uses vehicle chase AI and cannon weapons
- Jets use plane mission AI with rockets and strafing runs
- All units have enhanced combat attributes and accuracy

### OneSync Compatibility
- All entities are properly set as mission entities
- Fully compatible with OneSync Infinity
- Supports multiplayer synchronization
- Each player can have their own level independently

## Requirements

- FiveM Server
- OneSync Infinity enabled
- GTA V game build (all standard vehicles and peds included)

## Troubleshooting

**Units not spawning?**
- Check server console for error messages
- Ensure OneSync is enabled
- Verify models are valid for your game version

**Units not attacking?**
- This is expected behavior if no targets are nearby
- Units have a detection range and will patrol until they find targets

**Performance issues?**
- Lower the active level
- Consider reducing respawn frequency in `client.lua` (Config.RESPAWN_CHECK_INTERVAL)

## Credits

Developed for FiveM military roleplay servers.

## License

This project is open source and available for modification.