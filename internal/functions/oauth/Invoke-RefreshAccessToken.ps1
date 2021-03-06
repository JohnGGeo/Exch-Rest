function Invoke-RefreshAccessToken
{
	[CmdletBinding()]
	param (
		[Parameter(Position = 0, Mandatory = $true)]
		[string]
		$MailboxName,
		
		[Parameter(Position = 1, Mandatory = $true)]
		[psobject]
		$AccessToken
	)
	process
	{
		Add-Type -AssemblyName System.Web
		$HttpClient = Get-HTTPClient -MailboxName $MailboxName
		$ClientId = $AccessToken.clientid
		# $redirectUrl = [System.Web.HttpUtility]::UrlEncode($AccessToken.redirectUrl)
		$redirectUrl = $AccessToken.redirectUrl
		$Cached = $AccessToken.Cached
		$RefreshToken = (ConvertFrom-SecureStringCustom -SecureToken $AccessToken.refresh_token)
		$AuthorizationPostRequest = "client_id=$ClientId&refresh_token=$RefreshToken&grant_type=refresh_token&redirect_uri=$redirectUrl"
		$content = New-Object System.Net.Http.StringContent($AuthorizationPostRequest, [System.Text.Encoding]::UTF8, "application/x-www-form-urlencoded")
		$ClientResult = $HttpClient.PostAsync([Uri]("https://login.windows.net/common/oauth2/token"), $content)
		if (!$ClientResult.Result.IsSuccessStatusCode)
		{
			Write-Output ("Error making REST POST " + $ClientResult.Result.StatusCode + " : " + $ClientResult.Result.ReasonPhrase)
			Write-Output $ClientResult.Result
			if ($ClientResult.Content -ne $null)
			{
				Write-Output ($ClientResult.Content.ReadAsStringAsync().Result);
			}
		}
		else
		{
			$JsonObject = ConvertFrom-Json -InputObject $ClientResult.Result.Content.ReadAsStringAsync().Result
			if ([bool]($JsonObject.PSobject.Properties.name -match "refresh_token"))
			{
				$JsonObject.refresh_token = (Get-ProtectedToken -PlainToken $JsonObject.refresh_token)
			}
			if ([bool]($JsonObject.PSobject.Properties.name -match "access_token"))
			{
				$JsonObject.access_token = (Get-ProtectedToken -PlainToken $JsonObject.access_token)
			}
			if ([bool]($JsonObject.PSobject.Properties.name -match "id_token"))
			{
				$JsonObject.id_token = (Get-ProtectedToken -PlainToken $JsonObject.id_token)
			}
			Add-Member -InputObject $JsonObject -NotePropertyName clientid -NotePropertyValue $ClientId
			Add-Member -InputObject $JsonObject -NotePropertyName redirectUrl -NotePropertyValue $redirectUrl
			Add-Member -InputObject $JsonObject -NotePropertyName mailbox -NotePropertyValue $MailboxName
			if ($AccessToken.Beta)
			{
				Add-Member -InputObject $JsonObject -NotePropertyName Beta -NotePropertyValue True
			}
			if($Cached){
				Add-Member -InputObject $JsonObject -NotePropertyName Cached -NotePropertyValue $true
				$HostDomain = (New-Object system.net.Mail.MailAddress($MailboxName)).Host.ToLower()
				$resourceURI = [URI]$JsonObject.resource
				$resource = $resourceURI.Host
				if(!$Script:TokenCache[$resource].ContainsKey($HostDomain)){			
					$Script:TokenCache[$resource].Add($HostDomain,$JsonObject)
				}
				else{
					$Script:TokenCache[$resource][$HostDomain] = $JsonObject
				}
				write-host ("Cached Token for " + $HostDomain)
			}

		}
		return $JsonObject		
	}
}
