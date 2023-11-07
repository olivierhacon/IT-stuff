# Zabbix : IIS Application Pools Monitoring using Low-Level Discovery with Dependent items

## 1.	Prerequisites
### 1.1  Web-Scripting-Tools feature installation (on IIS servers)

```powershell
Install-WindowsFeature -Name Web-Scripting-Tools
```
### 1.2 Script Preparation:
A. IIS Application Pools Discovery Script ([iis_apppools_discovery.ps1](iis_apppools_discovery.ps1)):

```powershell
# Retrieves the names of all application pools using the Get-CimInstance cmdlet from the 'applicationpool' class within the 'root\webadministration' namespace
# Error Action (EA) is set to SilentlyContinue to ignore any non-terminating errors that occur during the command.
$allpools = (Get-CimInstance -EA SilentlyContinue -ClassName applicationpool -Namespace root\webadministration).Name

# Constructs a hashtable with a single key "data"
# This "data" key contains an array of hashtables
# Each inner hashtable represents an application pool, with a key "{#APPNAME}" corresponding to the name of the application pool converted to uppercase
# The foreach loop iterates over each name in the $allpools array to create these hashtables
# @{ "{#APPNAME}" = $_.ToUpper() } creates a hashtable with one key-value pair for each application pool name
@{  
    "data" = $allpools | foreach { @{
        "{#APPNAME}" = $_.ToUpper()  # Convert the application pool name to uppercase and assign it to the "{#APPNAME}" key
    }}
} | ConvertTo-Json  # Converts the entire structure to a JSON formatted string
```

This script will just discover the application pools on the IIS server. The output looks like:

```json
[
    {"{#APPNAME}": "app1"},
    {"{#APPNAME}": "app2"},
    {"{#APPNAME}": "app3"}
]
```
B. Main Metrics Script ([iis_apppools_wmi_metrics.ps1](iis_apppools_wmi_metrics.ps1)):

```powershell
# Retrieve all application pool names using the Get-CimInstance cmdlet for the 'applicationpool' class
$allpools = (Get-CimInstance -EA SilentlyContinue -ClassName applicationpool -Namespace root\webadministration).Name

# Retrieve all worker processes, including their application pool names and process IDs
$allprocids = Get-CimInstance -EA SilentlyContinue -ClassName WorkerProcess -Namespace root\webadministration | Select AppPoolName,ProcessId

# Define a function to get process information for a given application pool name
function get-WmiProcess($wpname) {
    Try {
        # Find the process ID for the given application pool name from the retrieved worker processes
        $procid = ($allprocids | Where-Object AppPoolName -eq "${wpname}").ProcessId
        
        # Find the process information for the found process ID
        $data = ($processinfo | Where-Object IDProcess -eq $procid)

        # Default value to be used if any metric is null
        $defaultVal = 0
        
        # Return a hashtable with various process metrics, using default value if the actual value is null
        return @{
            IOReadOperationsPerSec = if ($data.IOReadOperationsPerSec -ne $null) { $data.IOReadOperationsPerSec } else { $defaultVal }
            IOWriteOperationsPerSec = if ($data.IOWriteOperationsPerSec -ne $null) { $data.IOWriteOperationsPerSec } else { $defaultVal }
            IOReadBytesPerSec = if ($data.IOReadBytesPerSec -ne $null) { $data.IOReadBytesPerSec } else { $defaultVal }
            WorkingSetPeak = if ($data.WorkingSetPeak -ne $null) { $data.WorkingSetPeak } else { $defaultVal }
            HandleCount = if ($data.HandleCount -ne $null) { $data.HandleCount } else { $defaultVal }
            ThreadCount = if ($data.ThreadCount -ne $null) { $data.ThreadCount } else { $defaultVal }
            IOWriteBytesPerSec = if ($data.IOWriteBytesPerSec -ne $null) { $data.IOWriteBytesPerSec } else { $defaultVal }
            PercentProcessorTime = if ($data.PercentProcessorTime -ne $null) { $data.PercentProcessorTime } else { $defaultVal }
            WorkingSet = if ($data.WorkingSet -ne $null) { $data.WorkingSet } else { $defaultVal }
            WorkingSetPrivate = if ($data.WorkingSetPrivate -ne $null) { $data.WorkingSetPrivate } else { $defaultVal }
            PrivateBytes = if ($data.PrivateBytes -ne $null) { $data.PrivateBytes } else { $defaultVal }
        }
    }
    Catch {
        # If an error occurs, write the error message and return a hashtable with all metrics set to 0
        Write-Error $_.Exception.Message
        return @{
            IOReadOperationsPerSec = 0
            IOWriteOperationsPerSec = 0
            IOReadBytesPerSec = 0
            WorkingSetPeak = 0
            HandleCount = 0
            ThreadCount = 0
            IOWriteBytesPerSec = 0
            PercentProcessorTime = 0
            WorkingSet = 0
            WorkingSetPrivate = 0
            PrivateBytes = 0
        }
    }
}

# Retrieve performance information for processes with names like 'w3wp%'*
$processinfo = (Get-CimInstance -EA SilentlyContinue -ClassName Win32_PerfRawData_PerfProc_Process -Filter "Name like 'w3wp%'") | select HandleCount,IDProcess,IOReadBytesPerSec,IOReadOperationsPerSec,IOWriteBytesPerSec,IOWriteOperationsPerSec,PercentProcessorTime,PrivateBytes,ThreadCount,WorkingSet,WorkingSetPeak,WorkingSetPrivate

# Initialize an array to hold the results
$results = @()

# Iterate over each application pool
$allpools | foreach {
    # Get the WMI process information for the current application pool
    $data = get-WmiProcess $_
    
    # Add the application pool name (converted to upper case) and its data to the results array
    $results += @{
        'application' = $_.ToUpper()
        'data' = $data
    }
}

# Convert the results array to JSON format and output it
$results | ConvertTo-Json
```

