# Next Steps

The solution appears to have transformed successfully — no build errors were detected across any of the projects in the solution.

## Validation Steps

### 1. Verify Target Framework
Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure no projects are still referencing `net48`, `netcoreapp3.1`, or other outdated monikers unless intentionally targeting multiple frameworks.

### 2. Restore Dependencies
Run the following command from the solution root to confirm all NuGet packages resolve correctly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or unresolved references.

### 3. Build the Solution
Perform a full build to confirm there are no issues beyond what was captured in the initial error report:

```bash
dotnet build --configuration Release
```

Address any warnings that could indicate runtime issues, such as nullable reference warnings or platform compatibility warnings.

### 4. Run the Test Suite
If the solution contains test projects, execute them to verify functional correctness after the transformation:

```bash
dotnet test --configuration Release
```

Review test output carefully. A passing build does not guarantee behavioral correctness, so any failing tests should be investigated before proceeding.

### 5. Check for Windows-Specific API Usage
Use the .NET Compatibility Analyzer or review the build output for `CA1416` platform compatibility warnings. These indicate APIs that are only available on Windows and may cause runtime failures on Linux or macOS.

You can also run the following to surface these warnings explicitly:

```bash
dotnet build -p:PlatformTarget=AnyCPU --configuration Release
```

### 6. Validate Runtime Behavior
Run the application directly to confirm it starts and operates as expected:

```bash
dotnet run --project ./AdoCore/AdoCore.csproj --configuration Release
```

Test the primary workflows of the application manually or through integration tests to confirm parity with the legacy behavior.

### 7. Review Removed or Changed APIs
Cross-reference any usages of APIs that were available in .NET Framework but have changed or been removed in modern .NET. The [.NET Upgrade Assistant compatibility report](https://learn.microsoft.com/en-us/dotnet/core/porting/) and the [.NET API compatibility documentation](https://learn.microsoft.com/en-us/dotnet/core/compatibility/) are useful references for this.

Pay particular attention to:
- `System.Configuration` (replaced by `Microsoft.Extensions.Configuration`)
- `System.Web` (not available in modern .NET)
- WCF server-side components (not available in modern .NET without `CoreWCF`)
- Windows Registry access (`Microsoft.Win32.Registry`)

### 8. Publish the Application
Once validation is complete, publish the application for the target platform:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained false
```

Replace `linux-x64` with your intended runtime identifier (e.g., `win-x64`, `osx-x64`). Review the publish output directory to confirm all required assets are present.