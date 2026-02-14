/* ===== ADD — Engagement Mode Toggle ===== */

(function () {
  'use strict';

  var root = document.getElementById('engagement-toggle');
  if (!root) return;

  /* ---------- Mode data ---------- */

  var modes = [
    {
      id: 'guided',
      label: 'Guided',
      color: '#6366f1',
      iconClass: 'ph ph-user',
      tagline: 'Human approves each step',
      permissions: [
        { action: 'Read files', allowed: true },
        { action: 'Write files', allowed: false, note: 'Requires approval' },
        { action: 'Run tests', allowed: true },
        { action: 'Git commit', allowed: false, note: 'Requires approval' },
        { action: 'Deploy', allowed: false, note: 'Requires approval' },
        { action: 'Architecture decisions', allowed: false, note: 'Requires approval' }
      ],
      humanRole: 'Reviews every file change, approves each commit, makes all architecture decisions',
      agentRole: 'Proposes changes, waits for approval before acting, explains reasoning'
    },
    {
      id: 'balanced',
      label: 'Balanced',
      color: '#b00149',
      iconClass: 'ph ph-handshake',
      tagline: 'Human at decision points',
      permissions: [
        { action: 'Read files', allowed: true },
        { action: 'Write files', allowed: true },
        { action: 'Run tests', allowed: true },
        { action: 'Git commit', allowed: true },
        { action: 'Deploy', allowed: false, note: 'Requires approval' },
        { action: 'Architecture decisions', allowed: false, note: 'Pauses for interview' }
      ],
      humanRole: 'Sets direction via specs, resolves ambiguity at decision points, approves deploys',
      agentRole: 'Executes TDD cycles independently, pauses at forks, follows spec boundaries'
    },
    {
      id: 'autonomous',
      label: 'Autonomous',
      color: '#22c55e',
      iconClass: 'ph ph-robot',
      tagline: 'Human sets boundaries, walks away',
      permissions: [
        { action: 'Read files', allowed: true },
        { action: 'Write files', allowed: true },
        { action: 'Run tests', allowed: true },
        { action: 'Git commit', allowed: true },
        { action: 'Deploy', allowed: true, note: 'Up to staging' },
        { action: 'Architecture decisions', allowed: true, note: 'Within spec scope' }
      ],
      humanRole: 'Defines scope and boundaries upfront, reviews briefing on return',
      agentRole: 'Full autonomous execution: TDD, commit, push, deploy to staging, log all decisions'
    }
  ];

  var activeIndex = 1; /* default: Balanced */

  /* ---------- Inject scoped CSS ---------- */

  var style = document.createElement('style');
  style.textContent = [
    '.et-container { font-family: var(--font-sans, -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif); }',

    /* Toggle bar */
    '.et-toggle-bar { display: flex; gap: 4px; background: var(--bg-secondary, #f1f5f9); border-radius: 12px; padding: 4px; }',
    '.et-toggle-btn { flex: 1; display: flex; align-items: center; justify-content: center; gap: 8px; padding: 10px 16px; border: none; border-radius: 10px; cursor: pointer; font-size: 0.95rem; font-weight: 600; background: transparent; color: var(--text-secondary, #64748b); transition: background 0.25s, color 0.25s, box-shadow 0.25s; }',
    '.et-toggle-btn:hover { background: var(--bg-tertiary, #e2e8f0); color: var(--text-primary, #1e293b); }',
    '.et-toggle-btn.et-active { color: #fff; box-shadow: 0 2px 8px rgba(0,0,0,0.15); }',
    '.et-toggle-btn.et-active:hover { opacity: 0.92; }',
    '.et-toggle-btn i { font-size: 1.1rem; }',

    /* Content panel */
    '.et-panel { margin-top: 20px; display: flex; gap: 24px; transition: opacity 0.25s ease; }',
    '.et-panel.et-fading { opacity: 0; }',

    /* Permissions grid */
    '.et-permissions { flex: 0 0 60%; }',
    '.et-permissions-heading { font-size: 0.8rem; font-weight: 700; text-transform: uppercase; letter-spacing: 0.05em; color: var(--text-tertiary, #94a3b8); margin: 0 0 12px; }',
    '.et-perm-row { display: flex; align-items: center; justify-content: space-between; padding: 10px 12px; border-radius: 8px; margin-bottom: 4px; background: var(--bg-secondary, #f8fafc); }',
    '.et-perm-row:nth-child(even) { background: var(--bg-tertiary, #f1f5f9); }',
    '.et-perm-action { font-size: 0.9rem; font-weight: 500; color: var(--text-primary, #1e293b); }',
    '.et-perm-status { display: flex; align-items: center; gap: 6px; font-size: 0.85rem; }',
    '.et-perm-status i { font-size: 1.15rem; }',
    '.et-perm-status .et-allowed { color: #22c55e; }',
    '.et-perm-status .et-denied { color: #ef4444; }',
    '.et-perm-status .et-approval { color: #f59e0b; }',
    '.et-perm-note { color: var(--text-tertiary, #94a3b8); font-size: 0.8rem; }',

    /* Role cards */
    '.et-roles { flex: 0 0 calc(40% - 24px); display: flex; flex-direction: column; gap: 16px; }',
    '.et-role-card { padding: 16px 18px; border-radius: 10px; background: var(--bg-secondary, #f8fafc); border-left: 3px solid var(--text-tertiary, #94a3b8); }',
    '.et-role-card-heading { font-size: 0.8rem; font-weight: 700; text-transform: uppercase; letter-spacing: 0.05em; color: var(--text-tertiary, #94a3b8); margin: 0 0 8px; }',
    '.et-role-card p { margin: 0; font-size: 0.9rem; line-height: 1.55; color: var(--text-secondary, #475569); }',

    /* Tagline */
    '.et-tagline { margin-top: 20px; text-align: center; font-size: 1.15rem; font-weight: 600; transition: color 0.25s ease; }',

    /* Responsive */
    '@media (max-width: 600px) {',
    '  .et-panel { flex-direction: column; }',
    '  .et-permissions { flex: none; }',
    '  .et-roles { flex: none; }',
    '}'
  ].join('\n');
  document.head.appendChild(style);

  /* ---------- Render ---------- */

  function render() {
    var mode = modes[activeIndex];

    /* Toggle bar */
    var toggleBarHTML = '<div class="et-toggle-bar">';
    for (var i = 0; i < modes.length; i++) {
      var m = modes[i];
      var isActive = i === activeIndex;
      var btnStyle = isActive
        ? 'background:' + m.color + ';color:#fff;'
        : '';
      toggleBarHTML +=
        '<button class="et-toggle-btn' + (isActive ? ' et-active' : '') + '"'
        + ' data-index="' + i + '"'
        + ' style="' + btnStyle + '">'
        + '<i class="' + m.iconClass + '"></i> '
        + m.label
        + '</button>';
    }
    toggleBarHTML += '</div>';

    /* Permissions grid */
    var permsHTML = '<div class="et-permissions">'
      + '<p class="et-permissions-heading">Permissions</p>';
    for (var j = 0; j < mode.permissions.length; j++) {
      var perm = mode.permissions[j];
      var statusHTML;
      if (perm.allowed && !perm.note) {
        statusHTML = '<i class="ph ph-check-circle et-allowed"></i>';
      } else if (perm.allowed && perm.note) {
        statusHTML = '<i class="ph ph-check-circle et-allowed"></i>'
          + '<span class="et-perm-note">' + perm.note + '</span>';
      } else if (!perm.allowed && perm.note) {
        statusHTML = '<i class="ph ph-clock et-approval"></i>'
          + '<span class="et-perm-note">' + perm.note + '</span>';
      } else {
        statusHTML = '<i class="ph ph-x-circle et-denied"></i>';
      }
      permsHTML +=
        '<div class="et-perm-row">'
        + '<span class="et-perm-action">' + perm.action + '</span>'
        + '<span class="et-perm-status">' + statusHTML + '</span>'
        + '</div>';
    }
    permsHTML += '</div>';

    /* Role cards */
    var rolesHTML = '<div class="et-roles">'
      + '<div class="et-role-card" style="border-left-color:' + mode.color + ';">'
      + '<p class="et-role-card-heading">Human Role</p>'
      + '<p>' + mode.humanRole + '</p>'
      + '</div>'
      + '<div class="et-role-card" style="border-left-color:' + mode.color + ';">'
      + '<p class="et-role-card-heading">Agent Role</p>'
      + '<p>' + mode.agentRole + '</p>'
      + '</div>'
      + '</div>';

    /* Panel */
    var panelHTML = '<div class="et-panel" id="et-panel">'
      + permsHTML + rolesHTML
      + '</div>';

    /* Tagline */
    var taglineHTML = '<p class="et-tagline" style="color:' + mode.color + ';">'
      + mode.tagline + '</p>';

    root.innerHTML =
      '<div class="et-container">'
      + toggleBarHTML
      + panelHTML
      + taglineHTML
      + '</div>';

    /* Bind toggle buttons */
    var buttons = root.querySelectorAll('.et-toggle-btn');
    for (var k = 0; k < buttons.length; k++) {
      buttons[k].addEventListener('click', handleToggle);
    }
  }

  /* ---------- Toggle handler with fade transition ---------- */

  function handleToggle(e) {
    var btn = e.currentTarget;
    var newIndex = parseInt(btn.getAttribute('data-index'), 10);
    if (newIndex === activeIndex) return;

    var panel = document.getElementById('et-panel');
    if (panel) {
      panel.classList.add('et-fading');
    }

    setTimeout(function () {
      activeIndex = newIndex;
      render();
    }, 250);
  }

  /* ---------- Init ---------- */

  render();
})();
