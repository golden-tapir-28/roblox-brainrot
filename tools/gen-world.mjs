// Brainrot Bay world generator.
//
// Writes default.project.json for the Rojo project: the static 3D world of
// the game (plaza, conveyor belt, eight base plots, shop kiosk, fountain,
// palm trees, lamps, clouds, paths, signs) plus the script mappings.
// Everything is placed from one layout table, so the world the place file
// holds and the world the screenshots render are the same world.
//
// Run: node tools/gen-world.mjs   (from the repository root)

import { writeFileSync } from 'node:fs';

// -- helpers ---------------------------------------------------------------

const parts = {};

function part(name, props, parent) {
	parent[name] = { $className: 'Part', $properties: props };
	return parent[name];
}

function box(parent, name, pos, size, color, extra = {}) {
	return part(name, {
		Anchored: true,
		CanCollide: true,
		Locked: true,
		Color: color,
		Position: pos,
		Size: size,
		Material: extra.material ?? 'Plastic',
		Shape: 'Block',
		TopSurface: 'Smooth',
		...extra.props,
	}, parent);
}

function ball(parent, name, pos, diameter, color, extra = {}) {
	return part(name, {
		Anchored: true,
		CanCollide: false,
		Locked: true,
		Color: color,
		Position: pos,
		Size: [diameter, diameter, diameter],
		Material: extra.material ?? 'Plastic',
		Shape: 'Ball',
		...extra.props,
	}, parent);
}

function cylinder(parent, name, pos, length, diameter, color, extra = {}) {
	return part(name, {
		Anchored: true,
		CanCollide: extra.collide ?? false,
		Locked: true,
		Color: color,
		Position: pos,
		Size: [length, diameter, diameter],
		Material: extra.material ?? 'Plastic',
		Shape: 'Cylinder',
		Orientation: extra.orientation ?? [0, 0, 90],
		...extra.props,
	}, parent);
}

// -- palette ---------------------------------------------------------------

const GRASS = [0.29, 0.55, 0.22];
const PLAZA = [0.85, 0.72, 0.5];
const PATH = [0.72, 0.6, 0.45];
const BELT = [0.16, 0.16, 0.18];
const BELT_STRIPE = [0.98, 0.8, 0.15];
const RAIL = [0.9, 0.35, 0.15];
const TRUNK = [0.45, 0.3, 0.15];
const LEAF = [0.15, 0.55, 0.2];
const WATER = [0.15, 0.55, 0.95];
const STONE = [0.6, 0.6, 0.62];
const WOOD = [0.55, 0.38, 0.2];
const CLOUD = [1, 1, 1];
const LAMP_POLE = [0.2, 0.2, 0.22];
const LAMP_GLOW = [1, 0.9, 0.4];

// The eight base plots, in a ring around the plaza. Each plot gets its own
// pad colour; the first plot (index 0, south) is the local player's home
// base in the screenshots.
const PLOT_COLORS = [
	[0.95, 0.35, 0.35], // red
	[0.35, 0.6, 0.95], // blue
	[0.35, 0.85, 0.4], // green
	[0.95, 0.75, 0.25], // yellow
	[0.75, 0.4, 0.9], // purple
	[0.95, 0.55, 0.25], // orange
	[0.35, 0.85, 0.85], // cyan
	[0.95, 0.5, 0.7], // pink
];

const PLOT_RADIUS = 58;
const PLOT_SIZE = 16;

// -- world -----------------------------------------------------------------

const ws = parts;

// Ground.
box(ws, 'Baseplate', [0, -10, 0], [512, 20, 512], GRASS, { material: 'Grass' });

// Central plaza slab.
box(ws, 'Plaza', [0, 0.05, 0], [90, 0.1, 90], PLAZA, { material: 'Slate', props: { CanCollide: false } });

