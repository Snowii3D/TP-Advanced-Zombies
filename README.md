# Snowii Advanced Zombies

An advanced FiveM zombies script that provides a realistic zombie apocalypse experience with dynamic features and immersive gameplay.

## Features

- 🧟‍♂️ Dynamic Zombie System
  - Multiple zombie types (Regular, Stronger, Runner, On-Fire, Gas)
  - Custom zombie behaviors and animations
  - Configurable health and damage settings
  - Headshot system with insta-kill option

- 🗺️ Zone System
  - Redzones: High-difficulty areas with increased zombie spawns
  - Firezones: Areas where zombies are set on fire
  - Safezones: Protected areas where zombies are removed
  - Configurable zone properties and limits

- 🚗 Vehicle System
  - Parked vehicle density control
  - Vehicle damage from zombies
  - Player damage while in vehicles
  - Configurable damage settings

- 🔊 Sound System
  - Support for xsound and sounity
  - 3D sound effects for zombies
  - Sound-based zombie attraction
  - Configurable volume and distance

- 🎮 Gameplay Features
  - Dynamic zombie spawning
  - Custom loot system
  - Player statistics tracking
  - Framework support (ESX, QBCore, Standalone)

## Requirements

- FiveM Server
- OneSync (Recommended)
- One of the following sound systems:
  - xsound
  - sounity
- One of the following frameworks (optional):
  - ESX
  - QBCore

## Installation

1. Download the latest release
2. Extract the files to your resources folder
3. Add `ensure snowii_advanced-zombies` to your server.cfg
4. Import the SQL file if using ESX or QBCore
5. Configure the script in `config.lua`

## Configuration

### Basic Setup

1. Open `config.lua`
2. Set your framework:
```lua
Config.Framework = "ESX" -- or "QBCore" or "Standalone"
```

3. Configure sound system:
```lua
Config.SoundSystem = {
    Enabled = true,
    Type = "xsound", -- or "sounity"
    Volume = 0.5,
    MaxDistance = 50.0
}
```

### Zone Setup

1. Configure Redzones:
```lua
Config.RedZones = {
    Enabled = true,
    Zones = {
        Downtown = {
            Pos = {x = 0.0, y = 0.0, z = 0.0},
            Radius = 100.0,
            ZombieLimit = 20,
            SpawnDistance = 50.0,
            Models = {"u_m_m_prolsec_01", "a_m_m_hillbilly_01"},
            SpawnRate = 1000
        }
    }
}
```

2. Configure Firezones:
```lua
Config.FireZones = {
    Enabled = true,
    Zones = {
        Downtown = {
            Pos = {x = 0.0, y = 0.0, z = 0.0},
            Radius = 50.0,
            DamagePerSecond = 10
        }
    }
}
```

3. Configure Safezones:
```lua
Config.SafeZones = {
    Enabled = true,
    AllowZombieSpawning = false,
    Zones = {
        -- Add your safe zones here
    }
}
```

### Zombie Types

Configure special zombie types in `Config.ZombieTypes`:
```lua
Config.ZombieTypes = {
    Regular = {
        Enabled = true,
        Health = 200,
        Damage = 15,
        Speed = 1.0
    },
    Stronger = {
        Enabled = true,
        Models = {
            {model = "a_m_o_acult_02", hp = 900}
        }
    }
    -- Configure other types as needed
}
```

### Vehicle System

Configure vehicle settings:
```lua
Config.VehicleSystem = {
    EnableParkedVehicles = true,
    ParkedVehicleDensity = 0.5,
    EnableVehicleDamage = true,
    VehicleDamageSettings = {
        EngineDamage = true,
        PlayerDamage = true,
        DamageAmount = 10,
        DamageInterval = 1000
    }
}
```

## Performance Optimization

1. Adjust spawn distances in `Config.Zombies`:
```lua
Config.Zombies = {
    MinSpawnDistance = 30,
    MaxSpawnDistance = 45,
    DespawnDistance = 50
}
```

2. Configure zombie limits in zones:
```lua
Config.RedZones.Zones.YourZone.ZombieLimit = 20
```

3. Adjust spawn rates:
```lua
Config.RedZones.Zones.YourZone.SpawnRate = 1000
```

## Troubleshooting

1. Zombies not spawning:
   - Check if zones are properly configured
   - Verify spawn distances
   - Check if the resource is started

2. Sound issues:
   - Verify xsound/sounity is installed
   - Check sound file paths
   - Adjust volume settings

3. Performance issues:
   - Reduce zombie limits
   - Increase spawn distances
   - Adjust spawn rates

## Support

For support, please:
1. Check the documentation
2. Review the changelog
3. Check known issues
4. Contact support if needed

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Credits

- Original Author: Nosmakos
- Modified by: Snowii
- Special thanks to all contributors 