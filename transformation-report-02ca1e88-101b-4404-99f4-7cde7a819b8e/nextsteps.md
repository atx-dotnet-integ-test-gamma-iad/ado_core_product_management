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

Address any warnings that surface, particularly those related to nullable reference types or obsolete API usage, as these can indicate areas that may cause runtime issues.

### 4. Run Existing Tests
If the solution contains test projects, execute them to verify that existing behavior is preserved:

```bash
dotnet test --configuration Release
```

Review test results carefully. Any failing tests should be investigated before proceeding.

### 5. Audit Platform-Specific Code
Search the codebase for APIs that were historically Windows-only, such as those in the following namespaces:

- `Microsoft.Win32`
- `System.Windows.Forms`
- `System.Drawing`
- `System.Runtime.InteropServices` (P/Invoke calls)

Use the .NET Compatibility Analyzer to assist with this:

```bash
dotnet add package Microsoft.DotNet.Analyzers.Compatibility
```

Any platform-specific calls should either be guarded with runtime checks using `OperatingSystem.IsWindows()` or replaced with cross-platform alternatives.

### 6. Review Configuration and App Settings
If the project previously used `App.config` or `Web.config`, confirm that settings have been migrated to `appsettings.json` or environment variables where appropriate, as `System.Configuration` support is limited in cross-platform .NET.

### 7. Verify Output and Runtime Behavior
Run the application directly and exercise its primary functionality:

```bash
dotnet run --project ./AdoCore/AdoCore.csproj --configuration Release
```

Compare the runtime behavior against the legacy application to confirm functional equivalence.

### 8. Check for Removed or Changed APIs
Review the [.NET Upgrade Assistant compatibility report](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or consult the [.NET API differences documentation](https://learn.microsoft.com/en-us/dotnet/core/compatibility/) for any APIs that were removed or changed between the legacy .NET Framework version and the current target framework.

### 9. Publish the Application
Once validation is complete, publish the application for the target platform:

```bash
dotnet publish --configuration Release --runtime win-x64 --self-contained false
```

Adjust the `--runtime` identifier to match your deployment target (e.g., `linux-x64`, `osx-x64`). Use `--self-contained true` if the target machine does not have the .NET runtime installed.