This script retrieves values for each application pool? The output looks like:

```bash
[
    {
        "application": "app1",
        "data":  {
                     "IOReadOperationsPerSec":  ...,
                     "IOWriteOperationsPerSec":  ...,
                     "IOReadBytesPerSec":  ...,
                     "WorkingSetPrivate":  ...,
                     "WorkingSetPeak":  ...,
                     "HandleCount":  ...,
                     "ThreadCount":  ...,
                     "IOWriteBytesPerSec":  ...,
                     "PercentProcessorTime":  ...,
                     "WorkingSet":  ...,
                     "PrivateBytes":  ...
                 }
    },
    ...
]
```
****Note about performance counters*** :  
- Performance counters available for $processinfo:  
CreatingProcessID, ElapsedTime, Frequency_Object, Frequency_PerfTime, Frequency_Sys100NS, HandleCount, IDProcess, IODataOperationsPerSec, IOOtherOperationsPerSec, IOReadBytesPerSec, IOReadOperationsPerSec, IOWriteBytesPerSec, IOWriteOperationsPerSec, IODataBytesPerSec, IOOtherBytesPerSec, PageFaultsPerSec, PageFileBytes, PageFileBytesPeak, PercentPrivilegedTime, PercentProcessorTime, PercentUserTime, PoolNonpagedBytes, PoolPagedBytes, PriorityBase, PrivateBytes, ThreadCount, Timestamp_Object, Timestamp_PerfTime, Timestamp_Sys100NS, VirtualBytes, VirtualBytesPeak, WorkingSet, WorkingSetPeak, WorkingSetPrivate 
- WorkingSetPrivate = RAM Usage as in task manager

- Here are some additional commands to retrieve other counters related to IIS/.NET: 
```powershell
Get-WmiObject -List -Namespace root\cimv2 | select -Property name | where name -like "*Win32_PerfFormattedData_W3SVC*"
Name
----
Win32_PerfFormattedData_W3SVC_WebService
Win32_PerfFormattedData_W3SVC_WebServiceCache
Win32_PerfFormattedData_W3SVCW3WPCounterProvider_W3SVCW3WP

Get-WmiObject -Class Win32_PerfFormattedData_W3SVC_WebService
Get-WmiObject -List -Namespace root\cimv2 | select -Property name | where name -like "*Win32_PerfRawData_NET*"
...
```
### 1.3 Zabbix Agent Configuration:
Modify the zabbix_agentd.conf adding these lines:

```plaintext
UserParameter=iis.apppools.discovery[*],powershell -NoProfile -ExecutionPolicy Bypass -File C:\zabbix\script\iis_apppools_discovery.ps1
UserParameter=iis.apppools.metrics[*],powershell -NoProfile -ExecutionPolicy Bypass -File C:\zabbix\script\iis_apppools_wmi_metrics.ps1
```
Restart the Zabbix agent after adding these lines and check the zabbix_agentd.log.


