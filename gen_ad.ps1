param(
    [Parameter(Mandatory=$True)] $JSONFile,
    [switch] $Revert
)

function CreateADGroup(){
    param([Parameter(Mandatory=$True)] $groupObject)

    $name = $groupObject.name
    New-ADGroup -name $name -GroupScope Global
}

function RemoveADGroup(){
    param([Parameter(Mandatory=$True)] $groupObject)

    $name = $groupObject.name
    Remove-ADGroup -Identity $name -Confirm:$false
}

function CreateADUser()
{
    param([Parameter(Mandatory=$True)] $userObject)

    # Extract name from Json object
    $name = $userObject.name
    $password = $userObject.password
    
    # Generate a "first initial, last name" structure for username
    $firstname, $lastname = $name.Split(" ")
    $username = ($firstname[0] + $lastname).ToLower()
    $samAccountName = $username
    $principalname = $username

    # Create the AD user object
    New-ADUser -Name "$firstname $lastname" -GivenName $firstname -Surname $lastname -SamAccountName $SamAccountName -UserPrincipalName $principalname@$Global:Domain -AccountPassword (ConvertTo-SecureString $password -AsPlainText -Force) -PassThru | Enable-ADAccount

    # Add the user to it's groups
    foreach($group_name in $userObject.groups) {
        try {
            Get-ADGroup -Identity $group_name
            Add-ADGroupMember -Identity $group_name -Members $username
        }
        catch [Microsoft.ActiveDirectory.Management.ADIdentityNotFoundException]
        {
            Write-Warning "User not added to group '" + $group_name + "'. AD group '" + $group_name + "' not found."
        }
    }
}

function RemoveADUser(){
    param([Parameter(Mandatory=$True)] $userObject)

    $name = $userObject.name
    $firstname, $lastname = $name.Split(" ")
    $username = ($firstname[0] + $lastname).ToLower()
    $samAccountName = $username

    Remove-ADUser -Identity $samAccountName -Confirm:$false
}

function WeakenSecurityPolicy(){
    secedit /export /cfg C:\Windows\Tasks\secpol.cfg
    (Get-Content C:\Windows\Tasks\secpol.cfg).replace("PasswordComplexity = 1", "PasswordComplexity = 0").replace("MinimumPasswordLength = 7", "MinimumPasswordLength = 1") | Out-File C:\Windows\Tasks\secpol.cfg
    secedit /configure /db C:\windows\security\local.sdb /cfg C:\Windows\Tasks\secpol.cfg /areas SECURITYPOLICY
    Remove-Item -force C:\Windows\Tasks\secpol.cfg -Confirm:$false
}

function HardenSecurityPolicy(){
    secedit /export /cfg C:\Windows\Tasks\secpol.cfg
    (Get-Content C:\Windows\Tasks\secpol.cfg).replace("PasswordComplexity = 0", "PasswordComplexity = 1").replace("MinimumPasswordLength = 1", "MinimumPasswordLength = 7") | Out-File C:\Windows\Tasks\secpol.cfg
    secedit /configure /db C:\windows\security\local.sdb /cfg C:\Windows\Tasks\secpol.cfg /areas SECURITYPOLICY
    Remove-Item -force C:\Windows\Tasks\secpol.cfg -Confirm:$false
}

$json = (Get-Content $JSONFile | ConvertFrom-JSON)
$Global:Domain = $json.domain

if (-Not $Revert)
{
    WeakenSecurityPolicy

    # Create all Groups
    foreach ( $group in $json.groups ) {
        CreateADGroup $group
    }

    # Create all Users
    foreach ( $user in $json.users ) {
        CreateADUser $user
    }
}
else
{
    HardenSecurityPolicy

    # Create all Users
    foreach ( $user in $json.users ) {
        RemoveADUser $user
    }

    # Create all Groups
    foreach ( $group in $json.groups ) {
        RemoveADGroup $group
    }
}