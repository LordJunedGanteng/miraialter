const { app, BrowserWindow, shell, Menu, ipcMain, Notification } = require('electron');
const path = require('path');

Menu.setApplicationMenu(null);

let mainWin = null;

function createSplash() {
  const splash = new BrowserWindow({
    width: 960, height: 540,
    frame: false, alwaysOnTop: true,
    resizable: false, center: true,
    backgroundColor: '#111319',
    icon: path.join(__dirname, 'assets', 'icon.ico'),
    webPreferences: { nodeIntegration: false, contextIsolation: true },
    show: false,
  });

  splash.loadFile(path.join(__dirname, 'splash.html'));
  splash.once('ready-to-show', () => splash.show());
  splash.on('closed', () => createMain());
  return splash;
}

function createMain() {
  mainWin = new BrowserWindow({
    width: 1440, height: 900,
    minWidth: 1024, minHeight: 640,
    frame: false, backgroundColor: '#111319',
    icon: path.join(__dirname, 'assets', 'icon.ico'),
    webPreferences: {
      nodeIntegration: false,
      contextIsolation: true,
      webSecurity: false,
      preload: path.join(__dirname, 'preload.js'),
    },
    show: false,
  });

  mainWin.loadFile(path.join(__dirname, 'login.html'));
  mainWin.once('ready-to-show', () => mainWin.show());

  mainWin.webContents.setWindowOpenHandler(({ url }) => {
    shell.openExternal(url);
    return { action: 'deny' };
  });

  mainWin.on('enter-full-screen', () => mainWin.webContents.send('fullscreen-changed', true));
  mainWin.on('leave-full-screen', () => mainWin.webContents.send('fullscreen-changed', false));
  mainWin.on('closed', () => { mainWin = null; });

  ipcMain.on('win-minimize',   () => mainWin?.minimize());
  ipcMain.on('win-maximize',   () => mainWin?.isMaximized() ? mainWin.unmaximize() : mainWin?.maximize());
  ipcMain.on('win-close',      () => mainWin?.close());
  ipcMain.on('win-fullscreen', () => mainWin?.setFullScreen(!mainWin?.isFullScreen()));

  ipcMain.on('win-notify', (_e, title, body) => {
    if (Notification.isSupported()) {
      new Notification({
        title: title || 'MIRAI ATELIER',
        body:  body  || '',
        icon:  path.join(__dirname, 'assets', 'icon.ico'),
        silent: false,
      }).show();
    }
  });

  const http = require('http');
  let _oauthSrv = null;
  ipcMain.handle('google-oauth-listen', (_e, port) => new Promise(resolve => {
    if (_oauthSrv) { try { _oauthSrv.close(); } catch(e) {} _oauthSrv = null; }
    _oauthSrv = http.createServer((req, res) => {
      const u = new URL(req.url, `http://127.0.0.1:${port}`);
      const code = u.searchParams.get('code'), error = u.searchParams.get('error');
      res.writeHead(200, { 'Content-Type': 'text/html;charset=utf-8' });
      res.end(`<!DOCTYPE html><html><body style="font-family:Inter,sans-serif;background:#111319;color:#e1e2e9;display:flex;flex-direction:column;align-items:center;justify-content:center;height:100vh;margin:0;gap:14px"><div style="font-size:3rem">${code?'✓':'✗'}</div><h2 style="margin:0;color:${code?'#e8b84b':'#f87171'}">${code?'Berhasil!':'Gagal'}</h2><p style="margin:0;color:#9b8f7c;font-size:.875rem">${code?'Kamu bisa menutup tab ini.':error||'Unknown error'}</p></body></html>`);
      if (_oauthSrv) { try { _oauthSrv.close(); } catch(e) {} _oauthSrv = null; }
      resolve({ code: code||null, error: error||null });
    });
    _oauthSrv.on('error', e => resolve({ code: null, error: e.message }));
    _oauthSrv.listen(port, '127.0.0.1');
  }));
}

app.whenReady().then(() => {
  createSplash();
  app.on('activate', () => {
    if (BrowserWindow.getAllWindows().length === 0) createMain();
  });
});

app.on('window-all-closed', () => {
  if (process.platform !== 'darwin') app.quit();
});
