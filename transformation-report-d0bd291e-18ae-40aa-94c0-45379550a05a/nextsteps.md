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
Perform a clean build to confirm there are no errors or warnings that were not surfaced previously:

```bash
dotnet build --configuration Release
```

Address any warnings that could indicate runtime issues, such as nullable reference warnings or platform compatibility warnings.

### 4. Run the Test Suite
If the solution contains test projects, execute them to verify that existing behavior has been preserved:

```bash
dotnet test --configuration Release
```

Review any failing tests carefully, as failures may indicate behavioral differences between the legacy .NET Framework and the new cross-platform .NET runtime.

### 5. Check for Windows-Specific API Usage
Use the .NET Compatibility Analyzer or review the build output for `CA1416` platform compatibility warnings. These warnings indicate calls to Windows-only APIs (such as certain `System.Drawing`, registry, or WCF APIs) that may fail on Linux or macOS at runtime even if they compile successfully.

You can enable the analyzer explicitly in your `.csproj` if it is not already active:

```xml
<EnableNETAnalyzers>true</EnableNETAnalyzers>
<AnalysisMode>All</AnalysisMode>
```

### 6. Run the Application
Execute the application directly and exercise its primary code paths:

```bash
dotnet run --project ./AdoCore/AdoCore.csproj --configuration Release
```

Verify that runtime behavior matches the expectations of the original legacy project.

### 7. Validate on Target Platforms
If cross-platform support is a goal, run the application on each intended operating system (Windows, Linux, macOS) to surface any platform-specific runtime issues that static analysis may not catch.

### 8. Review Removed or Changed APIs
Consult the [.NET breaking changes documentation](https://learn.microsoft.com/en-us/dotnet/core/compatibility/breaking-changes) relevant to the version you migrated from and the version you migrated to. Pay particular attention to areas such as:

- `System.Data` and ADO.NET behavior changes (relevant given the `AdoCore` project name)
- Serialization APIs
- Threading and synchronization primitives
- Configuration and app settings (e.g., `ConfigurationManager` usage)

### 9. Publish a Self-Contained Build
Once validation is complete, produce a publish output to confirm the final artifact is correct:

```bash
dotnet publish --configuration Release --self-contained false
```

Review the output directory to ensure all expected assemblies and configuration files are present.