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
Perform a full build to confirm the clean state is consistent:

```bash
dotnet build --configuration Release
```

Address any warnings that surface, particularly those related to nullable reference types or obsolete API usage, as these can indicate runtime issues.

### 4. Run Existing Tests
If the solution contains test projects, execute them to verify runtime behavior has not regressed:

```bash
dotnet test --configuration Release
```

Review test output carefully. A successful build does not guarantee correct runtime behavior after a framework migration.

### 5. Audit Platform-Specific API Usage
Use the .NET Compatibility Analyzer or review the code manually for any APIs that were available in .NET Framework but are not available or behave differently in cross-platform .NET. Common areas to check include:

- `System.Windows.Forms` or `System.Web` references (not available cross-platform)
- Registry access (`Microsoft.Win32.Registry`)
- `AppDomain` usage
- `BinaryFormatter` (deprecated and disabled by default)
- P/Invoke calls targeting Windows-specific native libraries

### 6. Run on Target Platforms
If cross-platform support is a goal, run the application on each intended operating system (Linux, macOS, Windows) to surface any platform-specific runtime failures that would not appear during a Windows-only build.

```bash
dotnet run --configuration Release
```

### 7. Review NuGet Package Compatibility
Check that all third-party NuGet packages in use have versions that support the target framework. Visit [nuget.org](https://www.nuget.org) or use the following command to inspect package details:

```bash
dotnet list package --outdated
```

Update packages where newer versions provide better framework compatibility.

### 8. Publish the Application
Once validation is complete, publish the application using the appropriate runtime identifier for your target environment:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained false
```

Replace `linux-x64` with the appropriate runtime identifier (`win-x64`, `osx-x64`, etc.) as needed. Review the publish output directory to confirm all required assets are present.