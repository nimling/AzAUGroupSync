function Get-AllAU {
  <#
  .SYNOPSIS
    Returns all AUs from the currently connected tenant
  #>
  $requestSettings = @{
    "Method"  = "Get"
    "Uri"     = "https://graph.microsoft.com/v1.0/directory/administrativeUnits"
  }
  $AUs = Invoke-Graphrequest @requestSettings
  return $AUs.value
}

function Get-AUName 
{
  <#
  .SYNOPSIS
    Retreives name of Administratrive Unit
  #>
  param
  (
    # Azure AD object Id for Administrative Unit
    [Parameter(Mandatory=$true)]
    [string]$AUId
  )
  $requestSettings = @{
    "Method"  = "Get"
    "Uri"     = "https://graph.microsoft.com/v1.0/directory/administrativeUnits/$AUId"
  }
  $AU = Invoke-Graphrequest @requestSettings
  return $AU.displayName
}

function Get-UserName 
{
  <#
  .SYNOPSIS
    Retreives name of AD user
  #>
  param (
    # Azure AD object Id for user
    [Parameter(Mandatory=$true)]
    [string]$UserId
  )
  $requestSettings = @{
    "Method"  = "Get"
    "Uri"     = "https://graph.microsoft.com/v1.0/users/$UserId"
  }
  $User = Invoke-Graphrequest @requestSettings
  return $User.displayName
}

function Get-GroupName 
{
  <#
  .SYNOPSIS
    Retreives name of AD group
  #>
  param
  (
    # Azure AD object Id for Group
    [Parameter(Mandatory=$true)]
    [string]$GroupId
  ) 
  $requestSettings = @{
    "Method"  = "Get"
    "Uri"     = "https://graph.microsoft.com/v1.0/groups/$GroupId"
  }
  $Group = Invoke-Graphrequest @requestSettings
  return $Group.displayName
}

function Add-AUMember 
{
  <#
  .SYNOPSIS
    Adds Azure AD user to Administrative Unit.
  #>
  param
  (  
    # Azure AD object Id for user
    [Parameter(Mandatory=$true)]
    [string]$UserId,
    # Azure AD object Id for Administrative Unit
    [Parameter(Mandatory=$true)]
    [string]$AUId
  )
  $requestSettings = @{
    "Method"  = "Post"
    "Uri"     = "https://graph.microsoft.com/v1.0/directory/administrativeUnits/$AUId/members/`$ref"
    "Body"    = "{`"@odata.id`": `"https://graph.microsoft.com/v1.0/directoryObjects/$UserId`"}"
  }
  
  try {
    Invoke-Graphrequest @requestSettings
  }
  catch {
    Write-Warning "Unable to add user with Id $UserId to AU $(Get-AUName -AUId $AUId) ($AUId)."
    return
  }
  Write-Output "User $(Get-UserName -UserId $UserId) ($UserId) was successfully added to AU $(Get-AUName -AUId $AUId) ($AUId)."
  return
}

function Get-AUIdFromName 
{
  <#
  .SYNOPSIS
    Retrieves Administrative Unit Id from Administrative Unit name.
  #>
  param (
    # Azure AD object name for Administrative Unit
    [Parameter(Mandatory=$true)]
    [string]$AUName
  )
  $requestSettings = @{
    "Method"  = "Get"
    "Uri"     = "https://graph.microsoft.com/v1.0/directory/administrativeUnits"
  }
  $AUs = Invoke-Graphrequest @requestSettings

  $AUId = ($AUs.value | Where-Object {$_.displayName -eq $AUName}).id
  return $AUId
}

function Get-GroupIdFromName 
{
  <#
  .SYNOPSIS
    Retrieves group Id from group name.
  #>
  param (
    # Azure AD object name for group
    [Parameter(Mandatory=$true)]
    [string]$GroupName
  )
  $requestSettings = @{
    "Method"  = "Get"
    "Uri"     = "https://graph.microsoft.com/v1.0/groups"
  }
  $Groups = Invoke-Graphrequest @requestSettings

  $GroupId = ($Groups.value | Where-Object {$_.displayName -eq $GroupName}).id
  return $GroupId
}

