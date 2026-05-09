# Next Steps

The solution appears to have transformed successfully — no build errors were detected across any of the projects in the solution.

## Validation

### 1. Verify Target Framework
Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

### 2. Restore NuGet Packages
Run the following command from the solution root to ensure all dependencies resolve correctly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or unresolved dependencies.

### 3. Build the Solution
Perform a full build to confirm there are no issues that may have been missed:

```bash
dotnet build --configuration Release
```

Address any warnings that surface, particularly those related to nullable reference types or obsolete APIs, as these can indicate latent issues.

### 4. Run Existing Tests
If the solution contains test projects, execute them to verify that existing behavior is preserved:

```bash
dotnet test --configuration Release
```

Review test output carefully. Any failures that were not present in the original project should be investigated as potential regressions introduced during transformation.

### 5. Review Platform-Specific Code
Search the codebase for any APIs that were available in .NET Framework but behave differently or are unavailable in cross-platform .NET. Common areas to check include:

- `System.Windows.Forms` or `System.Web` references
- Registry access (`Microsoft.Win32.Registry`)
- Windows Communication Foundation (WCF) server-side usage
- `AppDomain` usage beyond what is supported
- P/Invoke calls targeting Windows-only native libraries

Use the [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the `Microsoft.DotNet.PlatformAbstractions` tooling to assist with this review if needed.

### 6. Run the Application
Execute the application directly and exercise its primary workflows to confirm runtime behavior matches the original:

```bash
dotnet run --project <YourStartupProject>.csproj --configuration Release
```

### 7. Verify Output Artifacts
Check that the published output is correct for the intended deployment target:

```bash
dotnet publish --configuration Release --runtime <target-rid> --self-contained false
```

Replace `<target-rid>` with the appropriate Runtime Identifier, for example `win-x64`, `linux-x64`, or `osx-x64`.

Inspect the output directory to confirm all expected assemblies, configuration files, and assets are present.