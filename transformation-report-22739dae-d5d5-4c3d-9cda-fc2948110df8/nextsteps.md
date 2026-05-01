# Next Steps

The solution appears to have transformed successfully — no build errors were detected across any of the projects in the solution.

## Validation Steps

### 1. Verify Target Framework
Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure no projects are still referencing `net48` or any other .NET Framework moniker unless that is intentional.

### 2. Restore Dependencies
Run the following command from the solution root to confirm all NuGet packages resolve correctly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or packages that do not support the target framework.

### 3. Build the Solution
Run a full build to confirm there are no issues that may have been missed:

```bash
dotnet build --configuration Release
```

Review all warnings in the output, as some warnings may indicate compatibility issues that do not prevent compilation but could cause runtime problems.

### 4. Run the Test Suite
If the solution contains test projects, execute them to verify runtime behavior is consistent with the original project:

```bash
dotnet test --configuration Release
```

Review any failing tests carefully, as failures may indicate behavioral differences between .NET Framework and cross-platform .NET (e.g., differences in globalization, file path handling, or reflection behavior).

### 5. Check for Platform-Specific API Usage
Review the code for any APIs that were available in .NET Framework but are not fully supported or behave differently in cross-platform .NET. Common areas to check include:

- `System.Windows.Forms` or `System.Web` references (these are not cross-platform)
- Registry access (`Microsoft.Win32.Registry`)
- File path assumptions (backslash vs. forward slash)
- `AppDomain` usage
- COM interop

The [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the [Platform Compatibility Analyzer](https://learn.microsoft.com/en-us/dotnet/standard/analyzers/platform-compat-analyzer) can assist in identifying these issues.

### 6. Run the Application
Execute the application on each target platform (Windows, Linux, macOS as applicable) and verify that the runtime behavior matches expectations:

```bash
dotnet run --project ./AdoCore/AdoCore.csproj --configuration Release
```

### 7. Publish the Application
Once validation is complete, publish the application for the target runtime:

```bash
dotnet publish --configuration Release --runtime <runtime-identifier> --self-contained true
```

Replace `<runtime-identifier>` with the appropriate value, such as `win-x64`, `linux-x64`, or `osx-x64`. Review the publish output directory to confirm all required files are present.