function InstallService ($serviceName, $displayName, $folder, $executable, $arguments, $accountType, $login, $password, $startUpType, $stateAfterInstallation) {
  Write-Host "Installing service: $serviceName"

  $binaryPath = Join-Path $folder $executable

  if ((Test-Path $binaryPath) -eq $false) {
    throw "BinaryPath to service not found: $binaryPath"
  }

  if (("Automatic", "AutomaticDelayedStart", "Manual", "Disabled") -notcontains $startUpType) {
    throw "Value for startUpType parameter should be (Automatic, AutomaticDelayedStart, Manual or Disabled) and it was $startUpType"
  }

  $binaryPathWithArgs = $binaryPath
  if ($arguments) {
    $binaryPathWithArgs = "`"$binaryPath`" $arguments"
  }

  $existingService = Get-Service $serviceName -ErrorAction SilentlyContinue
  if ($existingService) {
    Write-Host "Service $serviceName already exists - stopping and removing"
    $existingService | Stop-Service -Force
    $existingService | Remove-Service
  }

  if (!$password) {
    $secpasswd = (new-object System.Security.SecureString)
  }
  else {
    $secpasswd = ConvertTo-SecureString $password -AsPlainText -Force
  }

  if ($accountType -eq "LocalSystem") {
    $login = "LocalSystem"
  }
  elseif ($accountType -eq "LocalService") {
    $login = "NT AUTHORITY\\LOCAL SERVICE"
  }
  elseif ($accountType -eq "NetworkService") {
    $login = "NT AUTHORITY\
ETWORK SERVICE"
  }
  $serviceCredential = New-Object System.Management.Automation.PSCredential ($login, $secpasswd)

  if (!$displayName) {
    $displayName = $serviceName
  }
  New-Service -name $serviceName -binaryPathName $binaryPathWithArgs -displayName $displayName -startupType $startUpType -credential $serviceCredential

  Write-Host "Installation completed: $serviceName"

  if ($stateAfterInstallation -eq "Started") {
    Write-Host "Starting service: $serviceName"
    Start-Service -Name $serviceName
    Write-Host "Service started: $serviceName"
  }
}

$serviceName = $Jaws.Parameters["STEP.ServiceInformation.ServiceName"].Value
$serviceDisplayName = $Jaws.Parameters["STEP.ServiceInformation.DisplayName"].Value
$serviceDir = $Jaws.Parameters["STEP.ServiceExecutable.InstallationDirectory"].Value
$binaryName = $Jaws.Parameters["STEP.ServiceExecutable.ExecutablePath"].Value
$arguments = $Jaws.Parameters["STEP.ServiceExecutable.ExecutableArguments"].Value
$accountType = $Jaws.Parameters["STEP.ServiceAccount.AccountType"].Value
$username = $Jaws.Parameters["STEP.ServiceAccount.UserAccountName"].Value
$password = $Jaws.Parameters["STEP.ServiceAccount.UserAccountPassword"].Value
$startMode = $Jaws.Parameters["STEP.ServiceStartup.StartMode"].Value
$stateAfterInstallation = $Jaws.Parameters["STEP.ServiceStartup.StateAfterInstallation"].Value

InstallService $serviceName $serviceDisplayName $serviceDir $binaryName $arguments $accountType $username $password $startMode $stateAfterInstallation