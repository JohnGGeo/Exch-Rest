function  Get-EXREmailActivityUserDetail{
    [CmdletBinding()]
    param(
        [Parameter(Position=0, Mandatory=$false)] [string]$MailboxName,
        [Parameter(Position=1, Mandatory=$false)] [psobject]$AccessToken,
        [Parameter(Position=3, Mandatory=$false)] [String]$PeriodType = "D7",
        [Parameter(Position=3, Mandatory=$false)] [String]$date   
    )
    Begin{
        
		if($AccessToken -eq $null)
		{
			$AccessToken = Get-ProfiledToken -MailboxName $MailboxName  
			if($AccessToken -eq $null){
				$AccessToken = Get-EXRAccessToken -MailboxName $MailboxName       
			}                 
		}
		if([String]::IsNullOrEmpty($MailboxName)){
			$MailboxName = $AccessToken.mailbox
        }else{
            $Filter = $MailboxName
        }   
        $HttpClient =  Get-HTTPClient -MailboxName $MailboxName
        $EndPoint =  Get-EndPoint -AccessToken $AccessToken -Segment "reports"
        if(![String]::IsNullOrEmpty($date)){
            $RequestURL =  $EndPoint + "/getEmailActivityUserDetail(date=$date)`?`$format=text/csv"
        }else{
            $RequestURL =  $EndPoint + "/getEmailActivityUserDetail(period='$PeriodType')`?`$format=text/csv"
        }        
        Write-Host $RequestURL
        $Output = Invoke-RestGet -RequestURL $RequestURL -HttpClient $HttpClient -AccessToken $AccessToken -MailboxName $MailboxName -NoJSON
        $OutPutStream = $Output.ReadAsStreamAsync().Result
        if([String]::IsNullOrEmpty($Filter)){
            return ConvertFrom-Csv ([System.Text.Encoding]::UTF8.GetString($OutPutStream.ToArray()))
        }else{
            return ConvertFrom-Csv ([System.Text.Encoding]::UTF8.GetString($OutPutStream.ToArray())) | Where-Object {$_.'User Principal Name' -eq $MailboxName}
        }    
    }
}
