# Creating a .NET Core Application for CPU and RAM Load Testing on IIS

##      Prerequisites
Install The .[NET SDK](https://dotnet.microsoft.com/en-us/download/dotnet) on your workstation.

To check the installation:

```powershell
dotnet --version
```

## 1.   Create a new .NET Core web application:
### 1.1 Create the application
```powershell
dotnet new webapi -n LoadTestApp
```
If you get this error message, you must manually create the NuGet.config file in your project directory:
> C:\Users\myuser\LoadTestApp\LoadTestApp.csproj : error NU1100: Unable to resolve 'Swashbuckle.AspNetCore (>= 6.5.0)' for 'net6.0'.
Failed to restore C:\Users\myuser\LoadTestApp\LoadTestApp.csproj (in 147 ms) you must manually create the NuGet.config file in your project directory.  

- To create it in the C:\Users\myuser\LoadTestApp directory:
```powershell
Set-Location C:\Users\myuser\LoadTestApp
```
- Use the Set-Content cmdlet in PowerShell to create the file and write content to it
```powershell
Set-Content -Path NuGet.config -Value @"
<?xml version="1.0" encoding="utf-8"?>
<configuration>
  <packageSources>
    <add key="NuGetOfficialV3" value="https://api.nuget.org/v3/index.json" />
    <!-- Add other sources here if needed -->
  </packageSources>
</configuration>
"@
```
- To check the content of the created file
```powershell
Get-Content NuGet.config
```
### 1.2   Modify the default WeatherForecast controller:

Replace the Controllers/WeatherForecastController.cs with the following:

```csharp
using Microsoft.AspNetCore.Mvc;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading;

namespace LoadTestApp.Controllers
{
    [ApiController]
    [Route("[controller]")]
    public class LoadController : ControllerBase
    {
        private static List<byte[]> MemoryList = new List<byte[]>();

        [HttpGet("cpu/{seconds}")]
        public ActionResult<string> LoadCPU(int seconds)
        {
            DateTime end = DateTime.Now.AddSeconds(seconds);

            while (DateTime.Now < end)
            {

            }

            return "CPU loaded!";
        }

        [HttpGet("ram/{megabytes}")]
        public ActionResult<string> LoadRAM(int megabytes)
        {
            try
            {
                for (int i = 0; i < megabytes; i++)
                {
                    byte[] buffer = new byte[1024 * 1024];
            
                    for (int j = 0; j < buffer.Length; j += 4096)  // assuming 4KB pages
                    {
                        buffer[j] = 0;
                    }
            
                    MemoryList.Add(buffer);
                }
            }
            catch (Exception e)
        {
                return $"Error: {e.Message}";
        }

            return $"Allocated {megabytes} MB of RAM!";
        }

        [HttpGet("free")]
        public ActionResult<string> FreeMemory()
        {
            MemoryList.Clear();
            GC.Collect();
            return "Memory cleared!";
        }
    }
}
```
Code explanation:

```csharp
// Here, we're importing required namespaces to enable the functionality of our code.
using Microsoft.AspNetCore.Mvc;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading;

namespace LoadTestApp.Controllers
{
    // This attribute indicates that the class will be treated as a controller in ASP.NET Core.
    [ApiController]
    // This attribute defines the route to access this controller. For instance: `/Load`
    [Route("[controller]")]
    public class LoadController : ControllerBase
    {
        // A static list to store byte arrays. This will be used to simulate RAM usage.
        private static List<byte[]> MemoryList = new List<byte[]>();

        // This is a route to test CPU load. When accessed, it will make the CPU busy for the specified number of seconds.
        [HttpGet("cpu/{seconds}")]
        public ActionResult<string> LoadCPU(int seconds)
        {
            // Calculate the end time based on the current time plus the specified seconds.
            DateTime end = DateTime.Now.AddSeconds(seconds);

            // Busy wait: Continuously check the time until we reach the end time. This loop makes the CPU busy.
            while (DateTime.Now < end)
            {
                // Busy wait
            }

            // Return a message indicating that the CPU was loaded.
            return "CPU loaded!";
        }

        // This is a route to test RAM load. When accessed, it will allocate the specified number of megabytes in RAM.
        [HttpGet("ram/{megabytes}")]
        public ActionResult<string> LoadRAM(int megabytes)
        {
            try
            {
                // Loop for the number of megabytes to allocate.
                for (int i = 0; i < megabytes; i++)
                {
                    // Create a new byte array of size 1 megabyte (1024 * 1024 bytes).
                    byte[] buffer = new byte[1024 * 1024];
            
                    // This loop touches each 4KB page of the buffer to ensure it's in the working set of memory.
                    for (int j = 0; j < buffer.Length; j += 4096)  // assuming 4KB pages
                    {
                        buffer[j] = 0;
                    }
            
                    // Add the buffer to the memory list to keep a reference to it (preventing garbage collection).
                    MemoryList.Add(buffer);
                }
            }
            catch (Exception e)
            {
                // If there's any error during allocation, return an error message.
                return $"Error: {e.Message}";
            }

            // Return a message indicating how much RAM was allocated.
            return $"Allocated {megabytes} MB of RAM!";
        }

        // This is a route to free up the memory that was allocated using the above route.
        [HttpGet("free")]
        public ActionResult<string> FreeMemory()
        {
            // Clear the memory list, removing references to the allocated buffers.
            MemoryList.Clear();
            // Force a garbage collection to free up the memory.
            GC.Collect();
            // Return a message indicating that the memory was cleared.
            return "Memory cleared!";
        }
    }
}
```

### 1.3 Publish the application
```powershell
dotnet publish -c Release
```
Your application files are available in: C:\Users\myuser\LoadTestApp\bin\Release\net6.0\publish. This directory contains the executable, configuration files, and any other files required to run your application.

### 1.4 Host the application

- Create a new website or application in IIS and point it to the published folder.

- Create a new application pool for this website and set its .NET version to "No Managed Code" since .NET Core has its own web server.

- Make sure the Application Pool is set to "Always Running" and set the "Start Mode" to "Always Running" as well.

- You might need to install the ASP.NET Core Hosting Bundle if you haven’t already [ASP.NET Core Hosting Bundle](https://dotnet.microsoft.com/download/dotnet-core/thank-you/runtime-aspnetcore-5.0.5-windows-hosting-bundle-installer)

## 2.   Load Test:

You can now navigate to:
- http://[localhost:port]/load/cpu/10 to load the CPU for 10 seconds.
- http://[localhost:port]/load/ram/100 to load 100 MB of RAM.
- http://[localhost:port]/load/free to free the allocated RAM.
