// Convert an SVG file to a PNG of the given width.
//
// Usage:
//   node svg-to-png.js <input.svg> <output.png> [width=1024]
//
// Example:
//   node svg-to-png.js ../app/assets/icon.svg ../app/assets/icon.png 1024
//   node svg-to-png.js ../app/assets/splash.svg ../app/assets/splash.png 512

const fs = require('fs');
const path = require('path');
const { Resvg } = require('@resvg/resvg-js');

const [, , inputArg, outputArg, widthArg] = process.argv;
if (!inputArg || !outputArg) {
  console.error('Usage: node svg-to-png.js <input.svg> <output.png> [width=1024]');
  process.exit(1);
}

const width = widthArg ? Number(widthArg) : 1024;
const inputPath = path.resolve(inputArg);
const outputPath = path.resolve(outputArg);

const svg = fs.readFileSync(inputPath);
const resvg = new Resvg(svg, { fitTo: { mode: 'width', value: width } });
fs.writeFileSync(outputPath, resvg.render().asPng());

console.log(`Wrote ${path.relative(process.cwd(), outputPath)} (${width}px wide)`);
