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
Perform a full build to confirm there are no errors:

```bash
dotnet build --configuration Release
```

### 4. Run Existing Tests
If the solution contains test projects, execute them to verify runtime behavior has not regressed:

```bash
dotnet test --configuration Release
```

Review the test output for any failures or skipped tests that may indicate behavioral differences between the legacy and modernized versions.

### 5. Review Removed or Replaced APIs
Check the code for any usage of APIs that were available in .NET Framework but have changed behavior in cross-platform .NET, including:

- `System.Web` dependencies (not available in .NET Core and later)
- `AppDomain` usage
- Windows-specific registry or file path assumptions
- `BinaryFormatter` (deprecated and disabled by default)

Use the [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the `Microsoft.DotNet.PlatformAbstractions` tooling to surface any remaining compatibility concerns.

### 6. Verify Runtime Behavior
Run the application manually and exercise the primary workflows to confirm the output matches the behavior of the original legacy project.

### 7. Review `AdoCore.csproj` Specifically
Since `AdoCore` is the most foundational project in the solution, confirm the following:

- All ADO.NET-related NuGet packages (e.g., database drivers such as `Microsoft.Data.SqlClient`) are explicitly referenced, as some were previously included transitively via .NET Framework.
- Connection string handling and database provider initialization code is compatible with the target runtime.

### 8. Check for Platform-Specific Code
If the application is intended to run on non-Windows platforms, audit any P/Invoke calls, COM interop usage, or Windows-specific file paths (`C:\`, registry access, etc.) within `AdoCore` and dependent projects.