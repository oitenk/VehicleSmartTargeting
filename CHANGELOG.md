# Changelog

## 1.2

- The mod's on-screen text can now be translated. It goes through Codeware's localization system, with English as the fallback for any language that has no translation yet.
- Core: the mode messages ("Mounted guns: Smart Lock" and so on) are translatable when Codeware is installed. Codeware stays optional for the core file; without it the messages are in English as before.
- Garage add-on: the Targeting service button, the screen, its buttons and the purchase notice are all translatable.

Nothing changes in English, and no settings or saves are affected. The Mod Settings page stays in English. See "Translating" in the README if you would like to add a language.

## 1.1

- Fixed the lock-on diamond not appearing for the mounted guns in some load orders. Smart Lock itself was unaffected: targets were still locked and rounds still homed, only the on-screen diamond was missing.
- The gun crosshair now reads the locked target directly from the game's targeting system, which makes the diamond more robust across different setups.
- Debug logging records a little more detail about lock-on, to help with future reports.

If the diamond was already showing for you, nothing changes. No settings or saves are affected, and the Garage add-on file is unchanged.

## 1.0

- Initial release: Smart Lock and Gimbal Aim for mounted vehicle machine guns, with an optional Garage add-on.
