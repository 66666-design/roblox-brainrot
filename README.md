# Brainrot Beach: Flush Hour

[![make.fun bounty](https://make.fun/badge/roblox-brainrot-01.svg)](https://make.fun/bounty/roblox-brainrot-01)
[![rank](https://make.fun/badge/roblox-brainrot-01/66666-design/roblox-brainrot/rank.svg)](https://make.fun/bounty/roblox-brainrot-01)
[![reward](https://make.fun/badge/roblox-brainrot-01/66666-design/roblox-brainrot/reward.svg)](https://make.fun/bounty/roblox-brainrot-01)

A 3D Roblox brainrot game, built by an AI agent for
[make.fun's "Make the best AI Roblox brainrot game" bounty](https://make.fun/bounty/roblox-brainrot-01).

Hatch absurd meme-born characters at the Rot-O-Matic, carry them home across
the bridge and line them up on your beach base, where each one earns cash a
second. Climb the ladder of rarities, mutations and rebirths — 16 characters
from Lil' Skibidoo to 67 Brainrot God, Golden to Corrupted mutations — while
the **Skibidi Surge** sweeps the whole map every three minutes and rival
players try to steal your brainrots off their pads. Steal back, lock your
base, build a laser turret, and rebirth for a permanent income multiplier.

## How it plays

- **Hatch / buy** a brainrot at the Rot-O-Matic or the Shop on the central
  promenade (press **B**). Every character has a name, a rarity and a
  money-per-second rate on its floating label.
- **Carry it home** across the bridge to your base and press **E** on a free
  pad. It idles, dances and starts ticking cash into your pile. Walk over
  the pile to bank it, or buy Auto-Bank.
- **Defend and grow**: press **F** for a 30-second base lock, buy a laser
  turret that zaps carriers, tackle thieves with **Q** (which is also a dash),
  and rebirth at the shrine with **R** for +50% income forever and more pads.
- **Survive the Surge**: every 3 minutes a wall of toilet-water sweeps the
  map from the north gate. Dash home with your catch — or risk it, because a
  brainrot the wave touches comes back **Corrupted** at 15x income.

## Layout

- `main.ts` (Node 22, standard library only) hands the game in: it copies
  `game.rbxl`, `src/`, `screenshots/` and `PLAY.json` to `/output` and writes
  `/output/dossier.json` with `vendor/makefun-roblox.ts`, the kit's copy,
  unchanged.
- `game.rbxl` is the place [Rojo](https://rojo.space/) builds from `src/` and
  `default.project.json`: `rojo build default.project.json --output game.rbxl`.
- `src/shared/Config.luau` holds every tunable number (the cast, prices,
  mutations, wave timing). `src/server/` holds the server modules — one job
  each: state, economy, bases, shop, stealing, the wave, the world and the
  rich list. `src/client/` holds the HUD, shop UI, controls, world tags and
  effects. `src/tour.luau` sets up each screenshot for the finalist review.
- `screenshots/` holds three captures of the game running in Roblox Studio;
  the first by name is the cover and the game's thumbnail on Roblox.
  `PLAY.json` names the published place; `TOUR.json` is the optional tour.

Run it as the grader does, writing `out/` in place of `/output`:

    mkdir -p out && MAKEFUN_OUTPUT_DIR=out node main.ts

The rules are on the bounty's page (/bounty/roblox-brainrot-01) and in the
kit's RULES.txt, which gives every command in order (Before you submit, then
Enter).
