<#
	.DESCRIPTION
		Downloads package from specified address to the temp storage. Skips download if file already exists.
#>
function Download-File([string]$url, [string]$destination)
{
	if (Test-Path $destination)
	{
		Write-Output "The file has been already downloaded. Skipping."
		return
	}

	Write-Output "Downloading file from $url to $destination"
	
	$client = new-object System.Net.WebClient
	$client.DownloadFile($url, $destination)
	
	Write-Output "Download complete!"		
}

<#
	.DESCRIPTION
		Extract package to the webroot
#>
function Extract-Package([string]$downloadLocation, [string]$webroot, [string]$extractedFolder, [string]$overwrite)
{
    if (($overwrite -eq "1") -and (Test-Path $webroot))
    {
        Write-Output "Webroot already exists. Removing...."
   		Remove-Item $webroot -Recurse -Force
        Start-sleep -milliseconds 2000
    }

    if(Test-Path $webroot)
	{
		Write-Output "Web root already exists. Skipping."
		return
	}

	# Create a web root directory and unzip archive
	New-Item $webroot -type directory -Force -Verbose
    Unzip-Archive $downloadLocation $webroot

    if (Test-Path "$webroot\$extractedFolder") {
    	move "$webroot\$extractedFolder\*" "$webroot" -Verbose
    	rm "$webroot\$extractedFolder" -Verbose
    }
}

<#
	.DESCRIPTION
		Copy license file to data folder
#>
function Copy-License([string]$wwwroot, [string]$webroot)
{
	copy "$wwwroot\Setup\License\license.xml" "$webroot\data" -Verbose
}

<#
	.DESCRIPTION
		Set file system Permissions by running setSecurity.bat
#>
function Set-Permissions([string]$wwwroot, [string]$webroot)
{
	Write-Output "Setting folder permissions ..."
	
	copy "$wwwroot\Setup\setSecurity.bat" "$webroot" -Verbose
	cd $webroot
	cmd /c "$webroot\setSecurity.bat" `>setsecurity.log 2`>`&1	
	
	Write-Output "Setting folder permissions Done."
}

<#
	.DESCRIPTION
		Remove development folders 
#>
function Cleanup-Folder([string]$folder)
{
	if (Test-Path $folder)
	{
        try
        {
		  Remove-Item $folder -Recurse -Force
		  Write-Output "Remove folder $folder. Done."
        }
        catch 
        {
            Write-Output "Remove-Item could not remove $folder"
        }
	}
}

<#
	.DESCRIPTION
		Package resources, like dictionary and indexes
#>
function Package-Resources([string]$webroot, [string]$tempFolder)
{	
    Write-Output "Packaging resources from $webroot to $tempFolder"
    
    $resourcesFolder = $tempFolder + "Resources\"
    $dataFolder = $tempFolder + "Resources\data"
    $websiteFolder = $tempFolder + "Resources\website"
    $indexesFolder = $tempFolder + "Resources\data\indexes"
    $websiteTempFolder = $tempFolder + "Resources\website\temp"
    $resourcesArchive = $tempFolder + "resources.zip"

    # Existing website
    $dictionaryPath = $webroot + "\website\temp\dictionary.dat"
    $indexesPath = $webroot + "\data\indexes"

    if(Test-Path $resourcesFolder)
	{
		Write-Output "Resources folder already exists. Let's drop it."
        rm $resourcesFolder -Force -Recurse
	}

	Write-Output "Creating new resources directory ..."
	New-Item $resourcesFolder -type directory -force
	New-Item $dataFolder -type directory -force
    New-Item $websiteFolder -type directory -force   
    New-Item $indexesFolder -type directory -force
    New-Item $websiteTempFolder -type directory -force   
    
    Write-Output "Dictionary path: $dictionaryPath"
    if(Test-Path $dictionaryPath)
	{        
        copy $dictionaryPath "$websiteTempFolder" -Verbose
	}
    
    Write-Output "Indexes path: $indexesPath"
    if(Test-Path $indexesPath)
	{
        copy "$indexesPath\*" "$indexesFolder" -Recurse -Verbose
	}
    
	Set-Content $resourcesArchive ("PK" + [char]5 + [char]6 + ("$([char]0)" * 18))
	(dir $resourcesArchive).IsReadOnly = $false

    $shellApplication = new-object -com shell.application
	$zipPackage = $shellApplication.NameSpace($resourcesArchive)
	 
    $zipPackage.CopyHere($dataFolder)
    Start-sleep -milliseconds 10000
    $zipPackage.CopyHere($websiteFolder)
    Start-sleep -milliseconds 5000
    rm $resourcesFolder -force -recurse
}

<#
	.DESCRIPTION
		Extract archive
#>
function Unzip-Archive ([string]$file, [string]$targetFolder)
{
    if (Test-Path $file)
	{
        Write-Output "Unzipping package - $file"
		
    	$shell_app = new-object -com shell.application 
    	$zip_file = $shell_app.namespace($file) 
    	$destination = $shell_app.namespace($targetFolder)
    	$destination.CopyHere($zip_file.items(), 0x14)
		
    	Write-Output "Unzipping done!"	
	}
    else 
    {
        Write-Output "Package $file not found!"	
    }	
}

function Add-HostFileContent ([string]$IPAddress, [string]$computer)          
{                              
	$file = Join-Path -Path $($env:windir) -ChildPath "system32\drivers\etc\hosts"            
	if (-not (Test-Path -Path $file)){            
		Throw "Hosts file not found"            
	}            
	$data = Get-Content -Path $file             
	$data += "$IPAddress  $computer"            
	Set-Content -Value $data -Path $file -Force -Encoding ASCII     
	
	Write-Output "Hosts file updated"
}
 
Export-ModuleMember -function Download-File
Export-ModuleMember -function Extract-Package
Export-ModuleMember -function Copy-License
Export-ModuleMember -function Set-Permissions
Export-ModuleMember -function Cleanup-Folder
Export-ModuleMember -function Package-Resources
Export-ModuleMember -function Unzip-Archive
Export-ModuleMember -function Add-HostFileContent