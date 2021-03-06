# ES_DispelEnemyBuff

Addon that tailors the display of dispellable buffs on enemy nameplates.
Created spesificly for my own setup of nameplates. But hosting on GitHub so my friends that also use it can easily access any changes that might come

---
---
[Latest Release](/../../releases/latest) :file_folder:

:memo: Changes: v1.0.6
- (General): Code cleanup.
- (Fix): Added missing check for blood elves.
- (Fix): Filter type of units. Duplicate events for certain unittypes caused auras to never be removed once nameplate disappeared.

:memo: Changes: v1.0.5
- (Bugfix): Moved event-registering to the initialization stage. Hopefully preventing issues when addon is loaded slowly.

:memo: Changes: v1.0.4
- (Bugfix): Cleaned up the class lookup. Fixing the issue with hunters not seeing dispellable enrage.

:memo: Changes: v1.0.3
- (Bugfix): Reworked old unit-handling. Fixes issue of duplicate auras appearing.
- (General): Clean-up of code to improve performance.

:memo: Changes: v1.0.2
- (Bugfix): Variables now loaded earlier to prevent an issue on certain classes.

:memo: Changes: v1.0.1
- (Bugfix): Logic for centered growth finally works
- (Bugfix): Border replaced with texture. Should no longer glitch on certain sizes
- (Bugfix): General tweaks.
- (New): Settings now stored per account.
- (New): Settings-window and ability to test the display on current target.

  Type "/es_deb" to bring up the settings.
  
  Type "/es_deb reset" to revert back to default values
