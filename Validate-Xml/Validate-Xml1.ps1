# Validate Schema
#
# Description
# -----------
# Validates an XML file against its inline provided schema reference
#
# Command line arguments
# ----------------------
# xmlFileName: Filename of the XML file to validate
# xsdFileName: FileName of the XSD file
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
        Write-Host "Проверка XML невозможна, поскольку не найден XML-файл в '$xmlFileName'"
        exit 2
    }

    # Check if the provided file exists
    if(!(Test-Path -Path $xsdFileName))
    {
        Write-Host "Проверка XML невозможна, поскольку XSD-файл не найден '$xsdFileName'"
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
        Write-Host $("Ошибка в XML: " + $_.Message) -ForegroundColor Red
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
        Write-Host -ForegroundColor Red "XML-файлы не найденны"
        exit        
    }
    
    $xmlFiles = Get-ChildItem "$work\*.xml"
    foreach ($xmlFile in $xmlFiles){
        $name3Char = $xmlFile.BaseName.Substring(0, 3)
        $name2Char = $xmlFile.BaseName.Substring(0, 2)
        
        if ($name2Char -eq "PB"){
            $name3Char = "PBQ"
        }
        $xsdName = $name3Char + "_300.xsd"
        $xsdFile = $schemaCatalog + "\" + $xsdName        
        
        if(!(Test-Path -Path $xsdFile)){
            Write-Host -ForegroundColor Red "Файл XSD-схемы не найден $xsdName"
        } else {
            $valid = Validate-Xml -xmlFileName $xmlFile -xsdFileName $xsdFile
            if ($valid -eq 0){
                Write-Host "Валидация файла прошла успешно $xmlFile" -ForegroundColor Green
            } else {
                Write-Host "Ошибка валидации файла $xmlFile" -ForegroundColor Red
            }
        }
    }
}

cls
[string]$dir1 = Split-Path -Path $myInvocation.MyCommand.Path -Parent
[string]$work = "$dir1\work"
[string]$schemaCatalog = "$dir1\xsd-schemas"

Validate-Catalog