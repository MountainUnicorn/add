/**
 * ADD Hill Chart Component
 * Renders an interactive hill chart showing feature progress.
 * Pure vanilla JS, no dependencies. All CSS classes prefixed with hc-.
 */
(function () {
  'use strict';

  var container = document.getElementById('hill-chart-container');
  if (!container) return;

  /* ── Feature data ─────────────────────────────────────────────── */

  var features = [
    { name: 'Auth',      x: 0.15, color: '#b00149' },
    { name: 'API',       x: 0.35, color: '#d4326d' },
    { name: 'Dashboard', x: 0.55, color: '#e85d9c' },
    { name: 'Search',    x: 0.75, color: '#22c55e' },
    { name: 'Deploy',    x: 0.90, color: '#22c55e' }
  ];

  /* ── Hill math helpers ────────────────────────────────────────── */

  var SVG_W = 600;
  var SVG_H = 200;
  var X_MIN = 40;
  var X_MAX = 560;
  var Y_TOP = 30;   // peak (SVG y is inverted)
  var Y_BOT = 170;  // baseline

  function hillY(t) {
    // Parabola: y = 4t(1-t), peaks at 1 when t=0.5
    return 4 * t * (1 - t);
  }

  function mapX(t) {
    return X_MIN + t * (X_MAX - X_MIN);
  }

  function mapY(t) {
    // hillY returns 0..1, map to Y_BOT..Y_TOP (inverted)
    var h = hillY(t);
    return Y_BOT - h * (Y_BOT - Y_TOP);
  }

  /* ── Inject scoped CSS ────────────────────────────────────────── */

  var style = document.createElement('style');
  style.textContent = [
    '.hc-wrapper {',
    '  background: var(--card-bg, #ffffff);',
    '  border: 1px solid var(--border, #e5e5e5);',
    '  border-radius: 16px;',
    '  padding: 24px;',
    '}',
    '.hc-svg {',
    '  display: block;',
    '  width: 100%;',
    '  height: auto;',
    '}',
    '.hc-dot {',
    '  cursor: pointer;',
    '  animation: hc-pulse 2s ease-in-out infinite;',
    '  filter: drop-shadow(0 2px 4px rgba(0,0,0,0.2));',
    '}',
    '@keyframes hc-pulse {',
    '  0%, 100% { r: 8; opacity: 1; }',
    '  50%      { r: 10; opacity: 0.85; }',
    '}',
    '.hc-label {',
    '  font-family: inherit;',
    '  font-size: 11px;',
    '  fill: var(--text-secondary, #64748b);',
    '  text-anchor: middle;',
    '  pointer-events: none;',
    '}',
    '.hc-zone-label {',
    '  font-family: inherit;',
    '  font-size: 13px;',
    '  font-weight: 600;',
    '  fill: var(--text-secondary, #64748b);',
    '  text-anchor: middle;',
    '  pointer-events: none;',
    '}',
    '.hc-tooltip {',
    '  position: absolute;',
    '  padding: 6px 12px;',
    '  background: var(--card-bg, #ffffff);',
    '  border: 1px solid var(--border, #e5e5e5);',
    '  border-radius: 8px;',
    '  font-size: 12px;',
    '  color: var(--text-primary, #1a1a2e);',
    '  pointer-events: none;',
    '  white-space: nowrap;',
    '  box-shadow: 0 4px 12px rgba(0,0,0,0.1);',
    '  opacity: 0;',
    '  transition: opacity 0.15s;',
    '  z-index: 10;',
    '}'
  ].join('\n');
  document.head.appendChild(style);

  /* ── Build hill path ──────────────────────────────────────────── */

  var STEPS = 80;
  var pathParts = [];
  for (var i = 0; i <= STEPS; i++) {
    var t = i / STEPS;
    var px = mapX(t);
    var py = mapY(t);
    pathParts.push((i === 0 ? 'M' : 'L') + px.toFixed(1) + ',' + py.toFixed(1));
  }
  var hillPathD = pathParts.join(' ');

  // Closed path for gradient fill (hill + baseline)
  var fillPathD = hillPathD +
    ' L' + X_MAX + ',' + Y_BOT +
    ' L' + X_MIN + ',' + Y_BOT + ' Z';

  /* ── Status descriptions ──────────────────────────────────────── */

  function statusFor(t) {
    if (t < 0.2)  return 'Shaping \u2014 early exploration';
    if (t < 0.4)  return 'Speccing \u2014 design solidifying';
    if (t < 0.5)  return 'Almost over the hill';
    if (t < 0.6)  return 'Just past the hill \u2014 executing';
    if (t < 0.8)  return 'Building \u2014 steady progress';
    return 'Wrapping up \u2014 nearly done';
  }

  /* ── Build SVG ────────────────────────────────────────────────── */

  var ns = 'http://www.w3.org/2000/svg';

  function el(tag, attrs) {
    var node = document.createElementNS(ns, tag);
    if (attrs) {
      for (var k in attrs) {
        if (attrs.hasOwnProperty(k)) node.setAttribute(k, attrs[k]);
      }
    }
    return node;
  }

  var svg = el('svg', {
    viewBox: '0 0 ' + SVG_W + ' ' + SVG_H,
    class: 'hc-svg',
    'aria-label': 'Hill chart showing feature progress'
  });

  // Gradient definition
  var defs = el('defs');
  var grad = el('linearGradient', { id: 'hc-hill-grad', x1: '0', y1: '0', x2: '0', y2: '1' });
  var stop1 = el('stop', { offset: '0%', 'stop-color': 'rgba(176,1,73,0.1)' });
  var stop2 = el('stop', { offset: '100%', 'stop-color': 'rgba(176,1,73,0.05)' });
  grad.appendChild(stop1);
  grad.appendChild(stop2);
  defs.appendChild(grad);
  svg.appendChild(defs);

  // Hill fill
  svg.appendChild(el('path', {
    d: fillPathD,
    fill: 'url(#hc-hill-grad)'
  }));

  // Hill stroke
  svg.appendChild(el('path', {
    d: hillPathD,
    fill: 'none',
    stroke: 'rgba(176,1,73,0.3)',
    'stroke-width': '2'
  }));

  // Dashed vertical line at peak (x = 300)
  var peakX = mapX(0.5);
  svg.appendChild(el('line', {
    x1: peakX, y1: Y_TOP,
    x2: peakX, y2: Y_BOT,
    stroke: 'rgba(176,1,73,0.2)',
    'stroke-width': '1',
    'stroke-dasharray': '4,4'
  }));

  // Zone labels
  var zoneLeft = el('text', {
    x: '150', y: String(Y_BOT + 20),
    class: 'hc-zone-label'
  });
  zoneLeft.textContent = 'Figuring it out \u2191';
  svg.appendChild(zoneLeft);

  var zoneRight = el('text', {
    x: '450', y: String(Y_BOT + 20),
    class: 'hc-zone-label'
  });
  zoneRight.textContent = 'Executing \u2193';
  svg.appendChild(zoneRight);

  // Feature dots and labels
  features.forEach(function (f) {
    var cx = mapX(f.x);
    var cy = mapY(f.x);
    var isDownhill = f.x > 0.5;

    // Dot
    var dot = el('circle', {
      cx: cx, cy: cy, r: '8',
      fill: f.color,
      class: 'hc-dot',
      'data-name': f.name,
      'data-status': statusFor(f.x)
    });
    svg.appendChild(dot);

    // Label: below dot on uphill, above on downhill
    var labelY = isDownhill ? cy - 16 : cy + 22;
    var label = el('text', {
      x: cx, y: labelY,
      class: 'hc-label'
    });
    label.textContent = f.name;
    svg.appendChild(label);
  });

  /* ── Assemble DOM ─────────────────────────────────────────────── */

  var wrapper = document.createElement('div');
  wrapper.className = 'hc-wrapper';
  wrapper.style.position = 'relative';
  wrapper.appendChild(svg);
  container.appendChild(wrapper);

  /* ── Tooltip interaction ──────────────────────────────────────── */

  var tooltip = document.createElement('div');
  tooltip.className = 'hc-tooltip';
  wrapper.appendChild(tooltip);

  svg.addEventListener('mouseover', function (e) {
    if (e.target.classList.contains('hc-dot')) {
      var name = e.target.getAttribute('data-name');
      var status = e.target.getAttribute('data-status');
      tooltip.innerHTML = '<strong>' + name + '</strong><br>' + status;
      tooltip.style.opacity = '1';
    }
  });

  svg.addEventListener('mousemove', function (e) {
    if (tooltip.style.opacity === '1') {
      var rect = wrapper.getBoundingClientRect();
      var tx = e.clientX - rect.left + 12;
      var ty = e.clientY - rect.top - 40;
      tooltip.style.left = tx + 'px';
      tooltip.style.top = ty + 'px';
    }
  });

  svg.addEventListener('mouseout', function (e) {
    if (e.target.classList.contains('hc-dot')) {
      tooltip.style.opacity = '0';
    }
  });

})();
