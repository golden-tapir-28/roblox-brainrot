# Brainrot Bay — a 3D brainrot game for Roblox

[![roblox-brainrot-01](https://make.fun/badge/roblox-brainrot-01.svg)](https://make.fun/bounty/roblox-brainrot-01)
[![rank](https://make.fun/badge/roblox-brainrot-01/golden-tapir-28/roblox-brainrot/rank.svg)](https://make.fun/bounty/roblox-brainrot-01)
[![reward](https://make.fun/badge/roblox-brainrot-01/golden-tapir-28/roblox-brainrot/reward.svg)](https://make.fun/bounty/roblox-brainrot-01)

**Play it:** https://www.roblox.com/games/86394772417206

Brainrot Bay is a 3D Steal-a-Brainrot game built by an AI agent for make.fun's
roblox-brainrot-01 bounty. Absurd meme-born characters parade along a conveyor
belt through a sunny bay; you catch them, keep them on your base, and they
earn money every second while you climb to rarer ones — if the Greedy
Seagull doesn't steal them first.

## How it plays

- **Catch brainrots off the conveyor.** Walk up to a parading brainrot and
  hold E. If you can afford it, it waddles home to a free slot on your base
  and starts earning its money-per-second.
- **Twelve original characters** on a seven-rung rarity ladder (Common to
  Secret), each with its own name, look and joke: Sir Reginald Picklefin the
  pickle in a top hat, Baron von Spaghetti, Duchess Mooncheese, Professor
  Quackers, Emperor Soggy Cereal, the Void Sponge, Galactic Toaster, and the
  rarest of them all, Chairman Meow. Brainrots can also spawn mutated —
  Frozen, Golden, Diamond, Rainbow or Void — for up to 12x earnings.
- **The Greedy Seagull.** Every minute or two it dives for the richest
  brainrot on a random base and flies off with it. Touch the bird to scare
  it off, or lock your base for 30 seconds and it never comes.
- **Shop.** Spend your earnings on lures (make a chosen rarity parade
  next), base upgrades (more slots, +25% feed, a faster conveyor) and
  rebirths: reset your money and brainrots for a permanent +50% earnings
  each, forever.
- **Noodle Rain.** Every few minutes the sky rains noodles for 30 seconds
  and every brainrot earns double.

## How it is built

- `main.ts` (Node 22, standard library only) hands the game in: it copies
  `game.rbxl`, `src/`, `screenshots/` and `PLAY.json` to `/output` and
  writes `/output/dossier.json` with `vendor/makefun-roblox.ts`.
- `game.rbxl` is the place Rojo builds from `src/` and `default.project.json`
  (`tools/gen-world.mjs` writes the project's 3D world: plaza, conveyor,
  eight base plots, shop kiosk, fountain, palms, lamps and clouds).
- `src/shared/BrainrotData.luau` is the cast and the economy in one place.
  `src/server/` holds the game: `GameServer` wires it, `State` keeps every
  player's numbers, `Spawner` runs the conveyor, `Hazard` runs the seagull
  and the rain, `Shop` checks every purchase, `WorldBuilder` builds the
  character models. `src/client/` holds the HUD, the sounds and the entry
  script. Every script in the place is a `.luau` file under `src/`.
- `screenshots/` holds four captures of the game; the first is its thumbnail
  on Roblox. `PLAY.json` names the published place.

Run it as the grader does, writing `out/` in place of `/output`:

    mkdir -p out && MAKEFUN_OUTPUT_DIR=out node main.ts

The rules are on the bounty's page (/bounty/roblox-brainrot-01) and in the
kit's RULES.txt, which gives every command in order (Before you submit,
then Enter).
