# Create Base Machines
These machines will be cloned to create all of the others

## Setup Base Domain Controller

Create Virtual Machine
- 2 Processors
- 3072 MB of memory
- 80 GB of storage
- Network Adapters
	- Bridged Adapter
	- NAT
		
Install Windows Server 2022 Without desktop experience

Set Administrator Password: P@ssw0rd123!

Use SConfig to:
- Change Computer Name: DC

Install VBoxGuestAdditions.exe
```
D:
.\VBoxWindowsAdditions.exe
```

Create Snapshot in VBox

## Setup Base Workstation

Create Virtual Machine
- 2 Processors
- 5020 MB memory
- 50 GB of storage
- Network Adapters
	- Bridged Adapter
	- NAT
		
Install Windows 11 Enterprise Evaluation Edition

Install VBoxGuestAdditions.exe

Create Snapshot in VBox


# Create Initial Working Machines
These will be the first macines to get our domain up and running
- Domain Controller 01
- Work Station 01
- Management Console
## Setup Domain Controller 01
Clone Base Domain Controller

Use SConfig to:
- Change Computer Name: DC01
- Set Static IP
- Change DNS to match IPv4 address

Install AD Domain Services
```
Install-WindowsFeature AD-Domain-Services -IncludeManagementTools
```
	
Setup new domain with new forest:
```
import-module ADDSDeployment
Install-ADDSForest
```
	
DomainName: xyz.local

Safe Mode Administrator Password: P@ssw0rd123

Use SConfig to:
- Change DNS to match IPv4 address

Take Snapshot

## Setup Management Console (PSRemoting)
Clone Base Workstation

Set WinRM to begin Automatically and start service:

- Services >> Windows Remote Management >> Properties
	- Startup Type >> Automatic
	- ServiceStatus >> Start

Add Domain Controller to trusted hosts:
```
set-item wsman:\\localhost\Client\TrustedHosts -value [DC local IP]
```

Test PSRemoting:
```
New-PSSession [DC IP] -Credential (Get-Credential)
Enter-PSSession [DC Session #]
```

Install Chocolatey:
```
Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
```

Install VSCode:
```
choco install vscode
```

Take Snapshot

## Setup Work Station 01
Clone Base Workstation

set DNS to Domain IP
```
Get-NetIPAddress
```

Get [InterfaceIndex] of the BridgedAdapter

```
Set-DnsClientServerAddress -InterfaceIndex [InterfaceIndex] -ServerAddress 192.168.0.13
```

Join the Domain
- Settings >> Account >> Access work or school
- Add a work or school account >> Connect
	- Join this device to a local Active Directory Domain
		- Domain name: xyz.local

Do not create a Domain User at this time, press Skip.