function Remove-AUMember 
{
  <#
  .SYNOPSIS
    Removes Azure AD user from Administrative Unit.
  #>
  param
  (
    # Azure AD object Id for user
    [Parameter(Mandatory=$true)]
    [string]$UserId,
    # Azure AD object Id for Administrative Unit
    [Parameter(Mandatory=$true)]
    [string]$AUId
  )
  $requestSettings = @{
    "Method"  = "Delete"
    "Uri"     = "https://graph.microsoft.com/v1.0/directory/administrativeUnits/$AUId/members/$UserId/`$ref"
  }
  
  try {
    Invoke-Graphrequest @requestSettings
  }
  catch {
    Write-Output "User with Id $UserId is not a member of the AU $(Get-AUName -AUId $AUId) ($AUId), does not exist in Azure AD."
    return
  }
  Write-Output "User $(Get-UserName -UserId $UserId) ($UserId) was successfully removed from AU $(Get-AUName -AUId $AUId) ($AUId)."
  return
}

function Get-AUUserMembers 
{
  <#
  .SYNOPSIS
    Retrieves user members of Administrative Unit
  #>
  param
  (
    # Azure AD object Id for Administrative Unit
    [Parameter(Mandatory=$true)]
    [string]$AUId
  )
  $requestSettings = @{
    "Method"  = "Get"
    "Uri"     = "https://graph.microsoft.com/v1.0/directory/administrativeUnits/$AUId/members"
  }
  $AUUserMembers = Invoke-Graphrequest @requestSettings
  return ($AUUserMembers.value | Where-Object {$_."@odata.type" -eq "#microsoft.graph.user"})
}

function Get-AUGroupMembers 
{
  <#
  .SYNOPSIS
    Retrieves group members of Administrative Units
  #>
  param
  (
    # Azure AD object Id for Administrative Unit
    [Parameter(Mandatory=$true)]
    [string]$AUId
  )
  $requestSettings = @{
    "Method"  = "Get"
    "Uri"     = "https://graph.microsoft.com/v1.0/directory/administrativeUnits/$AUId/members"
  }

  $AUGroupMembers = Invoke-Graphrequest @requestSettings
  $AUGroupMembers = $AUGroupMembers.value | Where-Object {$_."@odata.type" -eq "#microsoft.graph.group"}

  if($null -eq $AUGroupMembers)
  {
    Write-Host "AU $(Get-AUName -AUId -$AUId) ($AUId) are not assigned any groups."
    return
  }
  else {
    return $AUGroupMembers
  }
}

function Get-GroupMembers 
{
  <#
  .SYNOPSIS
    Retrieves user members of group
  #>
  param
  (
    # Azure AD object Id for Group
    [Parameter(Mandatory=$true)]
    [string]$GroupId
  ) 
  $requestSettings = @{
    "Method"  = "Get"
    "Uri"     = "https://graph.microsoft.com/v1.0/groups/$GroupId/members"
  }

  return Invoke-Graphrequest @requestSettings
}

function Sync-AUandGroup
{
  <#
  .SYNOPSIS
    Synchronizes user members of Administrative Unit with users in an AD group
  #>
  [CmdletBinding(DefaultParameterSetName = 'Id')]
  param
  (
    # Azure AD object Id for Group
    [Parameter(ParameterSetName = 'Id', Mandatory=$true)]
    [string]$GroupId,
    # Azure AD object Id for Administrative Unit
    [Parameter(ParameterSetName = 'Id', Mandatory=$true)]
    [string]$AUId,
    # Azure AD object name for Group
    [Parameter(ParameterSetName = 'Name', Mandatory=$true)]
    [string]$GroupName,
    # Azure AD object name for Administrative Unit
    [Parameter(ParameterSetName = 'Name', Mandatory=$true)]
    [string]$AUName
  )
  
  if ($PSCmdlet.ParameterSetName -eq 'Name') {
    $AUId = Get-AUIdFromName -AUName $AUName
    if ($AUId.count -gt 1) {
      Write-Warning "There are multiple Administrative Units with the name '$($AUName)'. Please re-run the CMDLET with the object ID of the Administrative Unit(s)."
      return
    }
    $GroupId = Get-GroupIdFromName -GroupName $GroupName
  }

  

  # Retrieves all members of provided group
  $Users = (Get-GroupMembers -GroupId $GroupId).value.id

  # Retrieves all user members of provided Administrative Unit
  $AUMembers = Get-AUUserMembers -AUId $AUId

  # Removes all users from AU if groups don't contain user members or if AU does not contain any groups
  if ($null -eq $Users -and $null -ne $AUMembers) 
  {
    foreach ($user in $AUMembers.id) {
      Remove-AUMember -UserId $user -AUId $AUId
    }
    return
  }

  # Adds all group members to AU if AU does not contain any user members
  elseif ($null -eq $AUMembers -and $null -ne $Users) 
  {
    foreach ($user in $Users) {
      Add-AUMember -UserId $user -AUId $AUId
    }
    return
  }

  elseif ($null -eq $AUMembers -and $null -eq $Users) {
    Write-Output "No users found in both Administrative Unit $(Get-AUName -AUId $AUId) and AU groups. Exiting script."
    return
  }

  else 
  {
    # Makes a comparison between AU user members and aggregated user members
    $Compare = Compare-Object -ReferenceObject ($AUMembers).Id -DifferenceObject ($Users) -IncludeEqual

    # Update AU according to results from comparison
    foreach ($user in $Compare) 
    {
      if($user.SideIndicator -eq "<=")
      {
        Remove-AUMember -UserId $user.InputObject -AUId $AUId
      }
      elseif($user.SideIndicator -eq "=>")
      {
        Add-AUMember -UserId $user.InputObject -AUId $AUId
      }
      elseif($user.SideIndicator -eq "==")
      {
        continue
      }
    }
    return
  }
}

