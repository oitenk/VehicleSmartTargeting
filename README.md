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

## Requirements

- [RED4ext](https://github.com/WopsS/RED4ext)
- [redscript](https://github.com/jac3km4/redscript)
- [TweakXL](https://github.com/psiberx/cp2077-tweak-xl)

Optional:
- [Mod Settings](https://github.com/jackhumbert/mod_settings) - adds an in-game options page (see below). Without it the defaults apply.

## Installation

Copy the `r6` folder into the game directory, or install the release zip with a mod manager. It is laid out from the game root.

Every armed vehicle has both modes straight away.

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

## License

[MIT](LICENSE)
