
#Always the first line of any powershell script.
Set-StrictMode -Version Latest

# load the AMO library
[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.AnalysisServices.adomdclient") > $null

# load the SqlServer PowerShell module. This comes from PowerShellgallery.com
Import-Module SqlServer

#input the servers you want to iterate over here:
$servers = "SQL2017A", "SQl2016A"

#start looping over all of the servers in the list above
foreach ($s in $server)
{
    #establish a connection for each server
    $connStr = "data source=$s"
    [Microsoft.AnalysisServices.adomdclient.adomdconnection]$cnn = new-object Microsoft.AnalysisServices.adomdclient.adomdconnection($connStr)
    $cmd = new-Object Microsoft.AnalysisServices.AdomdClient.AdomdCommand
    $cmd.Connection = $cnn
    
    #the command we want to run against the system tables in SSAS
    $getlistofdatabases = "SELECT [CATALOG_NAME] FROM `$System.DBSCHEMA_CATALOGS"
    
    #open a connection
    $cnn.Open()

    # get a list of the databases on the server
    $cmd.CommandText = $getlistofdatabases
    $dbs = new-Object Microsoft.AnalysisServices.AdomdClient.AdomdDataAdapter($cmd)
    #create a dataset object to store the result
    $dsCmd = new-Object System.Data.DataSet
    #load the dataset object with the list of databases
    $dbs.Fill($dsCmd) > $null
    #retrive the rows from the first column of the dataset table
    $drCmd = $dsCmd.Tables[0].rows


    #begin looping over all of the databases returned
    foreach($database in $drCmd.CATALOG_NAME)
    {
        #run the backup database cmdlet
        Backup-ASDatabase -Server $s -Name $database -BackupFile "($database)_Backup_$(Get-Date -f yyyy-MM-dd).abf"
    
    }

    #close the Analysis Services connection
    $cnn.Close()


    #optionally, i could add a step here to go log in a sql table somewhere in my environment that the as database was successfully backed up on a certain day
}