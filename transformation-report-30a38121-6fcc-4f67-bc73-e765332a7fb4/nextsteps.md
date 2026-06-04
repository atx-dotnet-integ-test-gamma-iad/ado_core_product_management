# Next Steps

The solution appears to have transformed successfully — no build errors were detected across any of the projects in the solution.

## Validation Steps

### 1. Verify Target Framework
Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure no projects are still referencing `net48`, `netcoreapp3.1`, or other legacy/EOL targets unless intentionally kept for multi-targeting.

### 2. Restore Dependencies
Run the following command from the solution root to confirm all NuGet packages resolve correctly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or packages that do not support the target framework.

### 3. Build the Solution
Perform a clean build to confirm there are no issues that may have been masked:

```bash
dotnet build --configuration Release
```

Address any warnings that surface, particularly those related to nullable reference types or obsolete API usage, as these can indicate compatibility concerns.

### 4. Run the Test Suite
If the solution contains test projects, execute them to verify runtime behavior is consistent with the original project:

```bash
dotnet test --configuration Release
```

Review any failing tests carefully, as failures after a framework migration often point to behavioral differences in APIs, serialization, or threading models between .NET Framework and modern .NET.

### 5. Audit Removed or Replaced APIs
Check the code for any APIs that were available in .NET Framework but behave differently in modern .NET. Common areas to review include:

- `System.Web` dependencies (not available in modern .NET)
- `BinaryFormatter` usage (disabled by default in .NET 5+)
- `AppDomain` APIs with limited support
- Windows-specific APIs if cross-platform support is required

The [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) can help identify these programmatically.

### 6. Run the Application
Execute the application directly and verify its core functionality:

```bash
dotnet run --project ./AdoCore/AdoCore.csproj --configuration Release
```

Test all major code paths, particularly any database access, file I/O, or network calls, as these are common areas where cross-platform differences surface at runtime.

### 7. Publish the Application
Once validation is complete, publish the application to confirm the output is as expected:

```bash
dotnet publish --configuration Release --output ./publish
```

Review the output directory to confirm all required assets, configuration files, and dependencies are present.