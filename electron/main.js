// Головний процес Electron. Створює одне вікно й вмикає <webview>.
// Запуск:  npm install  &&  npm start
const { app, BrowserWindow, Menu } = require('electron');
const path = require('path');

function createWindow() {
  const win = new BrowserWindow({
    width: 1600,
    height: 1000,
    backgroundColor: '#000000',
    title: 'Карти повітряних тривог',
    icon: path.join(__dirname, 'icon.png'),   // Windows/Linux іконка вікна
    webPreferences: {
      webviewTag: true,        // дозволяє <webview> — справжній top-level контекст,
      contextIsolation: true,  // тож X-Frame-Options / frame-ancestors не блокують карти
      nodeIntegration: false,
    },
  });
  win.loadFile('index.html');
  return win;
}

// Мінімальне меню: повний екран (F11) та вихід. Оновлення карт робить renderer.js.
function buildMenu() {
  const template = [
    {
      label: 'AlertsGrid',
      submenu: [
        {
          label: 'На весь екран',
          accelerator: 'F11',
          click: (_item, win) => { if (win) win.setFullScreen(!win.isFullScreen()); },
        },
        { type: 'separator' },
        { role: 'quit', label: 'Вийти' },
      ],
    },
  ];
  Menu.setApplicationMenu(Menu.buildFromTemplate(template));
}

app.whenReady().then(() => {
  buildMenu();
  createWindow();
  app.on('activate', () => {
    if (BrowserWindow.getAllWindows().length === 0) createWindow();
  });
});

app.on('window-all-closed', () => {
  if (process.platform !== 'darwin') app.quit();
});
