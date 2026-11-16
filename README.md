# World IPTV playlist

Public M3U playlist assembled from the public [IPTV-org](https://github.com/iptv-org/iptv) feeds.

It keeps country groups and adds explicit top-level groups for:

- Sports
- Cricket
- Football
- Movies
- Series

## IPTV playlist URL

```text
https://raw.githubusercontent.com/mfaiq07/iptv-world-all-in-one/main/world-all-in-one.m3u
```

In IPTV Smarters, choose **URL Type**, use any playlist name, and paste the URL above.

Public streams can go offline or be geo-restricted. Cricket and Football groups are best-effort matches because IPTV-org classifies both under the broader Sports category.

## Updating

The included `build-merged-iptv.ps1` script rebuilds the playlist from IPTV-org. A scheduled GitHub Actions workflow refreshes it automatically.
