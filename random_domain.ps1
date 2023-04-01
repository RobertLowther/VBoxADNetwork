param([Parameter(Mandatory=$True)] $OutputJSONFile)

$group_names = [System.Collections.ArrayList](Get-Content "data\group_names.txt")
$first_names = [System.Collections.ArrayList](Get-Content "data\first_names.txt")
$last_names = [System.Collections.ArrayList](Get-Content "data\last_names.txt")
$passwords = [System.Collections.ArrayList](Get-Content "data\passwords.txt")

$groups = @()
$num_groups = 10
for ($i = 0; $i -lt $num_groups; $i++)
{
    $group_name = (Get-Random -InputObject $group_names)
    $groups += @{ "name" = "$group_name" }
    $group_names.Remove($group_name)
}

$users = @()
$num_users = 100
for ($i = 0; $i -lt $num_users; $i++)
{
    $first_name = (Get-Random -InputObject $first_names)
    $last_name = (Get-Random -InputObject $last_names)
    $password = (Get-Random -InputObject $passwords)
    $new_user = @{
        "name" = "$first_name $last_name"
        "password" = "$password"
        "groups" = @( (Get-Random -InputObject $groups.name) )
    }

    $first_names.Remove($first_name)
    $last_names.Remove($last_name)
    $passwords.Remove($password)

    $users += $new_user
}

Write-Output @{
    "domain" = "xyz.local"
    "groups" = $groups
    "users" = $users
} | ConvertTo-Json | Out-File $OutputJSONFile