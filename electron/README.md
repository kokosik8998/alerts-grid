# AlertsGrid (Electron) — кросплатформна версія

Чотири карти повітряних тривог в одному вікні 2×2. Працює на **Windows 11 x64**,
**Raspberry Pi OS (64-bit)** та **macOS**. Кожна карта — це `<webview>` (справжній
браузерний контекст), тож блокування вбудовування (`X-Frame-Options`,
`frame-ancestors`) на неї не діє — показуються всі 4 сайти.

Карти й правила приховування банерів — у масиві `MAPS` на початку `renderer.js`.

---

## Windows 11 (x64)

1. Встанови **Node.js LTS** із https://nodejs.org (інсталятор .msi, 64-bit).
2. Скопіюй теку `electron/` на комп'ютер (напр. у `C:\AlertsGrid`).
3. Відкрий **PowerShell** у цій теці (Shift+ПКМ у теці → «Відкрити вікно PowerShell тут»):

   ```powershell
   npm install
   npm start
   ```

`npm install` сам завантажить потрібну (x64) збірку Electron. Наступні запуски — лише `npm start`.

---

## Raspberry Pi OS (64-bit, з екраном)

Виконувати в терміналі робочого столу Pi (потрібна графічна сесія — Electron показує вікно).

1. Встанови свіжий Node.js LTS (репозиторій apt часто застарілий):

   ```bash
   curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
   sudo apt-get install -y nodejs
   ```

2. Скопіюй теку `electron/` на Pi (напр. `~/alerts-grid`), зайди в неї та запусти:

   ```bash
   cd ~/alerts-grid
   npm install
   npm start
   ```

   `npm install` завантажить збірку Electron під **linux-arm64**.

### Автозапуск як настінний дашборд (необов'язково)

Щоб карти відкривались самі при вході в робочий стіл, створи
`~/.config/autostart/alertsgrid.desktop`:

```ini
[Desktop Entry]
Type=Application
Name=AlertsGrid
Exec=sh -c "cd /home/username/alerts-grid && npm start"
X-GNOME-Autostart-enabled=true
```

Повний екран — клавіша **F11**.

> ⚠️ **Про продуктивність.** Чотири карти Chromium одночасно — відчутне навантаження.
> На Pi 4/5 (2 ГБ+) працює нормально. На **Pi 3B+ (1 ГБ RAM)** може гальмувати або
> не вистачати пам'яті. 

---

## macOS

На Mac у тебе вже є нативний застосунок (`../AlertsGrid.app`). Але за бажання
цей самий Electron-проєкт запускається й тут: `npm install && npm start`.

---

## Керування

- **− / +** у заголовку панелі — масштаб цієї карти (корисно на малих екранах, коли меню не влазить); поточний % показано між кнопками
- Подвійний клік по назві карти — скинути масштаб на 100%
- **Ctrl/Cmd + / − / 0** — масштаб усіх карт одразу (більше / менше / скинути)
- **⟳** у заголовку панелі — оновити одну карту
- **Ctrl/Cmd + R** — оновити всі
- **F11** — повний екран
- Закрити вікно — вийти

Масштаб кожної карти зберігається між запусками.

## Збірка інсталяторів (.exe / AppImage / .deb)

Налаштовано через [electron-builder](https://www.electron.build/). Готові файли
з'являться в теці `dist/`.

> **Важливо:** збирай інсталятор **на тій самій ОС**, під яку він потрібен — так
> найнадійніше, без крос-компіляції. Тобто `.exe` збираємо на Windows, а
> `AppImage`/`.deb` під arm64 — на самій Raspberry Pi (вона arm64, тож і збірка
> вийде arm64 автоматично).

### Windows → `.exe`

У теці проєкту в PowerShell:

```powershell
npm install
npm run dist:win
```

Результат: `dist\AlertsGrid Setup 1.0.0.exe` — звичайний інсталятор (можна обрати
теку встановлення, створює ярлик на робочому столі).

### Windows → портативний ZIP (без інсталяції)

Збирається навіть з macOS/Linux без Wine (вимкнено крок rcedit через
`win.signAndEditExecutable: false`), архітектура x64:

```powershell
npm run dist:win:zip
```

Результат: `dist\AlertsGrid-1.0.0-win.zip` — розпакувати й запустити `AlertsGrid.exe`.
Нюанс: іконка самого `.exe` у Провіднику буде стандартна Electron, але вікно й панель
задач показують нашу іконку. Перший запуск Windows SmartScreen може попередити
(застосунок без підпису) — «Докладніше» → «Виконати в будь-якому разі».

### Raspberry Pi OS (64-bit) → `AppImage` + `.deb`

На самій Pi у теці проєкту:

```bash
npm install
npm run dist:linux
```

Результат у `dist/`:
- `AlertsGrid-1.0.0-arm64.AppImage` — зробити виконуваним (`chmod +x`) і запускати подвійним кліком;
- `alerts-grid_1.0.0_arm64.deb` — встановити через `sudo apt install ./alerts-grid_1.0.0_arm64.deb`.

> Для `.deb`/AppImage electron-builder може попросити пакети `fakeroot` та `dpkg`:
> `sudo apt-get install -y fakeroot dpkg`.

### Зібрати все одразу (на поточній ОС)

```bash
npm run dist
```

> Крос-збірку (напр. `.exe` з Mac/Linux) electron-builder теж уміє, але вона
> потребує Wine/Docker і часто капризує — простіше зібрати нативно на кожній машині.
