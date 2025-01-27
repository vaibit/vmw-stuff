    <#
    param(
    [String]$Server="sql.premcloud.local",
    [String]$Database="vra",
    [String]$User="sa",
    [String]$Password="YourDBPassword",
    [Int32]$Attempts=101
    ) 
    
    $ConnectionString = "Data Source=$server;Initial Catalog=master;"
    if ([String]::IsNullOrEmpty($User))
    {
    $ConnectionString = $ConnectionString + "Integrated Security=True;"
    }
    else
    {
    $ConnectionString = $ConnectionString + "User Id=$User;Password=$Password;"
    }
    #>
    $Attempts=1000
    $ConnectionString ="server=$server ;database=$Database;user id=$User;password=$PassWord ;trusted_connection=true;"
    
    $durations = @() 
    
    $sw = [Diagnostics.Stopwatch ]::StartNew()
    for($i = 1; $i -le $Attempts; $i ++)
    {
    $transactionScope = New-Object System.Transactions.TransactionScope ([System.Transactions.TransactionScopeOption ]::RequiresNew)  
    
    Try
    {
    $stopwatch = [Diagnostics.Stopwatch ]::StartNew()
    $connection = New-Object System.Data.SqlClient.SqlConnection
    $connection.ConnectionString = $ConnectionString
    $connection.Open()
    $commmand = New-Object System.Data.SqlClient.SqlCommand
    $commmand.Connection = $connection
    $commmand.CommandText = "select * from sys.sysprocesses"
    $connection2 = New-Object System.Data.SqlClient.SqlConnection
    $connection2.ConnectionString = $ConnectionString
    $connection2.Open()
    $result = $commmand. ExecuteNonQuery()
    $connection.Close()
    $connection2.Close()
    $transactionScope.Complete()
    $durations += $stopwatch. Elapsed.Milliseconds
    $stopwatch.Stop()
    $stopwatch.Reset()
    }
    Catch [ system.exception]
    {
    $message = [String ]::Format("The following exception occurred, while executing SQL command. Message: {0}", $_. Exception.Message)
    $stackTrace = [String ]::Format("Stack trace: {0}" , $_.Exception .StackTrace)
    Write-Output $message
    Write-Output $stackTrace
    throw
    }
    Finally
    {
    $transactionScope.Dispose()
    }
    }
    Write-Output $sw .Elapsed
    $durations | Measure-Object -Average -Sum -Maximum -Minimum
