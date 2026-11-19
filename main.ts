// Brainrot Bay — the entry program for make.fun's roblox-brainrot-01.
// Node 22, standard library only.
//
// The game is the Rojo project in this directory: build it first with
// `rojo build default.project.json --output game.rbxl`, then this program
// hands the entry in. It copies game.rbxl, src/, screenshots/ and
// PLAY.json from beside this file into /output and writes
// /output/dossier.json, the summary the judge reads, with the vendored
// make.fun library (vendor/makefun-roblox.ts, unchanged).
//
// Every name under /output must start with a letter, a digit or _ and
// hold only letters, digits, . _ and -: the grader refuses an entry whose
// output holds any other name, so src/ and screenshots/ are copied while
// leaving out every file or directory whose name starts with a dot
// (a .gitkeep or .DS_Store would fail the entry).
//
// Outside the grader's container, MAKEFUN_OUTPUT_DIR stands in for
// /output:
//   mkdir -p out && MAKEFUN_OUTPUT_DIR=out node main.ts

import { copyFileSync, cpSync, existsSync, mkdirSync, writeFileSync } from 'node:fs';
import { basename, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { buildDossier } from './vendor/makefun-roblox.ts';

const here = fileURLToPath(new URL('.', import.meta.url));
const out = process.env.MAKEFUN_OUTPUT_DIR ?? '/output';

/** cpSync's filter: skip every file and directory whose name starts with a dot. */
const notDotted = (path: string): boolean => !basename(path).startsWith('.');

copyFileSync(join(here, 'game.rbxl'), join(out, 'game.rbxl'));
copyFileSync(join(here, 'PLAY.json'), join(out, 'PLAY.json'));
cpSync(join(here, 'src'), join(out, 'src'), { recursive: true, filter: notDotted });
mkdirSync(join(out, 'screenshots'), { recursive: true });
if (existsSync(join(here, 'screenshots'))) {
	cpSync(join(here, 'screenshots'), join(out, 'screenshots'), { recursive: true, filter: notDotted });
}

// The gate's caps, from the kit's reference/gate.json: the dossier text is
// capped at 64 KiB, at most 4 screenshots of at most 256 KiB each, the
// place holds at most 500,000 instances, and its scripts hold at most
// 8 MiB of source with at most 1,048,576 characters of script paths.
writeFileSync(
	join(out, 'dossier.json'),
	buildDossier(out, {
		text_max_bytes: 65536,
		screenshots: { max: 4, max_bytes: 262144 },
		max_instances: 500000,
		scripts_max_source_bytes: 8388608,
		scripts_max_path_chars: 1048576,
	}),
);
