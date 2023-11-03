$allpools = (Get-CimInstance -EA SilentlyContinue -ClassName applicationpool -Namespace root\webadministration).Name
$allprocids = Get-CimInstance -EA SilentlyContinue -ClassName WorkerProcess -Namespace root\webadministration | Select AppPoolName,ProcessId

function get-WmiProcess($wpname) {
    Try {
        $procid = ($allprocids | Where-Object AppPoolName -eq "${wpname}").ProcessId
        $data = ($processinfo | Where-Object IDProcess -eq $procid)

        $defaultVal = 0
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

$processinfo = (Get-CimInstance -EA SilentlyContinue -ClassName Win32_PerfRawData_PerfProc_Process -Filter "Name like 'w3wp%'") | select HandleCount,IDProcess,IOReadBytesPerSec,IOReadOperationsPerSec,IOWriteBytesPerSec,IOWriteOperationsPerSec,PercentProcessorTime,PrivateBytes,ThreadCount,WorkingSet,WorkingSetPeak,WorkingSetPrivate

#performance counters available:CreatingProcessID,ElapsedTime,Frequency_Object,Frequency_PerfTime,Frequency_Sys100NS,HandleCount,IDProcess,IODataOperationsPerSec,IOOtherOperationsPerSec,IOReadBytesPerSec,IOReadOperationsPerSec,IOWriteBytesPerSec,IOWriteOperationsPerSec,IODataBytesPerSec,IOOtherBytesPerSec,PageFaultsPerSec,PageFileBytes,PageFileBytesPeak,PercentPrivilegedTime,PercentProcessorTime,PercentUserTime,PoolNonpagedBytes,PoolPagedBytes,PriorityBase,PrivateBytes,ThreadCount,Timestamp_Object,Timestamp_PerfTime,Timestamp_Sys100NS,VirtualBytes,VirtualBytesPeak,WorkingSet,WorkingSetPeak,WorkingSetPrivate
#WorkingSetPrivate = RAM Usage as in task manager

#To get other counters related to IIS/.Net
#Get-WmiObject -List -Namespace root\cimv2 | select -Property name | where name -like "*Win32_PerfFormattedData_W3SVC*"
# Name
# ----
# Win32_PerfFormattedData_W3SVC_WebService
# Win32_PerfFormattedData_W3SVC_WebServiceCache
# Win32_PerfFormattedData_W3SVCW3WPCounterProvider_W3SVCW3WP
#Get-WmiObject -Class Win32_PerfFormattedData_W3SVC_WebService
#Get-WmiObject -List -Namespace root\cimv2 | select -Property name | where name -like "*Win32_PerfRawData_NET*"
#...

$results = @()
$allpools | foreach {
    $data = get-WmiProcess $_
    $results += @{
        'application' = $_.ToUpper()
        'data' = $data
    }
}

$results | ConvertTo-Json