// Paths out of the plaza, north / east / south / west.
box(ws, 'PathNorth', [0, 0.06, -62], [10, 0.1, 46], PATH, { material: 'Slate', props: { CanCollide: false } });
box(ws, 'PathEast', [62, 0.06, 0], [46, 0.1, 10], PATH, { material: 'Slate', props: { CanCollide: false } });
box(ws, 'PathSouth', [0, 0.06, 62], [10, 0.1, 46], PATH, { material: 'Slate', props: { CanCollide: false } });
box(ws, 'PathWest', [-62, 0.06, 0], [46, 0.1, 10], PATH, { material: 'Slate', props: { CanCollide: false } });

// Conveyor belt across the middle (brainrots parade from west to east).
box(ws, 'Conveyor', [0, 0.5, 0], [140, 1, 8], BELT, { material: 'Slate' });
box(ws, 'ConveyorRailNorth', [0, 1.1, -4.6], [140, 0.6, 0.8], RAIL, { material: 'Metal' });
box(ws, 'ConveyorRailSouth', [0, 1.1, 4.6], [140, 0.6, 0.8], RAIL, { material: 'Metal' });
for (let i = 0; i < 14; i++) {
	const x = -65 + i * 10;
	box(ws, `BeltStripe${i}`, [x, 1.05, 0], [2, 0.12, 7.4], BELT_STRIPE, { material: 'Neon', props: { CanCollide: false } });
}

// Base plots: a coloured pad with six slot markers (two rows of three).
// Brainrots a player owns stand on the slots and earn money.
for (let i = 0; i < 8; i++) {
	const a = (i * Math.PI) / 4 + Math.PI / 8;
	const cx = Math.round(Math.cos(a) * PLOT_RADIUS * 100) / 100;
	const cz = Math.round(Math.sin(a) * PLOT_RADIUS * 100) / 100;
	box(ws, `Plot${i}`, [cx, 0.5, cz], [PLOT_SIZE, 1, PLOT_SIZE], PLOT_COLORS[i], { material: 'Slate' });
	for (let s = 0; s < 6; s++) {
		const row = Math.floor(s / 3);
		const col = s % 3;
		const ox = (col - 1) * 4.4;
		const oz = (row - 0.5) * 4.4;
		box(ws, `Plot${i}Slot${s}`, [cx + ox, 1.05, cz + oz], [3.4, 0.12, 3.4], [1, 1, 1], { material: 'Neon', props: { CanCollide: false } });
	}
	// A short flag pole on each plot so owners can spot their base.
	cylinder(ws, `Plot${i}Flag`, [cx + 6.5, 4, cz - 6.5], 7, 0.6, [0.9, 0.9, 0.9], { material: 'Metal' });
	box(ws, `Plot${i}FlagCloth`, [cx + 5.2, 6.6, cz - 6.5], [2.6, 1.6, 0.2], PLOT_COLORS[i], { material: 'Fabric', props: { CanCollide: false } });
}

// Spawn pad (south) and the welcome sign.
ws['SpawnLocation'] = {
	$className: 'SpawnLocation',
	$properties: {
		Anchored: true,
		CanCollide: true,
		Locked: true,
		Color: [0.4, 0.8, 0.4],
		Position: [0, 0.5, 82],
		Size: [12, 1, 12],
		Material: 'Plastic',
		Neutral: true,
		Duration: 0,
		Enabled: true,
	},
};
box(ws, 'SignPostLeft', [-6, 2.5, 74], [0.8, 5, 0.8], WOOD, { material: 'Wood' });
box(ws, 'SignPostRight', [6, 2.5, 74], [0.8, 5, 0.8], WOOD, { material: 'Wood' });
const sign = box(ws, 'SignBoard', [0, 6, 74], [15, 4, 0.8], [0.95, 0.85, 0.6], { material: 'Wood' });
// The sign's text is attached by WorldBuilder at runtime: Rojo's project
// JSON cannot carry a UDim2 (no encoding this Rojo accepts), so the
// SurfaceGui lives in code, not in this file.

