// Regenerate app/web/favicon.png and app/web/icons/Icon-*.png from
// app/assets/icon.svg. Same source as the Android launcher icon, so
// all platforms show the same brand.
//
// Run:  node gen-web-icons.js  (from the tools/ directory)

const fs = require('fs');
const path = require('path');
const { Resvg } = require('@resvg/resvg-js');

const svg = fs.readFileSync(path.resolve(__dirname, '../app/assets/icon.svg'));

function render(width, outputRelative) {
  const resvg = new Resvg(svg, { fitTo: { mode: 'width', value: width } });
  const outputPath = path.resolve(__dirname, '..', outputRelative);
  fs.mkdirSync(path.dirname(outputPath), { recursive: true });
  fs.writeFileSync(outputPath, resvg.render().asPng());
  console.log(`  ${String(width).padStart(4)}px → ${outputRelative}`);
}

console.log('Generating web icons from app/assets/icon.svg...');
render(256, 'app/web/favicon.png');
render(192, 'app/web/icons/Icon-192.png');
render(512, 'app/web/icons/Icon-512.png');
// Maskable = Android adaptive icon on web. Our icon.svg already extends
// the gradient to all edges, so it survives any mask shape cleanly.
render(192, 'app/web/icons/Icon-maskable-192.png');
render(512, 'app/web/icons/Icon-maskable-512.png');
console.log('Done.');
