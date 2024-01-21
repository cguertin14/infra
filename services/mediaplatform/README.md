# Media Platform

## Radarr, Sonarr, Qbittorrent, Prowlarr & Sabnzbd

Before deploying these, comment out the ingresses in [here](./resources/ingresses.yml). 
Deploy the kustomize stack, then port-forward each of them to configure their settings (especially auth).

## Prowlarr Setup

Fill in the indexers, including https://nzbgeek.info/dashboard.php.

## Sabnzbd Setup

### Usenet Provider

Provider is news.newshosting.com, SSL on port 563. Credentials can be found on https://controlpanel.newshosting.com/customer/.

## Jellyfin Setup

### Hardware Acceleration

Official setup guide is [here](https://jellyfin.org/docs/general/administration/hardware-acceleration/intel/#configure-with-linux-virtualization), this is already done through [this](./patches/jellyfin-intel-quick-sync-patch.yml). Simply enable it in the Jellyfin UI, in Playback settings.

### IPTV Providers

Head over to https://epg.best/, log in.

1. Copy `My EPG XML link`, then add it as a new `TV Guide Data Provider` in Jellyfin
2. Copy all the `m3u` links, then add them as individual m3u `Tuner Devices` in Jellyfin.

## Known Issues

### Jellyfin

Currently, in versions <10.9.0, DTS-enabled livefeeds have no sound. This is fixed in version 10.9.0, which is unreleased.
In that version, simply enable `Ignore DTS` in playback settings.