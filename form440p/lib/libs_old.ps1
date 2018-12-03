function Verba_script_old{
	Param( 
		[String]$scrpt_name,
		[String]$mask = "*.*")
	
	[string]$tmp = "$dir1\tmp"
    [int]$amount =3
	
	do{
		$ht = @()
		Get-ChildItem "$work\$mask" | %{ $ht += ,($_.Name, $_.Length)}
		
		Write-Log -EntryType Information -Message "�������� ��������������..."
		Start-Process "$verba" "/@$scrpt_name" -NoNewWindow -Wait
		Start-Sleep -Seconds 3
		
		#��������� ������������� ��� ��� ����� ���������\������������. ����� ������ �������� � �������.
		$ff = Get-ChildItem "$work\$mask"
		Write-Log -EntryType Information -Message "���������� �� � ����� ��������������..."
		foreach ($f1 in $ff){	
			$ht |  % {$i = 0} { if ($_ -eq $f1.Name) {$ht[$i] += $f1.Length}; $i++} {}	
		}
		$not_diff = @()
		foreach ($h1 in $ht){
			if ($h1[1] -eq $h1[2]){
				$not_diff += [string]$h1[0]		
			}
		}
		#���� �� ��� �������������, ��������� �������
		$count = ($not_diff | Measure-Object).count
		if ($count -ne 0){
			
			Write-Log -EntryType Error -Message "����� ������ �� ���� �������������!"
						
			if (!(Test-Path $tmp)){
				New-Item -ItemType directory -Path $tmp | out-Null
			}
			$files1 = Get-ChildItem "$work\$mask" |  Select-Object Name | ? {$not_diff -notcontains $_.Name} | % {$_.Name}
			foreach ($ff2 in $files1){
				Move-Item -Path "$work\$ff2" -Destination $tmp
			}
			
		}
        $amount--
	} until ($count -eq 0 -or $amount -eq 0)
    	
	if (Test-Path $tmp){
		Move-Item -Path "$tmp\*.*" -Destination $work
		Remove-Item -Recurse $tmp
	}
    
    if ($amount -eq 0){
        Write-Log -EntryType Error -Message "������ ��� ������ � Verba"
        exit
    }
	Start-Sleep -Seconds 5
}

Function Validate-Xml{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$True)]
        [string]$xmlFileName,
        
        [Parameter(Mandatory=$True)]
        [string]$xsdFileName
    )

    # Check if the provided file exists
    if(!(Test-Path -Path $xmlFileName))
    {
        Write-Log -EntryType Error -Message "�������� XML ����������, ��������� �� ������ XML-���� � '$xmlFileName'"
        exit 2
    }

    # Check if the provided file exists
    if(!(Test-Path -Path $xsdFileName))
    {
        Write-Log -EntryType Error -Message "�������� XML ����������, ��������� XSD-���� �� ������ '$xsdFileName'"
        exit 3
    }

    #making the schemaset
    $schemaSet = New-Object -TypeName System.Xml.Schema.XmlSchemaSet
    [void]$schemaSet.Add("", $xsdFileName)
    $compiledSchema = $null
    Foreach($schema in $schemaSet)
    {
	    $compiledSchema = $schema
    }

    # Get the file
    $XmlFile = Get-Item($xmlFileName)

    # Keep count of how many errors there are in the XML file
    $script:errorCount = 0

    # Perform the XSD Validation
    $readerSettings = New-Object -TypeName System.Xml.XmlReaderSettings
    $readerSettings.Schemas.Add($compiledSchema)
    $readerSettings.ValidationType = [System.Xml.ValidationType]::Schema
    $readerSettings.ValidationFlags = [System.Xml.Schema.XmlSchemaValidationFlags]::ProcessInlineSchema -bor [System.Xml.Schema.XmlSchemaValidationFlags]::ProcessSchemaLocation
    $readerSettings.add_ValidationEventHandler(
    {
        # Triggered each time an error is found in the XML file
        Write-Log -EntryType Error -Message $("������ � XML: " + $_.Message)
        $script:errorCount++
    });
    $reader = [System.Xml.XmlReader]::Create($XmlFile.FullName, $readerSettings)
    while ($reader.Read()) { }
    $reader.Close()

    # Verify the results of the XSD validation
    if($script:errorCount -gt 0)
    {
        # XML is NOT valid
        return 1
    }
    else
    {
        # XML is valid
        return 0
    }
}

Function Validate-Catalog{
    $m = Get-ChildItem "$work\*.xml" | measure    
    if ($m.count -eq 0){
        Write-Log -EntryType Error -Message "XML-����� �� ��������"
        exit        
    }
    
    $xmlFiles = Get-ChildItem "$work\*.xml"
    [bool]$flag_err = $false
    
    foreach ($xmlFile in $xmlFiles){
        $name3Char = $xmlFile.BaseName.Substring(0, 3)
        $name2Char = $xmlFile.BaseName.Substring(0, 2)
        
        if ($name2Char -eq "PB"){
            $name3Char = "PBQ"
        }
        $xsdName = $name3Char + "_300.xsd"
        $xsdFile = $schemaCatalog + "\" + $xsdName        
        
        if(!(Test-Path -Path $xsdFile)){
            Write-Log -EntryType Error -Message "���� XSD-����� �� ������ $xsdName"
        } else {
            $valid = Validate-Xml -xmlFileName $xmlFile -xsdFileName $xsdFile
            if ($valid -eq 0){
                Write-Log -EntryType Information -Message "��������� ����� ������ ������� $xmlFile"
            } else {
                Write-Log -EntryType Error -Message "������ ��������� ����� $xmlFile"
                $flag_err = $true
            }
        }
    }

    return $flag_err
}

Function 440_out_test{
    #��������� �� ����������� XSD - �������
    <#if (Validate-Catalog){
        $title = "������ ���������"
        $message = "��� ��������� ��������� ������. ��������� �������� ����������?"
        $yes = New-Object System.Management.Automation.Host.ChoiceDescription "�� - &0", "��"
        $no = New-Object System.Management.Automation.Host.ChoiceDescription "��� - &1", "���"
        $options = [System.Management.Automation.Host.ChoiceDescription[]]($yes, $no)
        try {
	        $choice = $host.ui.PromptForChoice($title, $message, $options, 1)
	        switch ($choice){
		        0  { $proceed = $true}
		        1  { $proceed = $false}
	        }	
        }
        catch [Management.Automation.Host.PromptingException] {
	        Write-Log -EntryType Warning -Message "�����!"
            exit
        }
        if (!$proceed){
            return
        }
    }#>
}