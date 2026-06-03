# Next Steps

The solution appears to have transformed successfully — no build errors were detected across any of the projects in the solution.

## Validation Steps

### 1. Verify Target Framework
Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

### 2. Restore NuGet Packages
Run the following command from the solution root to ensure all dependencies are restored cleanly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated or unlisted packages and consider updating them.

### 3. Build the Solution
Perform a full build to confirm there are no compilation issues:

```bash
dotnet build --configuration Release
```

### 4. Run Existing Tests
If the solution contains test projects, execute them to verify that existing behavior is preserved:

```bash
dotnet test --configuration Release
```

Review any failing tests carefully, as they may indicate behavioral differences between the legacy .NET Framework runtime and the new cross-platform .NET runtime.

### 5. Review Removed or Unsupported APIs
Use the [.NET Upgrade Assistant](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the [Platform Compatibility Analyzer](https://learn.microsoft.com/en-us/dotnet/standard/analyzers/platform-compat-analyzer) to identify any API usage that may compile successfully but behave differently or throw at runtime on non-Windows platforms.

### 6. Run the Application
Execute the application directly and exercise its primary code paths:

```bash
dotnet run --project AdoCore/AdoCore.csproj --configuration Release
```

Pay particular attention to:
- Database connectivity (ADO.NET providers may require platform-specific NuGet packages on Linux/macOS)
- File system paths (ensure no hardcoded Windows-style paths remain)
- Any use of `System.Configuration.ConfigurationManager`, which requires the `System.Configuration.ConfigurationManager` NuGet package on .NET Core and later

### 7. Verify ADO.NET Provider Packages
Given the project name `AdoCore`, confirm that the correct database driver NuGet package is explicitly referenced. Legacy drivers such as `System.Data.SqlClient` should be evaluated for replacement with `Microsoft.Data.SqlClient`:

```xml
<PackageReference Include="Microsoft.Data.SqlClient" Version="5.x.x" />
```

### 8. Check for `app.config` / `web.config` Usage
If the project previously relied on `app.config`, verify that connection strings and application settings have been migrated to `appsettings.json` or environment variables, which are the standard configuration mechanisms in modern .NET.

### 9. Inspect Output Artifacts
Confirm the build output directory contains the expected assemblies and that no required assets (such as native libraries or configuration files) are missing:

```bash
ls ./AdoCore/bin/Release/net8.0/
```