function Sync-AUMembers
{
  <#
  .SYNOPSIS
    Synchronizes user members of Administrative Unit with AD groups which are members of the Administrative Unit.
  #>
  [CmdletBinding(DefaultParameterSetName = 'Id')]
  param
  (
    # Azure AD object Id for Administrative Unit
    [Parameter(ParameterSetName = 'Id', Mandatory=$true)]
    [string]$AUId,
    # Azure AD object name for Administrative Unit
    [Parameter(ParameterSetName = 'Name', Mandatory=$true)]
    [string]$AUName
  )
  
  if ($PSCmdlet.ParameterSetName -eq 'Name') {
    $AUId = Get-AUIdFromName -AUName $AUName
    if ($AUId.count -gt 1) {
      Write-Warning "There are multiple Administrative Units with the name '$($AUName)'. Please re-run the CMDLET with object ID."
      return
    }
  }

  # Retrieves all groups which are members of AU
  $AUGroups = Get-AUGroupMembers -AUId $AUId

  # Creates list of all users who are members of $AUGroups
  $Users = @()
  foreach ($group in $AUGroups) 
  {
    $GroupUsers = Get-GroupMembers -GroupId $group.id
    foreach($GroupUser in $GroupUsers.value.id) 
    {
      $Users += $GroupUser 
    }
  }

  $Users = $Users | Select-Object -Unique

  # Retrieves user members of AU
  $AUMembers = Get-AUUserMembers -AUId $AUId

  # Removes all users from AU if groups don't contain user members or if AU does not contain any groups
  if ($null -eq $Users -and $null -ne $AUMembers) 
  {
    foreach ($user in $AUMembers.id) {
      Remove-AUMember -UserId $user -AUId $AUId
    }
    return
  }

  # Adds all group members to AU if AU does not contain any user members
  elseif ($null -eq $AUMembers -and $null -ne $Users) 
  {
    foreach ($user in $Users) {
      Add-AUMember -UserId $user -AUId $AUId
    }
    return
  }

  elseif ($null -eq $AUMembers -and $null -eq $Users) {
    Write-Output "No users found in both Administrative Unit $(Get-AUName -AUId $AUId) and AU groups. Exiting script."
    return
  }

  else 
  {
    # Makes a comparison between AU user members and aggregated group user members
    $Compare = Compare-Object -ReferenceObject ($AUMembers).Id -DifferenceObject ($Users) -IncludeEqual

    # Update AU according to results from comparison
    foreach ($user in $Compare) 
    {
      if($user.SideIndicator -eq "<=")
      {
        Remove-AUMember -UserId $user.InputObject -AUId $AUId
      }
      elseif($user.SideIndicator -eq "=>")
      {
        Add-AUMember -UserId $user.InputObject -AUId $AUId
      }
      elseif($user.SideIndicator -eq "==")
      {
        continue
      }
    }
    return
  }
}
