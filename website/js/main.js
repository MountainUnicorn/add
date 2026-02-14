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

  // Highlight active nav link
  var path = window.location.pathname;
  document.querySelectorAll('.site-nav-links a').forEach(function (a) {
    var href = a.getAttribute('href');
    if (!href || href.indexOf('github') !== -1) return;
    // Exact match or starts-with for section pages
    if (path === href || (href !== '/' && path.indexOf(href) === 0)) {
      a.classList.add('active');
    }
  });

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
});
