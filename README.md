# Military FiveM Script

A comprehensive level-based military wave system for FiveM servers running OneSync Infinity.

## Features

- **Level-Based System**: Progressive difficulty with increasingly powerful enemy waves (4 levels currently implemented, supports up to 10)
- **Intelligent AI**: Enemy units actively hunt **players only** with advanced combat behavior
- **Map Blips**: All military units are marked on the map with red blips for easy tracking
- **Vehicle Combat**: Tanks and jets with functional weapons and chase AI
- **Instant Respawning**: Standard units (Levels 1, 2, 4) respawn immediately after destruction (Rhino tank respawns after 5 minutes)
- **Multi-player Support**: Set levels for yourself or other players
- **Custom Relationship Groups**: Military units fight players and are friendly to each other

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
- Is friendly to other military units
- Prevents friendly fire between spawned units

### Blips
All military units are marked on the map with red blips:
- **Crusaders** (Level 1): Red vehicle blips labeled "Military Crusader"
- **Barracks** (Level 2): Red vehicle blips labeled "Military Barracks"
- **Rhino Tank** (Level 3): Red vehicle blip labeled "Military Rhino Tank"
- **Lazer Jets** (Level 4): Red jet blips labeled "Military Lazer Jet"

### Respawn System
- **Standard Units** (Levels 1, 2, 4): Respawn immediately after death/destruction
- **Rhino Tank** (Level 3): Respawns 5 minutes after death/destruction
- Wreckage and dead bodies are removed after cleanup timer (1 minute for standard units, 5 minutes for Rhino)
- Units automatically respawn to maintain threat level

### AI Behavior
- Units actively seek and engage **players only** within range
- Units **ignore NPCs** (civilians, gangs, police, etc.)
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