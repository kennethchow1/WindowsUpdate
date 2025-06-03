$version = "2.8.5.208"

Write-Verbose "Verifying NuGet $version or later is installed"

$nuget = Get-PackageProvider -Name NuGet -ListAvailable -ErrorAction SilentlyContinue |
                Sort-Object -Property {[version]$_.version} | Select-Object -Last 1

if(-not $nuget -or [version]$nuget.version -lt [version]$version){
    Write-Verbose "Installing NuGet $($nuget.Version)"
    $null = Install-PackageProvider -Name NuGet -MinimumVersion $nuget.version -Force
}
Set-PSRepository -Name 'PSGallery' -InstallationPolicy Trusted
Install-Module -Name PSWindowsUpdate
Reset-WUComponents
