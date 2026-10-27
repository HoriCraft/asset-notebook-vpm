param(
    [Parameter(Mandatory)][string]$PackageZip,
    [Parameter(Mandatory)][string]$BuildReport,
    [Parameter(Mandatory)][string]$OutputDirectory,
    [ValidateSet('LocalTest', 'Publish')][string]$Mode = 'LocalTest',
    [string]$BaseUrl = 'http://127.0.0.1:18746/'
)

$ErrorActionPreference = 'Stop'
$packageId = 'com.horicraft.booth-library-unity'
$zipFull = (Resolve-Path -LiteralPath $PackageZip).Path
$report = Get-Content -LiteralPath $BuildReport -Raw -Encoding UTF8 | ConvertFrom-Json
$digest = (Get-FileHash -LiteralPath $zipFull -Algorithm SHA256).Hash.ToLowerInvariant()
$reportDigest = if ($report.sha256) { $report.sha256 } else { $report.zipSha256 }
if ($reportDigest -ne $digest) { throw 'Build report and package SHA-256 do not match.' }
if ($report.sha256 -and $report.zipSha256 -and $report.sha256 -ne $report.zipSha256) { throw 'Build report has inconsistent checksums.' }
$baseUri = [Uri]$BaseUrl
if ($Mode -eq 'LocalTest') {
    if (-not $baseUri.IsLoopback -or $baseUri.Scheme -ne 'http') { throw 'LocalTest requires a loopback HTTP URL.' }
} else {
    if ($BaseUrl -ne 'https://horicraft.github.io/asset-catalog-vpm/') { throw 'Unexpected publication destination.' }
    if ($report.releaseEligible -ne $true) { throw 'Publication requires a build that passed the release gate.' }
}
if (-not $BaseUrl.EndsWith('/')) { throw 'BaseUrl must end with a slash.' }
if (Test-Path -LiteralPath $OutputDirectory) { throw 'OutputDirectory must be new; existing listings are never overwritten.' }

Add-Type -AssemblyName System.IO.Compression.FileSystem
$archive = [IO.Compression.ZipFile]::OpenRead($zipFull)
try {
    $entries = @($archive.Entries | Where-Object { $_.Name })
    $names = @($entries | ForEach-Object FullName)
    if (@($names | Select-Object -Unique).Count -ne $names.Count) { throw 'Duplicate ZIP entries.' }
    $allowed = '^(package\.json(\.meta)?|README\.md(\.meta)?|CHANGELOG\.md(\.meta)?|LICENSE\.md(\.meta)?|Editor\.meta|Editor/[A-Za-z0-9_.-]+\.dll(\.meta)?)$'
    foreach ($name in $names) {
        if ($name -notmatch $allowed -or $name -match '(?i)(validation|test|fixture|\.\.)') { throw "Unexpected package entry: $name" }
    }
    $dlls = @($names | Where-Object { $_ -match '^Editor/.+\.dll$' })
    if ($dlls.Count -eq 0) { throw 'No Editor DLL in package.' }
    foreach ($dll in $dlls) {
        if ($names -notcontains "$dll.meta") { throw "DLL meta is missing: $dll" }
    }
    if ($names -notcontains 'LICENSE.md') { throw 'Package license is missing.' }
    $manifestEntry = $archive.GetEntry('package.json')
    if (-not $manifestEntry) { throw 'Root package.json is missing.' }
    $reader = [IO.StreamReader]::new($manifestEntry.Open())
    try { $manifest = $reader.ReadToEnd() | ConvertFrom-Json -AsHashtable } finally { $reader.Dispose() }
    if ($manifest.name -ne $packageId) { throw 'Package ID changed.' }
    if ($manifest.version -notmatch '^\d+\.\d+\.\d+(-[0-9A-Za-z.-]+)?$') { throw 'Invalid package version.' }
    if ($manifest.version -ne $report.version) { throw 'Package and build report versions differ.' }
    if ($manifest.license -ne 'SEE LICENSE.md') { throw 'Paid license marker is missing.' }
    if ($manifest.ContainsKey('zipSHA256')) { throw 'zipSHA256 belongs only in the listing manifest.' }
} finally { $archive.Dispose() }

$fileName = "$packageId-$($manifest.version).zip"
$manifest.url = $BaseUrl + 'packages/' + $fileName
$manifest.zipSHA256 = $digest
$listing = [ordered]@{
    name = $(if ($Mode -eq 'LocalTest') { 'Asset Notebook PC内テスト' } else { 'Asset Notebook' })
    id = $(if ($Mode -eq 'LocalTest') { 'com.horicraft.asset-catalog.local-test' } else { 'com.horicraft.asset-catalog.vpm' })
    author = 'HoriCraft'
    url = $BaseUrl + 'index.json'
    packages = @{ $packageId = @{ versions = @{ $manifest.version = $manifest } } }
}
$outputFull = [IO.Path]::GetFullPath($OutputDirectory)
$packagesDir = Join-Path $outputFull 'packages'
New-Item -ItemType Directory -Path $packagesDir -Force | Out-Null
Copy-Item -LiteralPath $zipFull -Destination (Join-Path $packagesDir $fileName)
[IO.File]::WriteAllText((Join-Path $outputFull 'index.json'), ($listing | ConvertTo-Json -Depth 20), [Text.UTF8Encoding]::new($false))
$state = if ($report.releaseEligible -eq $true) { '機能の利用には解除キーによる有効化が必要です。' } else { '配布前の確認が残る候補です。動作確認の範囲は担当の案内に従ってください。' }
$label = if ($Mode -eq 'LocalTest') { 'PC内の導入確認用VPM' } else { 'Asset Notebook VPM' }
$localNote = if ($Mode -eq 'LocalTest') { '<p>このURLは、このPCでサーバーが動作している間だけ使えます。</p>' } else { '' }
$safeVersion = [Net.WebUtility]::HtmlEncode($manifest.version)
$safeUrl = [Net.WebUtility]::HtmlEncode($listing.url)
$addUrl = 'vcc://vpm/addRepo?url=' + [Uri]::EscapeDataString($listing.url)
$html = @"
<!doctype html><html lang="ja"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>$label</title><style>body{font-family:system-ui,sans-serif;max-width:48rem;margin:8vh auto;padding:24px;line-height:1.8;color:#18382d;background:#f5f7f5}a{color:#075c43}code{overflow-wrap:anywhere}aside{padding:16px;background:#fff4cc;border-radius:8px}</style><main><h1>$label</h1><p>Asset Notebook $safeVersion</p><aside>動作確認用です。販売開始を示すものではありません。<br>$state</aside><p><a href="$addUrl">VCC / ALCOM にリポジトリを追加</a></p><p>手動追加用URL<br><code>$safeUrl</code></p><ol><li>VCC / ALCOM でプレリリース版を表示してください。</li><li>確認用プロジェクトに候補版を導入してください。</li><li>UnityのHoriCraftメニューから本ツールを開いてください。</li></ol>$localNote</main></html>
"@
[IO.File]::WriteAllText((Join-Path $outputFull 'index.html'), $html, [Text.UTF8Encoding]::new($false))
[ordered]@{mode=$Mode; version=$manifest.version; sha256=$digest; packageFiles=$names.Count; releaseEligible=$report.releaseEligible; listing=$listing.url; output=$outputFull} | ConvertTo-Json
