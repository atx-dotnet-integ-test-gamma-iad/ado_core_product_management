# Next Steps

The solution appears to have transformed successfully — no build errors were detected across any of the projects in the solution.

## Validation Steps

### 1. Verify Target Framework
Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure no projects are still referencing `net48`, `netstandard2.0`, or other legacy monikers unless intentionally kept for compatibility.

### 2. Restore Dependencies
Run the following command from the solution root to confirm all NuGet packages resolve cleanly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or unresolved references.

### 3. Build the Solution
Perform a full build to confirm no errors or warnings are introduced at compile time:

```bash
dotnet build --configuration Release
```

Address any warnings that could indicate runtime issues, such as nullable reference warnings or obsolete API usage.

### 4. Run the Test Suite
If the solution contains test projects, execute them to verify functional correctness after the migration:

```bash
dotnet test --configuration Release
```

Review test output for any failures that may indicate behavioral differences between the legacy .NET Framework runtime and the new cross-platform .NET runtime.

### 5. Check for Platform-Specific API Usage
Review the code for any APIs that were available in .NET Framework but are absent or behave differently in cross-platform .NET. Common areas to check include:

- `System.Web` usage (not available in cross-platform .NET)
- Windows Registry access (`Microsoft.Win32.Registry`)
- `AppDomain` usage
- WCF server-side components
- `BinaryFormatter` (deprecated and disabled by default)

Use the [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the `Microsoft.DotNet.PlatformAbstractions` tooling to surface remaining compatibility issues.

### 6. Run the Application
Execute the application directly to confirm it starts and operates correctly under the new runtime:

```bash
dotnet run --project ./AdoCore/AdoCore.csproj --configuration Release
```

Test the primary workflows of the application manually to catch any runtime-only issues not surfaced by the build or test suite.

### 7. Review Output Artifacts
Confirm the build output is placed in the expected directory and that all required assets, configuration files, and dependencies are present:

```bash
dotnet publish --configuration Release --output ./publish
```

Inspect the `./publish` directory to verify the output is complete and self-contained if a self-contained deployment is required.