function Get-OutdatedPackages {
    $solution = Get-ChildItem -Filter *.sln | Select-Object -First 1

    if (-not $solution) {
        Write-Host "No solution file found in the current directory." -ForegroundColor Red
        return
    }

    dotnet list $solution.FullName package --outdated |
        Select-String '>' | ForEach-Object {
            $parts = ($_ -split '\s+') -ne ''
            [PSCustomObject]@{
                Package        = $parts[1]  # Package name
                CurrentVersion = $parts[3]  # Resolved version
                LatestVersion  = $parts[4]  # Latest version
            }
        } | Where-Object { $_.CurrentVersion -ne $_.LatestVersion -and $_.LatestVersion -ne 'Not' } |
        Sort-Object Package -Unique |
        Format-Table -AutoSize
}
