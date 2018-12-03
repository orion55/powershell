# Create a SQLite database in memory
# This exists only as long as the connection is open
    $C = New-SQLiteConnection -DataSource :MEMORY: 

#Add some tables
    Invoke-SqliteQuery -SQLiteConnection $C -Query "
        CREATE TABLE OrdersToNames (OrderID INT PRIMARY KEY, Fullname TEXT);
        CREATE TABLE Names (Fullname TEXT PRIMARY KEY, Birthdate DATETIME);"

#Add some data
    Invoke-SqliteQuery -SQLiteConnection $C -SqlParameters @{BD = (Get-Date)} -Query "
        INSERT INTO OrdersToNames (OrderID, fullname) VALUES (1,'Cookie Monster');
        INSERT INTO OrdersToNames (OrderID) VALUES (2);
        INSERT INTO Names (Fullname, Birthdate) VALUES ('Cookie Monster', @BD)"

#Query the data.  Illustrate PSObject vs. Datarow filtering
    Invoke-SqliteQuery -SQLiteConnection $C -Query "SELECT * FROM OrdersToNames" |
        Where-Object { $_.Fullname }

    Invoke-SqliteQuery -SQLiteConnection $C -Query "SELECT * FROM OrdersToNames" -As DataRow |
        Where-Object { $_.Fullname }
    
#Joining.  Yeah, a CustomerID would make more sense :)
    Invoke-SqliteQuery -SQLiteConnection $C -Query "
        SELECT * FROM Names
            INNER JOIN OrdersToNames
            ON Names.fullname = OrdersToNames.fullname
    "

$c.close()