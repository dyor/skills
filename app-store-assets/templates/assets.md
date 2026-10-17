# <App Name>: app store assets

Settings for the `app-store-assets` skill. The skill is a generic template; everything
specific to this app lives here. Edit this file, not the skill.

## Config

```json
{
  "app": "<App Name>",
  "media_dir": "distribution/media",
  "style": {
    "background": "#1F6B35",
    "headline": "#FFFFFF",
    "accent": "#FFCC33",
    "subline": "#DEEEE2",
    "font": "/System/Library/Fonts/Avenir Next.ttc",
    "headline_font_index": 0,
    "subline_font_index": 5,
    "status_bar_px": 150
  },
  "outputs": {
    "ios": {
      "dir": "distribution/ios/appstore_metadata/screenshots/en-US",
      "size": [1290, 2796],
      "name": "{n:02d}_{id}.png"
    },
    "play": {
      "dir": "distribution/android/playstore_metadata/en-US/images/phoneScreenshots",
      "size": [1440, 2880],
      "name": "{n}.png"
    }
  },
  "text": {
    "ios": "distribution/ios/appstore_metadata/texts/en-US",
    "play": "distribution/android/playstore_metadata/en-US"
  },
  "website": {
    "provider": "febak",
    "site": "<app>.example.com",
    "static_repo": "~/path/to/website-repo",
    "static_dir": "public/_static/<app>",
    "url_prefix": "/_static/<app>",
    "width": 1179
  },
  "shots": [
    {
      "id": "home",
      "screen": "Home screen with realistic data loaded",
      "headline": "Everything in *one place*",
      "subline": "A one-line explanation of the benefit"
    },
    {
      "id": "main-feature",
      "screen": "The core feature in use",
      "headline": "Do the main thing *fast*",
      "subline": "Why it matters to the user"
    }
  ],
  "capture_notes": "Which device to use and what data to load before capturing."
}
```

Sizes: 1290x2796 is the App Store's iPhone 6.9" size; Play accepts at most a 2:1 ratio,
hence 1440x2880. Remove `website` if the app has no site, or `text` entries you don't use.

## Notes for the agent

- **Store upload:** how this app's screenshots and text reach the stores (e.g. fastlane
  `deliver` / `supply`, or a release tool).
- **Privacy:** screens that can show personal data, and what to blur.
- **Website:** how images are published and how the site's screenshot list and copy are
  updated (for Febak: commit to `static_repo`, push to deploy, then the Febak MCP
  `update_site` → `product.screenshots`).
