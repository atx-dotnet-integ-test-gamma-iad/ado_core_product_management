# Next Steps

The solution appears to have transformed successfully — no build errors were detected across any of the projects in the solution.

## Validation Steps

### 1. Verify Target Framework
Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure no projects are still referencing `net48` or other legacy .NET Framework monikers unless that is intentional for multi-targeting.

### 2. Restore Dependencies
Run the following command from the solution root to confirm all NuGet packages resolve correctly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or packages that do not support the target framework.

### 3. Build the Solution
Perform a clean build to confirm there are no errors or warnings that were not caught previously:

```bash
dotnet build --configuration Release
```

Address any warnings that could indicate runtime issues, such as nullable reference warnings or platform-compatibility warnings.

### 4. Run Existing Tests
If the solution contains test projects, execute the test suite to verify that existing behavior has been preserved:

```bash
dotnet test --configuration Release
```

Review any failing tests carefully, as they may indicate behavioral differences between .NET Framework and modern .NET.

### 5. Check for Windows-Specific APIs
Review the code for any APIs that are Windows-specific and may not behave correctly on Linux or macOS. Common areas to check include:

- `System.Drawing` (use `System.Drawing.Common` with caution, or migrate to an alternative such as `SkiaSharp`)
- Registry access (`Microsoft.Win32.Registry`)
- Windows Communication Foundation (WCF) client or server usage
- `System.Web` references, which are not available in modern .NET

The [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the `Microsoft.DotNet.PlatformAbstractions` package can help identify these.

### 6. Run the Application
Execute the application directly to confirm it starts and operates as expected:

```bash
dotnet run --project ./AdoCore/AdoCore.csproj --configuration Release
```

Perform smoke testing against the primary workflows of the application.

### 7. Review Configuration Files
Confirm that any `app.config` or `web.config` files have been migrated to `appsettings.json` or the appropriate modern .NET configuration model. Legacy XML-based configuration is not fully supported in modern .NET.

### 8. Verify Output Artifacts
Check the `bin/Release` output directory to confirm the expected assemblies, dependencies, and any publish profiles are producing the correct output:

```bash
dotnet publish --configuration Release --output ./publish
```

Review the contents of the `./publish` directory to ensure all required files are present.