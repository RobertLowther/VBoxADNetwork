param([Parameter(Mandatory=$True)] $JSONFile)

function CreateADGroup(){
    param([Parameter(Mandatory=$True)] $groupObject)

    $name = $groupObject.name
    New-ADGroup -name $name -GroupScope Global
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

$json = (Get-Content $JSONFile | ConvertFrom-JSON)
$Global:Domain = $json.domain

# Create all Groups
foreach ( $group in $json.groups ) {
    CreateADGroup $group
}

# Create all Users
foreach ( $user in $json.users ) {
    CreateADUser $user
}