[string]$curDir = Split-Path -Path $myInvocation.MyCommand.Path -Parent

Import-Module PSSQLite

#Create a table
    $Database = "$curDir\Names.SQLite"
    
    Invoke-SqliteQuery -DataSource $Database -Query "CREATE TABLE NAMES (
        fullname VARCHAR(20) PRIMARY KEY,
        surname TEXT,
        givenname TEXT,
        BirthDate DATETIME)"

#Build up some fake data to bulk insert, convert it to a datatable
    $DataTable = 1..10000 | %{
        [pscustomobject]@{
            fullname = "Name $_"
            surname = "Name"
            givenname = "$_"
            BirthDate = (Get-Date).Adddays(-$_)
        }
    } | Out-DataTable

#Copy the data in within a single transaction (SQLite is faster this way)
    Invoke-SQLiteBulkCopy -DataTable $DataTable -DataSource $Database -Table Names -NotifyAfter 1000 -verbose
