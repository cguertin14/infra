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

### IPTV Providers

Head over to https://epg.best/, log in.

1. Copy `My EPG XML link`, then add it as a new `TV Guide Data Provider` in Jellyfin
2. Copy all the `m3u` links, then add them as individual m3u `Tuner Devices` in Jellyfin.