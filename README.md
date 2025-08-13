# Steam Hour Farmer – Game Picker (PowerShell GUI)

A simple PowerShell-based GUI for selecting your Steam games and starting [steam-hour-farmer](https://github.com/tacheometry/steam-hour-farmer) with your chosen list.  
It updates only the `GAMES` entry in your `.env` file while preserving all other variables.

---

## Features

- Fetches your owned Steam games via the [Steam Web API](https://partner.steamgames.com/doc/webapi/IPlayerService#GetOwnedGames)
- Multi-select with search
- Updates only `GAMES` in `.env` — keeps all other variables intact
- Backs up `.env` as `.env.bak` before saving
- Automatically launches `steam-hour-farmer` (uses global install if available, otherwise falls back to `npx`)
- No paths to configure — script runs in the same folder as your `steam-hour-farmer` install

---

## Prerequisites

- **Windows** with PowerShell 5+ (default on Windows 10/11)
- [Node.js](https://nodejs.org) (needed for `npx` fallback)
- [`steam-hour-farmer`](https://github.com/tacheometry/steam-hour-farmer):
  ```bash
  npm install -g steam-hour-farmer
(Global install optional – npx will work without it)

## `.env` setup
Your `.env` file should be in the same folder as both this script and your `steam-hour-farmer` installation.

Minimum:
```
ACCOUNT_NAME="your_steam_username"
PASSWORD="your_steam_password"
GAMES="123456"
STEAM_API_KEY="XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
STEAM_ID64="76261898015349678"
```
Optional:
```
SHARED_SECRET="base64encodedsharedsecret"
```
This is for automatic Steam Guard handling.

## How to get the required variables

| Variable        | Description                                       | How to get it                                                                                              |
|-----------------|---------------------------------------------------|-------------------------------------------------------------------------------------------------------------|
| `ACCOUNT_NAME`  | Your Steam username                                | The name you use to log into Steam                                                                          |
| `PASSWORD`      | Your Steam password                                | The password you use to log into Steam                                                                      |
| `STEAM_API_KEY` | Your Steam Web API key                             | [Get it here](https://steamcommunity.com/dev/apikey) – sign in and generate one                             |
| `STEAM_ID64`    | Your 17-digit SteamID64 (starts with `7656…`)      | If your profile URL is `/profiles/7656.../` → that's it. If it's `/id/YourName/`, look it up on [steamid.io](https://steamid.io) |


## Installation
1. Clone or download this repository into your `steam-hour-farmer` folder.
2. Edit `.env` (in the same folder) and add:
- `STEAM_API_KEY`
- `STEAM_ID64`
- Your Steam credentials (`ACCOUNT_NAME`, `PASSWORD`)
3. Ensure Node.js is installed and optionally install `steam-hour-farmer` globally:
```
npm install -g steam-hour-farmer
```
## Usage
1. Run the GUI script:
```
powershell -ExecutionPolicy Bypass -File .\SteamHourFarmer.GUI.ps1
```
2. Search for games using the search box.
3. Tick the games you want to farm.
4. Click **Start farmer with selection** (bottom-right).
5. The script will:
  - Update `GAMES` in `.env`
  - Save a backup as `.env.bak`
  - Launch `steam-hour-farmer` in the same folder

## References
- [steam-hour-farmer](https://github.com/tacheometry/steam-hour-farmer) – The underlying farming tool.
- [Steam Web API – GetOwnedGames](https://partner.steamgames.com/doc/webapi/IPlayerService#GetOwnedGames) – API used to fetch your owned games.
- [Steam API Key](https://steamcommunity.com/dev/apikey) – Needed to query your game library.
- [steamid.io](https://steamid.io) – Convert custom profile URLs to SteamID64.
