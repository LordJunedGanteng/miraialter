(function () {
  if (!window.electronAPI) return;

  // ── Fullscreen overlay ──────────────────────────────────────────
  const overlay = document.createElement('div');
  overlay.id = 'fs-overlay';
  overlay.innerHTML = `
    <div id="fs-overlay-inner">
      <div id="fs-corner tl"></div>
      <div id="fs-text-wrap">
        <span id="fs-label">ENTERING FULLSCREEN MODE</span>
        <span id="fs-dots"></span>
      </div>
    </div>
  `;

  const ovStyle = document.createElement('style');
  ovStyle.textContent = `
    #fs-overlay {
      position: fixed; inset: 0; z-index: 999998;
      background: #0b0e13;
      display: flex; align-items: center; justify-content: center;
      opacity: 0; pointer-events: none;
      transition: opacity 0.25s ease;
    }
    #fs-overlay.show { opacity: 1; pointer-events: all; }

    #fs-overlay-inner {
      display: flex; flex-direction: column; align-items: center; gap: 20px;
    }

    /* Corner frame lines */
    #fs-overlay-inner::before,
    #fs-overlay-inner::after {
      content: '';
      position: absolute;
      width: 80px; height: 80px;
      border-color: rgba(232,184,75,0.25);
      border-style: solid;
    }
    #fs-overlay-inner::before {
      top: 40px; left: 40px;
      border-width: 1px 0 0 1px;
    }
    #fs-overlay-inner::after {
      bottom: 40px; right: 40px;
      border-width: 0 1px 1px 0;
    }

    #fs-text-wrap {
      display: flex; align-items: baseline; gap: 0;
    }

    #fs-label {
      font-family: 'Inter', sans-serif;
      font-size: 0.75rem;
      font-weight: 700;
      letter-spacing: 0.25em;
      text-transform: uppercase;
      color: #e8b84b;
      opacity: 0;
      transform: translateY(6px);
      transition: opacity 0.35s ease 0.1s, transform 0.35s ease 0.1s;
    }
    #fs-overlay.show #fs-label { opacity: 1; transform: translateY(0); }

    #fs-dots {
      font-family: 'Inter', sans-serif;
      font-size: 0.75rem;
      font-weight: 700;
      letter-spacing: 0.1em;
      color: #e8b84b;
      width: 24px;
      display: inline-block;
    }

    /* Scanline effect */
    #fs-overlay::after {
      content: '';
      position: absolute; inset: 0;
      background: repeating-linear-gradient(
        0deg,
        transparent,
        transparent 2px,
        rgba(0,0,0,0.08) 2px,
        rgba(0,0,0,0.08) 4px
      );
      pointer-events: none;
    }
  `;
  document.head.appendChild(ovStyle);
  document.body.appendChild(overlay);

  // Animate dots
  let _dotInterval = null;
  function startDots() {
    let n = 0;
    const el = document.getElementById('fs-dots');
    _dotInterval = setInterval(() => {
      el.textContent = '.'.repeat((n % 4));
      n++;
    }, 220);
  }
  function stopDots() {
    clearInterval(_dotInterval);
    const el = document.getElementById('fs-dots');
    if (el) el.textContent = '';
  }

  function showFsOverlay() {
    overlay.classList.add('show');
    startDots();
    setTimeout(() => {
      overlay.classList.remove('show');
      stopDots();
    }, 1800);
  }

  // ── Titlebar ────────────────────────────────────────────────────
  const bar = document.createElement('div');
  bar.id = 'electron-titlebar';
  bar.innerHTML = `
    <div id="etb-drag"></div>
    <span id="etb-title">MIRAI ATELIER</span>
    <div id="etb-controls">
      <button id="etb-fs"    title="Fullscreen">&#9974;</button>
      <button id="etb-min"   title="Minimize">&#8212;</button>
      <button id="etb-max"   title="Maximize">&#9633;</button>
      <button id="etb-close" title="Close">&#10005;</button>
    </div>
  `;

  const barStyle = document.createElement('style');
  barStyle.textContent = `
    #electron-titlebar {
      position: fixed;
      top: 0; left: 0; right: 0;
      height: 38px;
      background: #0b0e13;
      display: flex;
      align-items: center;
      z-index: 99999;
      -webkit-app-region: drag;
      user-select: none;
      border-bottom: 1px solid rgba(78,70,54,0.15);
      transition: opacity 0.3s ease, transform 0.3s ease;
    }
    /* Hide titlebar in fullscreen — show on mouse near top */
    body.is-fullscreen #electron-titlebar {
      opacity: 0;
      transform: translateY(-100%);
    }
    body.is-fullscreen:has(#electron-titlebar:hover) #electron-titlebar,
    body.is-fullscreen #electron-titlebar:hover {
      opacity: 1;
      transform: translateY(0);
    }
    #etb-drag {
      flex: 1; height: 100%;
      -webkit-app-region: drag;
    }
    #etb-title {
      position: absolute; left: 50%; transform: translateX(-50%);
      font-family: 'Inter', sans-serif;
      font-size: 10px; font-weight: 700;
      letter-spacing: 0.15em; text-transform: uppercase;
      color: #e8b84b; pointer-events: none;
    }
    #etb-controls {
      display: flex;
      -webkit-app-region: no-drag;
    }
    #etb-controls button {
      width: 46px; height: 38px;
      background: none; border: none;
      color: #9b8f7c; font-size: 13px;
      cursor: pointer;
      display: flex; align-items: center; justify-content: center;
      transition: background 0.15s, color 0.15s;
      -webkit-app-region: no-drag;
    }
    #etb-controls button:hover { background: rgba(255,255,255,0.06); color: #e1e2e9; }
    #etb-close:hover { background: #c42b1c !important; color: #fff !important; }
    #etb-fs { font-size: 15px; }

    body { padding-top: 38px !important; }
    body.is-fullscreen { padding-top: 0 !important; }
  `;

  document.head.appendChild(barStyle);
  document.body.insertBefore(bar, document.body.firstChild);

  // Controls
  document.getElementById('etb-min').addEventListener('click', () => window.electronAPI.minimize());
  document.getElementById('etb-max').addEventListener('click', () => window.electronAPI.maximize());
  document.getElementById('etb-close').addEventListener('click', () => window.electronAPI.close());
  document.getElementById('etb-fs').addEventListener('click', () => {
    window.electronAPI.toggleFullscreen();
  });

  // Listen for fullscreen state changes from main process
  window.electronAPI.onFullscreenChange((isFs) => {
    if (isFs) {
      document.body.classList.add('is-fullscreen');
      showFsOverlay();
    } else {
      document.body.classList.remove('is-fullscreen');
    }
  });

  // F11 shortcut
  document.addEventListener('keydown', (e) => {
    if (e.key === 'F11') { e.preventDefault(); window.electronAPI.toggleFullscreen(); }
  });

})();
