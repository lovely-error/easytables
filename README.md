# EasyTables

A lightweight Flutter app for creating, organizing, and visualizing tables of
data. Runs as a Windows desktop app and in the browser.

## Development

```powershell
flutter pub get
flutter run -d windows
flutter run -d chrome
```

## Web deployment

Pushes to `main` build the web app and deploy it to GitHub Pages through
`.github/workflows/deploy-web.yml`.

Before the first deployment, open the repository's **Settings → Pages** and set
**Build and deployment → Source** to **GitHub Actions**. The published URL is
`https://<owner>.github.io/easytables/`.

## Storage

- Windows: `%APPDATA%\EasyTables\library.json`
- Web: the library is stored locally in IndexedDB through Sembast, scoped to the
  site's browser origin.

Web data is per-browser and is not synchronized with the desktop library.
