# GitHub Build Badge — KDE Plasma widget

A tiny Plasma 6 panel widget that shows the live build status of a GitHub
Actions workflow as a shields-style badge, e.g. `[ build | passing ]`.

![demo](demo.gif)

## What it does

- Polls the GitHub API for the latest run of a workflow and renders a
  two-tone badge: dark label + colored status.
- Status colors: green `passing`, red `failing`, yellow `running`/`queued`,
  grey `no status`/`cancelled`/`set token`/`offline`.
- Tooltip shows repo · branch · last-updated time.
- The badge shows a strip of colored dots for the recent runs (green pass /
  red fail / yellow running), plus the latest status.
- Click opens a popup with the last 10 workflow runs (each links to its
  GitHub run page), refreshing on open. When the badge shows `set token`,
  clicking opens the settings dialog instead.
- Very compact (~18 px tall) — fits a panel without crowding neighbors.
- Refreshes on a configurable interval (default 5 minutes).

## Files

```
org.yatli.github.buildbadge/
├── metadata.json
├── icon/github-build-badge.svg
└── contents/
    ├── config/
    │   ├── main.xml          # settings schema (repo, workflow, branch, label, interval, token)
    │   └── config.qml        # settings dialog
    └── ui/
        ├── main.qml          # applet logic (PlasmoidItem + API polling)
        ├── Badge.qml         # badge rendering
        └── ConfigGeneral.qml # settings page UI
```

## Install

```sh
# 1. install the applet icon
mkdir -p ~/.local/share/icons/hicolor/scalable/apps
cp org.yatli.github.buildbadge/icon/github-build-badge.svg \
   ~/.local/share/icons/hicolor/scalable/apps/

# 2. install the widget
kpackagetool6 -t Plasma/Applet -i org.yatli.github.buildbadge
# (or `-u` to upgrade an existing install)
```

Then: right-click the panel → **Enter Edit Mode** → **Add Widgets** →
search "GitHub Build Badge" → drag it into your panel.

## Configuration

Right-click the widget → **Configure**:

| Field | Default | Notes |
|---|---|---|
| Repository | *(empty)* | `owner/repo` or full URL |
| Workflow file | *(empty)* | empty = latest run of any workflow |
| Branch | *(empty)* | empty = default branch |
| Badge label | `build` | left side text |
| Refresh every | `5` minutes | |
| GitHub token | *(empty)* | required for **private** repos |

## GitHub token (for private repos)

The widget needs a token to read a private repo. Create a **fine-grained
personal access token** at
<https://github.com/settings/personal-access-tokens/new>:

1. Repository access → **Only select repositories** → choose your repository.
2. Permissions → **Repository permissions** → **Actions** → **Read-only**.
3. Generate and paste the token into the widget's **GitHub token** field.

> ⚠️ The token is stored in plaintext in your Plasma applet config
> (`~/.config/plasma-org.kde.plasma.desktop-appletsrc`). Use a fine-grained
> token scoped to just this repo. Without a token, the widget shows
> `set token` in grey for private repos.

## Reinstall after editing source

```sh
kpackagetool6 -t Plasma/Applet -u org.yatli.github.buildbadge
plasmashell --replace &   # restart Plasma to pick up changes (optional)
```

## Notes

- GitHub API unauthenticated rate limit is 60 req/hour — fine for the
  default 5-minute interval; add a token if you refresh faster.
- Built and verified against Plasma 6.7.
