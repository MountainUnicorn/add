/* ===== ADD — Maturity Level Interactive Slider ===== */

(function () {
  'use strict';

  var LEVELS = [
    {
      id: 'poc',
      name: 'POC',
      color: '#6b7280',
      prd: 'A paragraph',
      specs: 'Optional',
      tdd: 'Optional',
      qualityGates: 'Pre-commit only',
      agents: '1',
      wip: '1',
      dimensions: 2,
      dimensionsLabel: '2 of 18 active'
    },
    {
      id: 'alpha',
      name: 'Alpha',
      color: '#f59e0b',
      prd: '1-pager',
      specs: 'Critical paths',
      tdd: 'Critical paths',
      qualityGates: '+ CI',
      agents: '1-2',
      wip: '2',
      dimensions: 8,
      dimensionsLabel: '8 of 18 active'
    },
    {
      id: 'beta',
      name: 'Beta',
      color: '#3b82f6',
      prd: 'Full template',
      specs: 'Required',
      tdd: 'Enforced',
      qualityGates: '+ Pre-deploy',
      agents: '2-4',
      wip: '4',
      dimensions: 14,
      dimensionsLabel: '14 of 18 active'
    },
    {
      id: 'ga',
      name: 'GA',
      color: '#b00149',
      prd: 'Full + architecture',
      specs: '+ Acceptance criteria',
      tdd: 'Strict',
      qualityGates: 'All 5 levels',
      agents: '3-5',
      wip: '5',
      dimensions: 18,
      dimensionsLabel: '18 of 18 active'
    }
  ];

  var TOTAL_DIMENSIONS = 18;

  var PROPERTIES = [
    { key: 'prd', label: 'PRD' },
    { key: 'specs', label: 'Specs' },
    { key: 'tdd', label: 'TDD' },
    { key: 'qualityGates', label: 'Quality Gates' },
    { key: 'agents', label: 'Agents' },
    { key: 'wip', label: 'WIP' }
  ];

  function init() {
    var container = document.getElementById('maturity-slider');
    if (!container) return;

    // Inject scoped styles
    var style = document.createElement('style');
    style.textContent = getStyles();
    document.head.appendChild(style);

    // Build DOM
    container.innerHTML = '';
    container.setAttribute('role', 'group');
    container.setAttribute('aria-label', 'Maturity level selector');

    var wrapper = el('div', 'ms-wrapper');

    // Slider track area
    var sliderArea = el('div', 'ms-slider-area');
    sliderArea.setAttribute('role', 'slider');
    sliderArea.setAttribute('aria-label', 'Maturity level');
    sliderArea.setAttribute('aria-valuemin', '0');
    sliderArea.setAttribute('aria-valuemax', '3');
    sliderArea.setAttribute('aria-valuenow', '0');
    sliderArea.setAttribute('aria-valuetext', LEVELS[0].name);
    sliderArea.setAttribute('tabindex', '0');

    var track = el('div', 'ms-track');
    var trackFill = el('div', 'ms-track-fill');
    track.appendChild(trackFill);

    var dotsContainer = el('div', 'ms-dots');
    LEVELS.forEach(function (level, i) {
      var dotWrap = el('div', 'ms-dot-wrap');

      var dot = el('button', 'ms-dot');
      dot.setAttribute('type', 'button');
      dot.setAttribute('aria-label', level.name);
      dot.setAttribute('data-index', i);
      dot.setAttribute('tabindex', '-1');

      var dotLabel = el('span', 'ms-dot-label');
      dotLabel.textContent = level.name;

      dotWrap.appendChild(dot);
      dotWrap.appendChild(dotLabel);
      dotsContainer.appendChild(dotWrap);
    });

    sliderArea.appendChild(track);
    sliderArea.appendChild(dotsContainer);

    // Level name display
    var levelName = el('div', 'ms-level-name');
    levelName.setAttribute('aria-live', 'polite');

    // Property cards grid
    var grid = el('div', 'ms-grid');
    PROPERTIES.forEach(function (prop) {
      var card = el('div', 'ms-card');
      card.setAttribute('data-prop', prop.key);

      var cardLabel = el('div', 'ms-card-label');
      cardLabel.textContent = prop.label;

      var cardValue = el('div', 'ms-card-value');

      card.appendChild(cardLabel);
      card.appendChild(cardValue);
      grid.appendChild(card);
    });

    // Dimensions progress bar
    var progressArea = el('div', 'ms-progress-area');
    var progressLabel = el('div', 'ms-progress-label');
    var progressTrack = el('div', 'ms-progress-track');
    var progressFill = el('div', 'ms-progress-fill');
    progressTrack.appendChild(progressFill);
    progressArea.appendChild(progressLabel);
    progressArea.appendChild(progressTrack);

    wrapper.appendChild(sliderArea);
    wrapper.appendChild(levelName);
    wrapper.appendChild(grid);
    wrapper.appendChild(progressArea);
    container.appendChild(wrapper);

    // State
    var currentIndex = 0;

    function setLevel(index, animate) {
      if (index < 0) index = 0;
      if (index > LEVELS.length - 1) index = LEVELS.length - 1;
      currentIndex = index;
      var level = LEVELS[index];

      // Update ARIA
      sliderArea.setAttribute('aria-valuenow', index);
      sliderArea.setAttribute('aria-valuetext', level.name);

      // Update dots
      var dots = dotsContainer.querySelectorAll('.ms-dot');
      var labels = dotsContainer.querySelectorAll('.ms-dot-label');
      dots.forEach(function (d, i) {
        if (i === index) {
          d.classList.add('ms-dot--active');
          d.style.borderColor = level.color;
          d.style.backgroundColor = level.color;
          d.style.boxShadow = '0 0 0 4px ' + hexToRgba(level.color, 0.25);
        } else {
          d.classList.remove('ms-dot--active');
          d.style.borderColor = '';
          d.style.backgroundColor = '';
          d.style.boxShadow = '';
        }
      });
      labels.forEach(function (lbl, i) {
        if (i === index) {
          lbl.style.color = level.color;
          lbl.style.fontWeight = '700';
        } else {
          lbl.style.color = '';
          lbl.style.fontWeight = '';
        }
      });

      // Track fill
      var pct = LEVELS.length > 1 ? (index / (LEVELS.length - 1)) * 100 : 0;
      trackFill.style.width = pct + '%';
      trackFill.style.backgroundColor = level.color;

      // Level name
      levelName.textContent = level.name;
      levelName.style.color = level.color;

      // Property cards
      PROPERTIES.forEach(function (prop) {
        var card = grid.querySelector('[data-prop="' + prop.key + '"]');
        var val = card.querySelector('.ms-card-value');
        val.textContent = level[prop.key];
        val.style.color = level.color;
      });

      // Progress bar
      progressLabel.textContent = level.dimensionsLabel;
      progressLabel.style.color = level.color;
      var fillPct = (level.dimensions / TOTAL_DIMENSIONS) * 100;
      progressFill.style.width = fillPct + '%';
      progressFill.style.backgroundColor = level.color;
    }

    // Event handlers — dot clicks
    dotsContainer.addEventListener('click', function (e) {
      var dot = e.target.closest('.ms-dot');
      if (!dot) return;
      var idx = parseInt(dot.getAttribute('data-index'), 10);
      setLevel(idx, true);
      sliderArea.focus();
    });

    // Keyboard navigation
    sliderArea.addEventListener('keydown', function (e) {
      var handled = false;
      if (e.key === 'ArrowRight' || e.key === 'ArrowUp') {
        setLevel(currentIndex + 1, true);
        handled = true;
      } else if (e.key === 'ArrowLeft' || e.key === 'ArrowDown') {
        setLevel(currentIndex - 1, true);
        handled = true;
      } else if (e.key === 'Home') {
        setLevel(0, true);
        handled = true;
      } else if (e.key === 'End') {
        setLevel(LEVELS.length - 1, true);
        handled = true;
      }
      if (handled) {
        e.preventDefault();
      }
    });

    // Touch/mouse drag on the track area
    var dragging = false;

    function getIndexFromPointer(clientX) {
      var rect = dotsContainer.getBoundingClientRect();
      var x = clientX - rect.left;
      var pct = x / rect.width;
      var idx = Math.round(pct * (LEVELS.length - 1));
      return Math.max(0, Math.min(LEVELS.length - 1, idx));
    }

    sliderArea.addEventListener('mousedown', function (e) {
      dragging = true;
      setLevel(getIndexFromPointer(e.clientX), true);
      e.preventDefault();
    });

    document.addEventListener('mousemove', function (e) {
      if (!dragging) return;
      setLevel(getIndexFromPointer(e.clientX), true);
    });

    document.addEventListener('mouseup', function () {
      dragging = false;
    });

    sliderArea.addEventListener('touchstart', function (e) {
      dragging = true;
      if (e.touches.length) {
        setLevel(getIndexFromPointer(e.touches[0].clientX), true);
      }
    }, { passive: true });

    sliderArea.addEventListener('touchmove', function (e) {
      if (!dragging) return;
      if (e.touches.length) {
        setLevel(getIndexFromPointer(e.touches[0].clientX), true);
      }
    }, { passive: true });

    sliderArea.addEventListener('touchend', function () {
      dragging = false;
    });

    // Initial render
    setLevel(0, false);
  }

  // Helpers
  function el(tag, cls) {
    var node = document.createElement(tag);
    if (cls) node.className = cls;
    return node;
  }

  function hexToRgba(hex, alpha) {
    var r = parseInt(hex.slice(1, 3), 16);
    var g = parseInt(hex.slice(3, 5), 16);
    var b = parseInt(hex.slice(5, 7), 16);
    return 'rgba(' + r + ',' + g + ',' + b + ',' + alpha + ')';
  }

  function getStyles() {
    return [
      '.ms-wrapper {',
      '  max-width: 640px;',
      '  margin: 0 auto;',
      '  padding: 24px 0;',
      '  font-family: inherit;',
      '}',

      /* Slider area */
      '.ms-slider-area {',
      '  position: relative;',
      '  padding: 12px 0;',
      '  cursor: pointer;',
      '  outline: none;',
      '  -webkit-tap-highlight-color: transparent;',
      '}',
      '.ms-slider-area:focus-visible .ms-dot--active {',
      '  outline: 2px solid var(--text-primary, #212529);',
      '  outline-offset: 3px;',
      '}',

      /* Track */
      '.ms-track {',
      '  position: absolute;',
      '  top: 50%;',
      '  left: 24px;',
      '  right: 24px;',
      '  height: 4px;',
      '  background: var(--border, #e9ecef);',
      '  border-radius: 2px;',
      '  transform: translateY(-14px);',
      '  pointer-events: none;',
      '}',
      '.ms-track-fill {',
      '  height: 100%;',
      '  width: 0;',
      '  border-radius: 2px;',
      '  transition: width 0.35s ease, background-color 0.35s ease;',
      '}',

      /* Dots container */
      '.ms-dots {',
      '  display: flex;',
      '  justify-content: space-between;',
      '  position: relative;',
      '  padding: 0 2px;',
      '}',

      /* Dot wrapper */
      '.ms-dot-wrap {',
      '  display: flex;',
      '  flex-direction: column;',
      '  align-items: center;',
      '  gap: 10px;',
      '  z-index: 1;',
      '}',

      /* Dot */
      '.ms-dot {',
      '  width: 28px;',
      '  height: 28px;',
      '  min-width: 44px;',
      '  min-height: 44px;',
      '  padding: 0;',
      '  border-radius: 50%;',
      '  border: 3px solid var(--border, #e9ecef);',
      '  background: var(--card-bg, #ffffff);',
      '  cursor: pointer;',
      '  transition: all 0.3s ease;',
      '  position: relative;',
      '  box-sizing: border-box;',
      '}',
      '.ms-dot--active {',
      '  transform: scale(1.25);',
      '}',

      /* Dot label */
      '.ms-dot-label {',
      '  font-size: 13px;',
      '  font-weight: 500;',
      '  color: var(--text-secondary, #6c757d);',
      '  transition: color 0.3s ease, font-weight 0.3s ease;',
      '  user-select: none;',
      '}',

      /* Level name */
      '.ms-level-name {',
      '  text-align: center;',
      '  font-size: 36px;',
      '  font-weight: 800;',
      '  letter-spacing: -0.5px;',
      '  margin: 20px 0 24px;',
      '  transition: color 0.35s ease;',
      '}',

      /* Property grid */
      '.ms-grid {',
      '  display: grid;',
      '  grid-template-columns: repeat(3, 1fr);',
      '  gap: 12px;',
      '  margin-bottom: 24px;',
      '}',
      '@media (max-width: 480px) {',
      '  .ms-grid {',
      '    grid-template-columns: repeat(2, 1fr);',
      '  }',
      '}',

      /* Property card */
      '.ms-card {',
      '  background: var(--card-bg, #ffffff);',
      '  border: 1px solid var(--border, #e9ecef);',
      '  border-radius: 12px;',
      '  padding: 16px;',
      '  text-align: center;',
      '  transition: transform 0.25s ease, box-shadow 0.25s ease;',
      '}',
      '.ms-card:hover {',
      '  transform: translateY(-2px);',
      '  box-shadow: 0 4px 12px rgba(0,0,0,0.08);',
      '}',
      '.ms-card-label {',
      '  font-size: 12px;',
      '  font-weight: 600;',
      '  text-transform: uppercase;',
      '  letter-spacing: 0.5px;',
      '  color: var(--text-secondary, #6c757d);',
      '  margin-bottom: 6px;',
      '}',
      '.ms-card-value {',
      '  font-size: 16px;',
      '  font-weight: 700;',
      '  transition: color 0.35s ease;',
      '}',

      /* Progress area */
      '.ms-progress-area {',
      '  margin-top: 4px;',
      '}',
      '.ms-progress-label {',
      '  font-size: 14px;',
      '  font-weight: 600;',
      '  margin-bottom: 8px;',
      '  text-align: center;',
      '  transition: color 0.35s ease;',
      '}',
      '.ms-progress-track {',
      '  height: 10px;',
      '  background: var(--border, #e9ecef);',
      '  border-radius: 5px;',
      '  overflow: hidden;',
      '}',
      '.ms-progress-fill {',
      '  height: 100%;',
      '  width: 0;',
      '  border-radius: 5px;',
      '  transition: width 0.5s ease, background-color 0.35s ease;',
      '}'
    ].join('\n');
  }

  // Initialize when DOM is ready
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', init);
  } else {
    init();
  }
})();
