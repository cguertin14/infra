# Media Platform

## Arr PostgreSQL databases

Radarr, Sonarr, and Prowlarr use individual CloudNativePG clusters. The app
deployments connect to PostgreSQL using credentials stored in SOPS-encrypted
Secrets. PostgreSQL data is separate from the existing app config PVCs, which
remain mounted at `/config` and retain each app's XML settings and SQLite files.

The first PostgreSQL startup initializes fresh databases and each Arr app uses
those databases once this change is deployed. The existing SQLite files remain
on the config PVCs as a fallback, but are not imported automatically. Servarr
documents SQLite-to-PostgreSQL imports as unsupported. Exported `config.xml`
files contain app/server settings only, not library, indexer, download-client,
history, quality profile, tag, or other application database state; configure
those again in the app after the PostgreSQL-backed instance starts.

Servarr does not back up PostgreSQL databases. Back up the CloudNativePG
clusters separately before relying on them as the sole app database.

## Radarr, Sonarr, Prowlarr & Sabnzbd

Before deploying these, comment out the http routes in [here](./resources/httproutes.yml). 
Deploy the kustomize stack, then port-forward each of them to configure their settings (especially auth).

## Prowlarr Setup

Fill in the indexers, including 
1. https://nzbgeek.info/dashboard.php
2. https://nzb.su/profile
3. https://www.nzb.life/
4. https://nzbfinder.ws/

## Sabnzbd Setup

### Usenet Provider

Provider is news.newshosting.com, SSL on port 563. Credentials can be found on https://controlpanel.newshosting.com/customer/.

## Jellyfin Setup

### Hardware Acceleration

Official setup guide is [here](https://jellyfin.org/docs/general/administration/hardware-acceleration/intel/#configure-with-linux-virtualization), this is already done through [this](./patches/jellyfin-intel-quick-sync-patch.yml). Simply enable it in the Jellyfin UI, in Playback settings.

## Known Issues

### Jellyfin

Currently, in versions <10.9.0, DTS-enabled livefeeds have no sound. This is fixed in version 10.9.0, which is unreleased.
In that version, simply enable `Ignore DTS` in playback settings.
