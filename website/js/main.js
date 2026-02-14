/* ===== ADD — Agent Driven Development — Shared JS ===== */

// Theme toggle
function toggleTheme() {
  const body = document.body;
  if (body.dataset.theme === 'dark') {
    body.removeAttribute('data-theme');
    localStorage.setItem('add-theme', 'light');
  } else {
    body.dataset.theme = 'dark';
    localStorage.setItem('add-theme', 'dark');
  }
}

// Restore theme preference (run immediately)
(function () {
  var saved = localStorage.getItem('add-theme');
  if (saved === 'dark') {
    document.body.dataset.theme = 'dark';
  }
})();

// Mobile nav toggle
document.addEventListener('DOMContentLoaded', function () {
  var toggle = document.querySelector('.nav-toggle');
  var links = document.querySelector('.site-nav-links');
  if (toggle && links) {
    toggle.addEventListener('click', function () {
      links.classList.toggle('open');
    });
    // Close menu when a link is clicked
    links.querySelectorAll('a').forEach(function (a) {
      a.addEventListener('click', function () {
        links.classList.remove('open');
      });
    });
  }

  // Highlight active nav link (most specific match wins)
  var path = window.location.pathname;
  var bestLink = null;
  var bestLen = 0;
  document.querySelectorAll('.site-nav-links a').forEach(function (a) {
    var href = a.getAttribute('href');
    if (!href || href.indexOf('github') !== -1) return;
    if (path === href || (href !== '/' && path.indexOf(href) === 0)) {
      if (href.length > bestLen) {
        bestLen = href.length;
        bestLink = a;
      }
    }
  });
  if (bestLink) bestLink.classList.add('active');

  // Smooth scroll for anchor links
  document.querySelectorAll('a[href^="#"]').forEach(function (anchor) {
    anchor.addEventListener('click', function (e) {
      e.preventDefault();
      var target = document.querySelector(this.getAttribute('href'));
      if (target) {
        target.scrollIntoView({ behavior: 'smooth' });
      }
    });
  });

  // Terminal copy buttons
  document.querySelectorAll('.terminal').forEach(function (terminal) {
    var body = terminal.querySelector('.terminal-body');
    if (!body) return;
    var btn = document.createElement('button');
    btn.className = 'terminal-copy';
    btn.textContent = 'Copy';
    btn.addEventListener('click', function () {
      var text = body.textContent.replace(/^\$\s*/gm, '').trim();
      navigator.clipboard.writeText(text).then(function () {
        btn.textContent = 'Copied!';
        btn.classList.add('copied');
        setTimeout(function () {
          btn.textContent = 'Copy';
          btn.classList.remove('copied');
        }, 2000);
      });
    });
    terminal.insertBefore(btn, terminal.firstChild);
  });
});