// Shop kiosk (west side): counter, roof, sign.
box(ws, 'ShopCounter', [-78, 1.5, 40], [12, 3, 5], [0.9, 0.7, 0.4], { material: 'Wood' });
box(ws, 'ShopRoof', [-78, 5.2, 40], [14, 0.8, 7], [0.9, 0.3, 0.3], { material: 'Plastic' });
box(ws, 'ShopPoleLeft', [-83, 3, 40], [0.8, 4.4, 0.8], WOOD, { material: 'Wood' });
box(ws, 'ShopPoleRight', [-73, 3, 40], [0.8, 4.4, 0.8], WOOD, { material: 'Wood' });
const shopSign = box(ws, 'ShopSign', [-78, 6.4, 40], [10, 2.6, 0.6], [1, 0.95, 0.7], { material: 'Wood' });
// Its "SHOP" text is attached by WorldBuilder at runtime, like the sign.

// Fountain (north of the plaza). Cylinders are rotated so their long axis
// is vertical: Size is [length, diameter, diameter] along that axis.
cylinder(ws, 'FountainBasin', [0, 1, -48], 2, 16, STONE, { material: 'Slate', collide: true });
cylinder(ws, 'FountainWater', [0, 1.8, -48], 0.6, 14, WATER, { material: 'Neon', props: { CanCollide: false } });
cylinder(ws, 'FountainColumn', [0, 3.5, -48], 5, 2, STONE, { material: 'Slate' });
ball(ws, 'FountainTop', [0, 6.5, -48], 3, WATER, { material: 'Neon' });

// Palm trees around the edge.
const PALMS = [
	[-95, -60], [95, -60], [-95, 60], [95, 60],
	[-60, -95], [60, -95], [-60, 95], [60, 95],
	[0, -100], [0, 100],
];
PALMS.forEach(([x, z], i) => {
	cylinder(ws, `Palm${i}Trunk`, [x, 5, z], 10, 1.6, TRUNK, { material: 'Wood' });
	ball(ws, `Palm${i}Leaf0`, [x, 11, z], 5, LEAF, { material: 'Grass' });
	ball(ws, `Palm${i}Leaf1`, [x + 2.5, 10, z + 1], 4, LEAF, { material: 'Grass' });
	ball(ws, `Palm${i}Leaf2`, [x - 2.5, 10, z - 1], 4, LEAF, { material: 'Grass' });
});

// Lamps along the paths.
const LAMPS = [[-20, -30], [20, -30], [-20, 30], [20, 30], [-45, 0], [45, 0]];
LAMPS.forEach(([x, z], i) => {
	cylinder(ws, `Lamp${i}Pole`, [x, 3, z], 6, 0.7, LAMP_POLE, { material: 'Metal' });
	ball(ws, `Lamp${i}Bulb`, [x, 6.6, z], 2.2, LAMP_GLOW, { material: 'Neon' });
});

// Clouds drifting high above.
const CLOUDS = [[-60, 46, -60], [60, 52, -40], [-40, 48, 70], [70, 44, 60], [0, 56, 0]];
CLOUDS.forEach(([x, y, z], i) => {
	ball(ws, `Cloud${i}`, [x, y, z], 12, CLOUD, { material: 'Plastic' });
	ball(ws, `Cloud${i}B`, [x + 7, y - 1, z + 2], 8, CLOUD, { material: 'Plastic' });
});

// -- project ---------------------------------------------------------------

const project = {
	name: 'brainrot-bay',
	tree: {
		$className: 'DataModel',
		Players: {
			$properties: {
				CharacterAutoLoads: true,
			},
		},
		ReplicatedStorage: {
			Shared: { $path: 'src/shared' },
		},
		ServerScriptService: {
			Server: { $path: 'src/server' },
		},
		StarterPlayer: {
			StarterPlayerScripts: {
				Client: { $path: 'src/client' },
			},
		},
		Workspace: {
			$properties: { FilteringEnabled: true },
			...ws,
		},
		Lighting: {
			$properties: {
				Ambient: [0.35, 0.35, 0.4],
				Brightness: 2.5,
				GlobalShadows: true,
				Outlines: false,
				Technology: 'Voxel',
				ClockTime: 10,
			},
		},
		SoundService: {
			$properties: { RespectFilteringEnabled: true },
		},
	},
};

writeFileSync('default.project.json', JSON.stringify(project, null, '\t') + '\n');
console.log('wrote default.project.json with', Object.keys(ws).length, 'workspace instances');
