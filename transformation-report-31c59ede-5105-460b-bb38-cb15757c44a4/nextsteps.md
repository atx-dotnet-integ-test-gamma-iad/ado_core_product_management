# Next Steps

The solution appears to have transformed successfully — no build errors were detected across any of the projects in the solution.

## Validation Steps

### 1. Verify Target Framework
Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure no projects are still referencing `net48` or other Windows-only frameworks unless that is intentional.

### 2. Restore Dependencies
Run the following command from the solution root to confirm all NuGet packages resolve correctly:

```bash
dotnet restore
```

Resolve any warnings about deprecated or unlisted packages by updating them in the relevant `.csproj` files.

### 3. Build the Solution
Perform a full build to confirm there are no issues beyond what was captured in the initial error report:

```bash
dotnet build --configuration Release
```

Review any warnings that appear, as some may indicate runtime issues that do not surface as build errors.

### 4. Run the Test Suite
If the solution contains test projects, execute them to verify that existing behavior has been preserved:

```bash
dotnet test --configuration Release
```

Review any failing tests carefully, as failures may indicate behavioral differences between the legacy .NET Framework and the new cross-platform .NET runtime.

### 5. Check for Windows-Specific API Usage
Even without build errors, some APIs may compile successfully but fail at runtime on non-Windows platforms. Use the .NET Compatibility Analyzer to surface these issues:

```bash
dotnet add package Microsoft.DotNet.Analyzers.Compatibility
```

Alternatively, review the code manually for usage of APIs such as `System.Windows.Forms`, `Microsoft.Win32`, or P/Invoke calls that target Windows-only system libraries.

### 6. Run the Application
Execute the application directly and exercise its primary code paths:

```bash
dotnet run --project ./AdoCore/AdoCore.csproj --configuration Release
```

Confirm that runtime behavior matches expectations from the legacy version.

### 7. Review Configuration Files
Check that any `app.config` or `web.config` files have been appropriately migrated to `appsettings.json` or the `Microsoft.Extensions.Configuration` model, as the legacy configuration system behaves differently under cross-platform .NET.

### 8. Validate NuGet Package Compatibility
Review all referenced NuGet packages and confirm they support the target framework. Packages that target only `net45`, `net48`, or similar legacy monikers may produce unexpected behavior even if they restore and build without errors. The NuGet package page for each dependency will list supported frameworks.