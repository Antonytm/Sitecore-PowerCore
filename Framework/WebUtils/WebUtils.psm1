function Get-WebPage {
	param($url)
	
	if (!$url.StartsWith("http://"))
	{
		$url = "http://" + $url
	}
	
	Write-Output "Creating request to $url"
	
	Try
	{
		$request = [system.net.WebRequest]::Create($url)
		$request.Timeout = 2400000
		return $request.GetResponse()		
	}
	Catch [System.Net.WebException]
	{
		#On web exception write response string and throw exception
		$stream = $_.Exception.Response.GetResponseStream()
		$reader = new-object -typename System.IO.StreamReader -argumentlist $stream
		Write-Host $reader.ReadToEnd()
		Throw $_.Exception
	}
	Catch
	{
		Throw $_.Exception
	}
}

Export-ModuleMember -function Get-WebPage