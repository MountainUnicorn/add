/**
 * Boids Flocking Animation for ADD Website
 *
 * Implements classic boids rules (separation, alignment, cohesion) to create
 * an organic flocking animation that evokes AI agents coordinating and
 * executing in parallel.
 *
 * Expects a <canvas id="boids-canvas"> element in the DOM.
 * No external dependencies.
 */
(function () {
  'use strict';

  var canvas = document.getElementById('boids-canvas');
  if (!canvas) return;

  var ctx = canvas.getContext('2d');
  if (!ctx) return;

  // --- Configuration ---

  var BOID_COUNT = 50;
  var BOID_RADIUS = 2.5;
  var BOID_COLOR = 'rgba(176, 1, 73, 0.4)';
  var LINE_COLOR = 'rgba(176, 1, 73, 0.08)';
  var TRAIL_COLOR = 'rgba(15, 15, 35, 0.15)';
  var CONNECTION_DISTANCE = 80;
  var MAX_SPEED = 1.8;
  var MIN_SPEED = 0.6;

  // Boid rule weights
  var SEPARATION_RADIUS = 28;
  var ALIGNMENT_RADIUS = 60;
  var COHESION_RADIUS = 80;
  var SEPARATION_WEIGHT = 0.05;
  var ALIGNMENT_WEIGHT = 0.04;
  var COHESION_WEIGHT = 0.008;

  // Cluster pulse configuration
  var CLUSTER_INTERVAL_MIN = 4000; // ms
  var CLUSTER_INTERVAL_MAX = 8000; // ms
  var CLUSTER_DURATION = 1800; // ms
  var CLUSTER_COHESION_MULTIPLIER = 6;

  // --- State ---

  var boids = [];
  var width = 0;
  var height = 0;
  var clusterActive = false;
  var clusterTimer = null;
  var clusterEnd = 0;

  // --- Vector helpers ---

  function vec(x, y) {
    return { x: x, y: y };
  }

  function add(a, b) {
    return vec(a.x + b.x, a.y + b.y);
  }

  function sub(a, b) {
    return vec(a.x - b.x, a.y - b.y);
  }

  function scale(v, s) {
    return vec(v.x * s, v.y * s);
  }

  function mag(v) {
    return Math.sqrt(v.x * v.x + v.y * v.y);
  }

  function limit(v, max) {
    var m = mag(v);
    if (m > max) {
      return scale(v, max / m);
    }
    return v;
  }

  function ensureMinSpeed(v, min) {
    var m = mag(v);
    if (m < min && m > 0.001) {
      return scale(v, min / m);
    }
    if (m <= 0.001) {
      var angle = Math.random() * Math.PI * 2;
      return vec(Math.cos(angle) * min, Math.sin(angle) * min);
    }
    return v;
  }

  /**
   * Compute the shortest displacement from a to b in toroidal space.
   */
  function toroidalDelta(a, b) {
    var dx = b.x - a.x;
    var dy = b.y - a.y;

    if (dx > width / 2) dx -= width;
    else if (dx < -width / 2) dx += width;

    if (dy > height / 2) dy -= height;
    else if (dy < -height / 2) dy += height;

    return vec(dx, dy);
  }

  function toroidalDist(a, b) {
    var d = toroidalDelta(a, b);
    return mag(d);
  }

  // --- Boid creation ---

  function createBoid() {
    var angle = Math.random() * Math.PI * 2;
    var speed = MIN_SPEED + Math.random() * (MAX_SPEED - MIN_SPEED);
    return {
      pos: vec(Math.random() * width, Math.random() * height),
      vel: vec(Math.cos(angle) * speed, Math.sin(angle) * speed)
    };
  }

  // --- Boid rules ---

  function separation(boid) {
    var steer = vec(0, 0);
    var count = 0;

    for (var i = 0; i < boids.length; i++) {
      var other = boids[i];
      if (other === boid) continue;

      var delta = toroidalDelta(other.pos, boid.pos);
      var d = mag(delta);

      if (d > 0 && d < SEPARATION_RADIUS) {
        // Steer away, weighted by inverse distance
        var repulse = scale(delta, 1 / (d * d));
        steer = add(steer, repulse);
        count++;
      }
    }

    if (count > 0) {
      steer = scale(steer, 1 / count);
    }

    return scale(steer, SEPARATION_WEIGHT);
  }

  function alignment(boid) {
    var avgVel = vec(0, 0);
    var count = 0;

    for (var i = 0; i < boids.length; i++) {
      var other = boids[i];
      if (other === boid) continue;

      var d = toroidalDist(boid.pos, other.pos);

      if (d < ALIGNMENT_RADIUS) {
        avgVel = add(avgVel, other.vel);
        count++;
      }
    }

    if (count > 0) {
      avgVel = scale(avgVel, 1 / count);
      var steer = sub(avgVel, boid.vel);
      return scale(steer, ALIGNMENT_WEIGHT);
    }

    return vec(0, 0);
  }

  function cohesion(boid) {
    var center = vec(0, 0);
    var count = 0;

    for (var i = 0; i < boids.length; i++) {
      var other = boids[i];
      if (other === boid) continue;

      var delta = toroidalDelta(boid.pos, other.pos);
      var d = mag(delta);

      if (d < COHESION_RADIUS) {
        center = add(center, delta);
        count++;
      }
    }

    if (count > 0) {
      center = scale(center, 1 / count);
      var weight = COHESION_WEIGHT;
      if (clusterActive) {
        weight *= CLUSTER_COHESION_MULTIPLIER;
      }
      return scale(center, weight);
    }

    return vec(0, 0);
  }

  // --- Cluster pulse scheduling ---

  function scheduleCluster() {
    var delay = CLUSTER_INTERVAL_MIN +
      Math.random() * (CLUSTER_INTERVAL_MAX - CLUSTER_INTERVAL_MIN);

    clusterTimer = setTimeout(function () {
      clusterActive = true;
      clusterEnd = performance.now() + CLUSTER_DURATION;
      scheduleCluster();
    }, delay);
  }

  // --- Resize handling ---

  function resize() {
    var parent = canvas.parentElement;
    if (!parent) return;

    var rect = parent.getBoundingClientRect();
    var dpr = window.devicePixelRatio || 1;

    width = rect.width;
    height = rect.height;

    canvas.width = width * dpr;
    canvas.height = height * dpr;
    canvas.style.width = width + 'px';
    canvas.style.height = height + 'px';

    ctx.setTransform(dpr, 0, 0, dpr, 0, 0);
  }

  // --- Main loop ---

  function update() {
    // Check if cluster pulse has expired
    if (clusterActive && performance.now() > clusterEnd) {
      clusterActive = false;
    }

    for (var i = 0; i < boids.length; i++) {
      var boid = boids[i];

      var sep = separation(boid);
      var ali = alignment(boid);
      var coh = cohesion(boid);

      boid.vel = add(boid.vel, sep);
      boid.vel = add(boid.vel, ali);
      boid.vel = add(boid.vel, coh);

      boid.vel = limit(boid.vel, MAX_SPEED);
      boid.vel = ensureMinSpeed(boid.vel, MIN_SPEED);

      boid.pos = add(boid.pos, boid.vel);

      // Wrap around edges (toroidal)
      if (boid.pos.x < 0) boid.pos.x += width;
      if (boid.pos.x >= width) boid.pos.x -= width;
      if (boid.pos.y < 0) boid.pos.y += height;
      if (boid.pos.y >= height) boid.pos.y -= height;
    }
  }

  function draw() {
    // Trail effect: semi-transparent overlay instead of full clear
    ctx.fillStyle = TRAIL_COLOR;
    ctx.fillRect(0, 0, width, height);

    // Draw connection lines between nearby boids
    ctx.strokeStyle = LINE_COLOR;
    ctx.lineWidth = 1;

    for (var i = 0; i < boids.length; i++) {
      for (var j = i + 1; j < boids.length; j++) {
        var delta = toroidalDelta(boids[i].pos, boids[j].pos);
        var d = mag(delta);

        if (d < CONNECTION_DISTANCE) {
          // Only draw if the connection does not wrap across edges
          // (avoids lines spanning the entire canvas)
          var dx = Math.abs(boids[j].pos.x - boids[i].pos.x);
          var dy = Math.abs(boids[j].pos.y - boids[i].pos.y);

          if (dx < CONNECTION_DISTANCE && dy < CONNECTION_DISTANCE) {
            ctx.beginPath();
            ctx.moveTo(boids[i].pos.x, boids[i].pos.y);
            ctx.lineTo(boids[j].pos.x, boids[j].pos.y);
            ctx.stroke();
          }
        }
      }
    }

    // Draw boids
    ctx.fillStyle = BOID_COLOR;

    for (var k = 0; k < boids.length; k++) {
      ctx.beginPath();
      ctx.arc(boids[k].pos.x, boids[k].pos.y, BOID_RADIUS, 0, Math.PI * 2);
      ctx.fill();
    }
  }

  function loop() {
    update();
    draw();
    requestAnimationFrame(loop);
  }

  // --- Initialize ---

  function init() {
    resize();

    boids = [];
    for (var i = 0; i < BOID_COUNT; i++) {
      boids.push(createBoid());
    }

    window.addEventListener('resize', resize);
    scheduleCluster();
    requestAnimationFrame(loop);
  }

  // Start when the DOM is ready
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', init);
  } else {
    init();
  }
})();