## 2. Apppool low-Level discovery with dependent items configuration:

### A. Create a template:


- Go to Configuration > Templates  
- Click on "Create template":  
```plaintext
Template name: My_Template_IIS
Groups: Assign the template to one or more groups
```
### B. Master Item for Collecting Raw Data:

You need to set up one master item that fetches the raw JSON data outside the discovery rule.

- Within the template go to the Items tab  
- Click on "Create Item":  
```plaintext
Name: Metrics RAW data IIS apppools
Type: Zabbix agent
Key: iis.apppools.metrics
Information Type: Text
```
This item will execute the script that returns all metrics for all app pools.

### C. Setting up the Discovery Rule:


- Within the template go to the "Discovery Rules" tab  
- Click on "Create Discovery Rule":  
```plaintext
Name: "Discovery IIS apppools".
Type: "Zabbix agent".
Key: iis.apppools.discovery.
Update Interval: Set how often you want Zabbix to perform the discovery. For instance, "1h" for every hour.
```
This discovery rule will execute the script that returns all the application name.

### D. Item Prototypes within Discovery Rule:

Now, within your discovery rule, create item prototypes to fetch individual metrics for each app pool. These keys should be dynamic based on the discovery.

- Within the discovery rule go to the "Item protoypes" tab  
- Click on "Create Item protoype":  
```plaintext
Name: "IO Read Operations Per Sec for {#APPNAME}"
Type: Dependent item
Key: iis.apppool.metric.IOReadOperationsPerSec[{#APPNAME}] (Note the use of {#APPNAME} macro to make it dynamic).
Information Type: Numeric (float) or others based on metric type.
Master item: Use the select button to choose the "Metrics RAW data IIS apppools" item you created.
Units: If the value is in bytes, you can set the item's Units property to B. Zabbix will automatically convert and display the value in the appropriate format (e.g., KB, MB, GB, etc.).
```
#### Preprocessing:
- Within the Item protoype go to the "Preprocessing" tab
- Click on "Add" under "Preprocessing steps"
- Choose "JSONPath" from the dropdown
- Enter the JSONPath expression to extract the metric from the raw JSON: 

```plaintext
$[?(@.application=="{#APPNAME}")].data.IOReadOperationsPerSec
```
This preprocessing step will extract the IOReadOperationsPerSec metric from the raw JSON data collected by Zabbix for a specific application pool identified by the {#APPNAME} macro.

- Add another "Preprocessing steps"
- Choose "Regular expression" from the dropdown
- In the pattern, enter:
```regex
 \[(\d+)\]

 #This will match a number enclosed in square brackets
 ```
- In the result, enter:
```regex
 \1 

#This will return just the number
```
This preprocessing step will extract the number from the string and provide it to Zabbix in a format it can understand.


#### The PercentProcessorTime value:

This value is given as the number of CPU seconds a process uses per second, with a value of 1 representing 100%.  
To convert this to a more conventional percentage representation, you can preprocess this data in Zabbix.  

The item prototype that collects PercentProcessorTime needs a special setup:

- Click on "Add" under "Preprocessing steps"
- Choose Custom multiplier. As the multiplier, enter:
```plaintext
0.0000001
```
- Click on "Add" under "Preprocessing steps"
This will convert the large number you receive (like 64375000) into a more reasonable figure.  
But it will still be in the format 0.xx for percentage.

- Add Another Multiplier for Percentage
- Choose Custom multiplier. As the multiplier, enter:
```plaintext
100
```
This will convert the value from the previous step into a percentage format.

- Add Another Preprocessing steps
- Choose Change per second from the dropdown.

Finally, in the Units field of the Item prototype, you can enter % so that Zabbix will display the value as a percentage.

### E. Create triggers and alert:

- Within the discovery rule go to the "Trigger prototypes" tab  
- Click on "Create trigger prototype":  
```plaintext
Item: Choose the dependent item prototype. For instance, PercentProcessorTime for {#APPNAME}.
Function: Select the last() function. This will use the most recent collected data point.
Last of (T): This indicates how far back you want to look for the most recent data point (blank by default).
Time shift: This allows you to analyze data from a specific time in the past.
Result: This is where you'll specify the threshold. For instance, change the operator from = to >, and set the value to 10. Now, the trigger should activate whenever the PercentProcessorTime exceeds 10%.
Severity: Choose a severity level for this alert, such as Warning, Average or High.
```
