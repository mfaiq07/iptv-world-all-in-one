param(
    [string]$OutputPath = (Join-Path $PSScriptRoot 'world-all-in-one.m3u')
)

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

$countryUrl = 'https://iptv-org.github.io/iptv/index.country.m3u'
$categoryUrls = @(
    @{ Name = 'Sports'; Url = 'https://iptv-org.github.io/iptv/categories/sports.m3u' },
    @{ Name = 'Movies'; Url = 'https://iptv-org.github.io/iptv/categories/movies.m3u' },
    @{ Name = 'Series'; Url = 'https://iptv-org.github.io/iptv/categories/series.m3u' }
)

function Set-GroupTitle {
    param([string]$PlaylistBody, [string]$GroupTitle)
    return [regex]::Replace(
        $PlaylistBody,
        '(?m)^(#EXTINF:[^\r\n]*?)group-title="[^"]*"',
        { param($match) $match.Groups[1].Value + 'group-title="' + $GroupTitle + '"' }
    )
}

function Select-ChannelBlocks {
    param([string]$PlaylistBody, [string]$Pattern, [string]$GroupTitle)
    $selected = [System.Collections.Generic.List[string]]::new()
    foreach ($match in [regex]::Matches($PlaylistBody, '(?ms)^#EXTINF:.*?(?=^#EXTINF:|\z)')) {
        $block = $match.Value.Trim("`r", "`n")
        $description = ($block -split '\r?\n', 2)[0]
        if ($description -match $Pattern) {
            $selected.Add((Set-GroupTitle -PlaylistBody $block -GroupTitle $GroupTitle))
        }
    }
    return $selected
}

$utf8 = [System.Text.Encoding]::UTF8
$countryResponse = Invoke-WebRequest -Uri $countryUrl -UseBasicParsing
$countryPlaylist = if ($countryResponse.Content -is [byte[]]) { $utf8.GetString($countryResponse.Content) } else { [string]$countryResponse.Content }

# A merged M3U needs only one header. Keeping category entries as duplicates
# exposes channels under Sports, Movies, or Series as well as their countries.
$parts = [System.Collections.Generic.List[string]]::new()
$parts.Add($countryPlaylist.TrimEnd("`r", "`n"))
foreach ($category in $categoryUrls) {
    $response = Invoke-WebRequest -Uri $category.Url -UseBasicParsing
    $playlist = if ($response.Content -is [byte[]]) { $utf8.GetString($response.Content) } else { [string]$response.Content }
    $body = $playlist -replace '^(?:\uFEFF)?#EXTM3U[^\r\n]*(?:\r?\n)?', ''
    $body = $body.Trim("`r", "`n")
    $parts.Add((Set-GroupTitle -PlaylistBody $body -GroupTitle $category.Name))

    if ($category.Name -eq 'Sports') {
        $cricketPattern = '(?i)cricket|willow|cricbuzz|\bicc\b|indian premier league|\bipl\b|big bash|the ashes'
        $footballPattern = '(?i)football|soccer|futbol|fútbol|calcio|golazo|premier league|laliga|la liga|bundesliga|uefa|fifa|real madrid|barcelona|barça|liverpool|manchester|chelsea|arsenal|juventus|ac milan|inter milan|napoli|bayern|dortmund|ajax|benfica|brøndby|celtic|rangers'
        $cricketBlocks = Select-ChannelBlocks -PlaylistBody $body -Pattern $cricketPattern -GroupTitle 'Cricket'
        $footballBlocks = Select-ChannelBlocks -PlaylistBody $body -Pattern $footballPattern -GroupTitle 'Football'
        if ($cricketBlocks.Count -gt 0) { $parts.Add(($cricketBlocks -join "`r`n")) }
        if ($footballBlocks.Count -gt 0) { $parts.Add(($footballBlocks -join "`r`n")) }
    }
}
$merged = $parts -join "`r`n"

[System.IO.File]::WriteAllText($OutputPath, $merged, [System.Text.UTF8Encoding]::new($false))

$entryCount = ([regex]::Matches($merged, '(?m)^#EXTINF:')).Count
Write-Output "Created $OutputPath with $entryCount playlist entries."
