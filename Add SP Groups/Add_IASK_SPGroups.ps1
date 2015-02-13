if ((Get-PSSnapin "Microsoft.SharePoint.PowerShell" -ErrorAction SilentlyContinue) -eq $null) 
{
    Add-PSSnapin "Microsoft.SharePoint.PowerShell"
}

#Get Site and Web objects
$SireUrl = Read-Host 'Please enter the url for the IASK website'
$site = Get-SPSite $SireUrl
$web = $site.RootWeb

$invocation = (Get-Variable MyInvocation).Value
$directorypath = Split-Path $invocation.MyCommand.Path
$settingspath = $directorypath + '\Groups.xml'

#Get XML file containing groups and associated users
$groupsXML = [xml] (Get-Content ($settingspath))

#Walk through each group node defined in the XML file
$groupsXML.Groups.Group | ForEach-Object {
    #Check to see if SharePoint group already exists in the site collection
    if ($web.SiteGroups[$_.name] -eq $null)
    {
        #If the SharePoint group doesn't exist already - create it from the name and description values at the node
        $newGroup = $web.SiteGroups.Add($_.name, $web.CurrentUser, $null, $_.description)
        Write-Host $_.name " has been created" -foregroundcolor green
    }

    #Get SharePoint group from the site collection
    $group = $web.SiteGroups[$_.name]

    #Add the users defined in the XML to the SharePoint group
    $_.Users.User | ForEach-Object {
        $group.Users.Add($_, "", "", "")
    }
    Write-Host  "Users added to the group" -foregroundcolor green
}


function AddGroupToSite ($web, $groupName, $permLevel)
{
    $account = $web.SiteGroups[$groupName]
    $assignment = New-Object Microsoft.SharePoint.SPRoleAssignment($account)
    $role = $web.RoleDefinitions[$permLevel]
    $assignment.RoleDefinitionBindings.Add($role);
    $web.RoleAssignments.Add($assignment)
    Write-Host  $groupName " added to the web." -foregroundcolor green
}

AddGroupToSite -web $web -groupName "IASK Content Management Team" -permLevel "Approve"
AddGroupToSite -web $web -groupName "IASK Representatives" -permLevel "Approve"
AddGroupToSite -web $web -groupName "IASK Content Review Experts" -permLevel "Approve"
AddGroupToSite -web $web -groupName "IASK Content Review Team" -permLevel "Approve"
AddGroupToSite -web $web -groupName "IASK Compliance team" -permLevel "Approve"
AddGroupToSite -web $web -groupName "IASK Content Rewiew Owners" -permLevel "Approve"
AddGroupToSite -web $web -groupName "IASK Publishers" -permLevel "Approve"


#Dispose of Web and Site objects
$web.Dispose()
$site.Dispose()