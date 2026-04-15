# Next Steps

The solution appears to have transformed successfully — no build errors were detected across any of the projects in the solution.

## Validation Steps

### 1. Verify Target Framework
Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure no projects are still referencing `net48` or other Windows-only framework monikers unless that is intentional.

### 2. Restore Dependencies
Run the following command from the solution root to confirm all NuGet packages resolve correctly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or packages that do not support the target framework.

### 3. Build the Solution
Perform a clean build to confirm there are no errors or warnings that were not captured previously:

```bash
dotnet build --configuration Release
```

Address any warnings that could indicate runtime issues, such as nullable reference warnings or platform compatibility warnings.

### 4. Run the Test Suite
If the solution contains test projects, execute them to verify existing behavior has not been broken:

```bash
dotnet test --configuration Release
```

Review test output carefully. Any failing tests should be investigated before proceeding.

### 5. Check for Windows-Specific API Usage
Use the .NET Compatibility Analyzer or the following command to scan for platform-specific API calls that may not behave correctly on Linux or macOS:

```bash
dotnet build /p:EnableNETAnalyzers=true /p:AnalysisMode=All
```

Pay attention to diagnostics prefixed with `CA1416`, which flag Windows-only APIs.

### 6. Run the Application
Execute the application directly to confirm it starts and operates as expected:

```bash
dotnet run --project ./AdoCore/AdoCore.csproj --configuration Release
```

Test the primary workflows manually to verify functional correctness.

### 7. Verify NuGet Package Compatibility
Cross-reference each NuGet dependency against [nuget.org](https://www.nuget.org) to confirm the versions in use support the target framework. Replace any packages that have a newer compatible version or a recommended alternative for cross-platform .NET.

### 8. Review `app.config` / `web.config` Migrations
If the original project used `app.config` or `web.config`, confirm that settings have been migrated to `appsettings.json` or environment variables where appropriate, as `ConfigurationManager` behavior differs in cross-platform .NET.

### 9. Publish a Test Build
Produce a self-contained or framework-dependent publish output and verify it runs on the intended target platform:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained false
```

Adjust the `--runtime` flag to match your deployment target (`win-x64`, `osx-x64`, etc.).