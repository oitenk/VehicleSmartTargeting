# Vehicle Smart Targeting

A Cyberpunk 2077 mod that gives the mounted machine guns on weaponized vehicles two targeting modes. Vehicle missile launchers already lock on; this does the same for the guns.

- **Smart Lock** - the guns lock on to hostile targets the way the missile launcher does, and their rounds home on the locked target.
- **Gimbal Aim** - no lock. Rounds leave the guns aimed at whatever is under the crosshair, within an arc in front of the car.

Both modes use the missile launcher's HUD as the crosshair. They apply to every vehicle that uses the stock mounted machine guns, vanilla or modded. Modded vehicles that replace the gun projectile with their own keep it.

## Controls

While the mounted guns are out:

| Vehicle | Key | Result |
|---|---|---|
| Guns only | `1` | Smart Lock |
| | `2` | Gimbal Aim |
| | `Alt` (Triangle / Y) | Switch between the two |
| Guns and missiles | `1` again while the guns are out | Switch between the two |

These are the game's own mounted-weapon keys, so they follow your key bindings.

## Packages

The mod comes in two parts. Each is laid out from the game root, so its folders can be copied into the game directory or zipped for a mod manager.

### Core

The `r6` folder.

On its own, every armed vehicle has both modes straight away.

Requires:
- [RED4ext](https://github.com/WopsS/RED4ext)
- [redscript](https://github.com/jac3km4/redscript)
- [TweakXL](https://github.com/psiberx/cp2077-tweak-xl)

Optional:
- [Mod Settings](https://github.com/jackhumbert/mod_settings) - adds an in-game options page (see below). Without it the defaults apply.

### Garage add-on

The contents of the `garage-addon` folder.

Installing the add-on turns the two modes into per-vehicle upgrades bought through [Garage](https://www.nexusmods.com/cyberpunk2077/mods/30297) by CyanideX. A "Targeting" service appears in the garage hub for owned vehicles with mounted guns.

| Upgrade | Price | Refit fee |
|---|---|---|
| Smart Lock | 50,000 | 5,000 |
| Gimbal Aim | 35,000 | 3,500 |

Removing an upgrade is free. The refit fee applies when putting back an upgrade that vehicle has already bought. A vehicle with neither upgrade fires straight, with the stock gun crosshair. What you pay goes into that garage's cash pool.

Requires:
- The core package
- [Garage](https://www.nexusmods.com/cyberpunk2077/mods/30297) (VehicleCore and GarageCore)
- [Codeware](https://github.com/psiberx/cp2077-codeware)
- [Cyber Engine Tweaks](https://github.com/maximegmd/CyberEngineTweaks)

The add-on will not compile without Garage installed. Removing the add-on makes both modes free again; purchases stay in the save.

Payment has been tested on GarageCore 1.0.4. The add-on is written to use Garage's `GC.Payment` helper where it exists (GarageCore 1.1.0 and later); that path has not been tested yet.

## Options

With Mod Settings installed, under **Vehicle Smart Targeting**:

| Section | Option | Default |
|---|---|---|
| Smart Lock | Miss chance (%) | 10 |
| Smart Lock | Jammer effect (%) | 100 |
| Smart Lock | Guidance arc (degrees) | 45 |
| Gimbal Aim | Gimbal arc (degrees) | 45 |
| Troubleshooting | Debug logging | Off |

*Jammer effect* scales how much enemies with smart-weapon jammers throw off the guns; 100 is the same penalty on-foot smart weapons take. Debug logging writes per-shot details to the Cyber Engine Tweaks game log.

## Notes

- The gun models do not move in Gimbal Aim; only the rounds leave at an angle.
- Smart Lock only guides rounds at targets within the guidance arc in front of the vehicle. Outside it, rounds fire straight.
- Built and tested on game version 2.3x with TweakXL 1.11.4 and Mod Settings 0.2.21.

## Credits

- **CyanideX** for [Garage](https://www.nexusmods.com/cyberpunk2077/mods/30297) and its service API and wiki, which the add-on is built on.
- **SDH0** for the [Nitrous Addon (Garage)](https://www.nexusmods.com/cyberpunk2077/mods/34377), the reference third-party Garage service, and for permission to publish this add-on.

The code in this repository was written with Claude, an AI assistant.

## License

[MIT](LICENSE)
