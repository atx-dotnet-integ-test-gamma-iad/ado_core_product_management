# Next Steps

The solution appears to have transformed successfully — no build errors were detected across any of the projects in the solution.

## Validation Steps

### 1. Verify Target Framework
Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure no projects are still referencing `net48`, `net472`, or any other .NET Framework moniker unless that is intentional for multi-targeting.

### 2. Restore and Build Locally
Run the following commands from the solution root to confirm a clean restore and build:

```bash
dotnet restore
dotnet build --configuration Release
```

Review the output for any warnings that may indicate compatibility issues, even if they do not cause build failures.

### 3. Run Existing Tests
If the solution contains test projects, execute them to verify runtime behavior has not changed:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Address any failing tests before proceeding.

### 4. Check for Removed or Changed APIs
Even with a clean build, some APIs behave differently on cross-platform .NET compared to .NET Framework. Pay particular attention to:

- **Windows-specific APIs**: Any code using `System.Drawing`, `Microsoft.Win32`, registry access, or COM interop may only function on Windows. Use the [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the `CA1416` platform compatibility analyzer warning to identify these.
- **AppDomain**: Several `AppDomain` members are no longer supported or throw `PlatformNotSupportedException`.
- **Configuration**: `System.Configuration.ConfigurationManager` requires the `System.Configuration.ConfigurationManager` NuGet package on cross-platform .NET.
- **Reflection**: Some reflection behaviors differ; test any dynamic loading or plugin-style code paths explicitly.

### 5. Review NuGet Package Compatibility
Open the `.csproj` files and review each `<PackageReference>`. Confirm that all referenced packages support the target framework. You can check compatibility on [nuget.org](https://www.nuget.org) or by inspecting the package's supported frameworks listed under its metadata.

### 6. Run on Target Platforms
If cross-platform support (Linux, macOS) is a goal, run the application on each intended platform to catch any runtime issues that would not surface during a Windows build:

```bash
dotnet run --configuration Release
```

### 7. Publish a Self-Contained or Framework-Dependent Build
Once validation is complete, produce a publish artifact to confirm the output is as expected:

```bash
# Framework-dependent
dotnet publish --configuration Release --output ./publish

# Self-contained (example for Linux x64)
dotnet publish --configuration Release --runtime linux-x64 --self-contained true --output ./publish-linux
```

Verify the output directory contains all expected files and that the application starts correctly from the published output.

### 8. Review Startup and Configuration Code
If the project is an application (web, console, or desktop), review the entry point and any startup/configuration code for patterns that were common in .NET Framework but have changed in cross-platform .NET, such as:

- `WebConfigurationManager` replaced by `IConfiguration`
- `Global.asax` replaced by `Program.cs` / `Startup.cs` middleware pipeline
- `HttpContext.Current` replaced by injected `IHttpContextAccessor`