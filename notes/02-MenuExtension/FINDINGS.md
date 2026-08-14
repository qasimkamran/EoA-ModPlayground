# Findings

In this note, I will detail all findings on the UE4 system, Lua API of UE4SS, and all reverse engineering effort that were made, observed or logged in the process of developing the **02-MenuExtension** mod.

## Methodology

For this mod, I used the UE4SS Lua function `NotifyOnNewObject` to observe the creation of `UMG.UserWidget` instances. The function is passed the class path `/Script/UMG.UserWidget` and a callback that receives each newly created widget. After validating the widget, the callback prints its full name to the console and writes it, together with a timestamp, to the log file. The mod is installed, and EoA is launched with the mod loaded and console output enabled in the UE4SS `.ini` settings file. Upon launch, the console should display the name of every newly created `UserWidget`. We can then select `Start Game`, enter the open world, and press the start button to open the Console Menu, which displays EoA's UI panel. Opening and closing the panel several times, and interacting with the items in the Console Menu, logs their names and IDs to the log file, which we can inspect after exiting the game. Finally, all logs are collected using `tools\log-collect.ps1` and placed in the project repository's `logs` directory.

## Observations

### Widgets

- `WBP_Console_MainMenu_C` - Console Menu Panel Widget
- `WBP_Console_MainMenu_List_C` - List of Console Menu Widget
    The widget contains seven items; matching the game's console menu item count.
- `WBP_Console_MainMenu_MenuIcon_C` - Representing each Menu Widget Item

**Structure**

```
WBP_Console_MainMenu_C
└── MainMenu_List
    ├── Item_0
    ├── Item_1
    ├── Item_2
    ├── Item_3
    ├── Item_4
    ├── Item_5
    └── Item_6
```

- `WBP_GameAnnounce_B_C` - One-off prompts
  <br>*This prompt displayed after trying to hit 'Log Out' three times at end of gameplay.*
