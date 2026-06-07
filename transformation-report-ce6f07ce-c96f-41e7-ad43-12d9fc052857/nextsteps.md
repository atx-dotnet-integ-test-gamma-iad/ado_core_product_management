# Next Steps

The solution appears to have transformed successfully — no build errors were detected across any of the projects in the solution.

## Validation Steps

### 1. Review Target Framework
Open each `.csproj` file and confirm the `<TargetFramework>` element is set to the intended cross-platform .NET version (e.g., `net8.0`). Example:

```xml
<PropertyGroup>
  <TargetFramework>net8.0</TargetFramework>
</PropertyGroup>
```

### 2. Restore NuGet Packages
Run the following command from the solution root to ensure all dependencies resolve correctly:

```bash
dotnet restore
```

### 3. Build the Solution
Perform a full build to confirm there are no compilation issues:

```bash
dotnet build --configuration Release
```

### 4. Run Existing Tests
If the solution contains test projects, execute them to verify runtime behavior matches expectations:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

### 5. Check for Removed or Replaced APIs
Even without build errors, some APIs that existed in .NET Framework may behave differently in cross-platform .NET. Review the code for usage of the following common problem areas:

- `System.Web` — not available in cross-platform .NET
- `AppDomain` — partially supported
- `BinaryFormatter` — deprecated and disabled by default
- Windows Registry access (`Microsoft.Win32.Registry`) — only functional on Windows
- `System.Drawing` — requires the `System.Drawing.Common` NuGet package and may have platform restrictions

Use the [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the `Microsoft.DotNet.PlatformAbstractions` tooling to surface any remaining compatibility concerns.

### 6. Run the Application
Execute the application directly to confirm it starts and behaves as expected:

```bash
dotnet run --project ./AdoCore/AdoCore.csproj --configuration Release
```

### 7. Test on Target Platforms
Since the goal is cross-platform support, run the application on each intended operating system (Windows, Linux, macOS) to identify any platform-specific runtime issues that would not surface during compilation.

### 8. Publish the Application
Once validation is complete, publish a self-contained or framework-dependent build as appropriate:

```bash
# Framework-dependent
dotnet publish --configuration Release --output ./publish

# Self-contained (example for Linux x64)
dotnet publish --configuration Release --runtime linux-x64 --self-contained true --output ./publish-linux
```

Review the contents of the output directory to confirm all required assets are present before deployment.