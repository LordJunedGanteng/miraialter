const { contextBridge, ipcRenderer } = require('electron');

contextBridge.exposeInMainWorld('electronAPI', {
  minimize:         () => ipcRenderer.send('win-minimize'),
  maximize:         () => ipcRenderer.send('win-maximize'),
  close:            () => ipcRenderer.send('win-close'),
  toggleFullscreen: () => ipcRenderer.send('win-fullscreen'),
  onFullscreenChange: (cb) => ipcRenderer.on('fullscreen-changed', (_e, isFs) => cb(isFs)),
  notify: (title, body) => ipcRenderer.send('win-notify', title, body),
  googleOAuthListen: (port) => ipcRenderer.invoke('google-oauth-listen', port),
});
