$ErrorActionPreference = "Stop"

$supabaseUrl = "https://augjybpfsmckgsyygkuv.supabase.co"
$supabaseKey = "sb_publishable_ni4WJmJeQAOlE_KtBcyzcw_As_rpiE5"

$headers = @{
    "apikey" = $supabaseKey
    "Authorization" = "Bearer $supabaseKey"
    "Content-Type" = "application/json"
    "Prefer" = "resolution=merge-duplicates"
}

$tables = @(
    @{ name = "categories"; file = "db/categories.json" }
    @{ name = "users"; file = "db/users.json" }
    @{ name = "posts"; file = "db/posts.json" }
    @{ name = "news"; file = "db/news.json" }
    @{ name = "cards"; file = "db/cards.json" }
    @{ name = "settings"; file = "db/settings.json" }
    @{ name = "subscribers"; file = "db/subscribers.json" }
)

Write-Output "=================================================="
Write-Output "SEEDING SUPABASE TABLES FROM LOCAL JSON FILES"
Write-Output "=================================================="

foreach ($t in $tables) {
    $path = $t.file
    $tableName = $t.name
    
    if (-not (Test-Path $path)) {
        Write-Warning "File '$path' not found. Skipping table '$tableName'."
        continue
    }
    
    Write-Output "Reading seed data for '$tableName' from $path..."
    $content = Get-Content -Raw -Path $path
    
    if ([string]::IsNullOrWhiteSpace($content) -or $content -eq "[]" -or $content -eq "{}") {
        Write-Output "Table '$tableName' seed data is empty. Skipping."
        continue
    }
    
    # In settings.json, it might be a single object or an array. PostgREST inserts prefer an array of objects.
    # Let's parse it first to verify it's formatted as an array.
    $parsed = ConvertFrom-Json $content
    $array = @()
    if ($parsed -is [Array]) {
        $array = $parsed
    } else {
        $array = @($parsed)
    }
    
    $jsonToSend = ConvertTo-Json $array -Depth 10 -Compress
    
    try {
        $uri = "$supabaseUrl/rest/v1/$tableName"
        Write-Output "Sending POST request to $uri..."
        $response = Invoke-WebRequest -Uri $uri -Headers $headers -Method Post -Body $jsonToSend -UseBasicParsing
        Write-Output "[SUCCESS] Seeded '$tableName'. Status code: $($response.StatusCode)"
    } catch {
        Write-Error "Failed to seed table '$tableName'. Error: $_"
        if ($_.Exception.Response) {
            $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
            $body = $reader.ReadToEnd()
            $reader.Close()
            Write-Output "Response body: $body"
        }
    }
}
Write-Output "=================================================="
Write-Output "Seeding completed."
Write-Output "=================================================="
