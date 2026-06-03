# Next Steps

The solution appears to have transformed successfully — no build errors were detected across any of the projects in the solution.

## Validation Steps

### 1. Verify Target Framework
Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure no projects are still referencing `net4x` or `netstandard` targets unintentionally.

### 2. Restore Dependencies
Run the following command from the solution root to confirm all NuGet packages resolve correctly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or version conflicts.

### 3. Build the Solution
Perform a full build to confirm there are no warnings that could indicate runtime issues:

```bash
dotnet build --configuration Release
```

Address any warnings related to nullable reference types, obsolete APIs, or platform compatibility.

### 4. Run Existing Tests
If the solution contains test projects, execute them to verify existing behavior is preserved:

```bash
dotnet test --configuration Release
```

Review test output for any failures or skipped tests that may indicate behavioral differences between the old and new target frameworks.

### 5. Check for Removed or Changed APIs
Use the .NET Upgrade Assistant compatibility analyzer or the `Microsoft.DotNet.ApiCompat` tool to identify any APIs that were available in the legacy framework but have been removed or altered in the new target:

```bash
dotnet tool install -g dotnet-apicompat
```

Pay particular attention to areas such as:
- `System.Web` usage (not available in cross-platform .NET)
- Windows-specific APIs (e.g., registry, WCF server-side, Windows Forms if targeting non-Windows)
- Reflection APIs that changed behavior

### 6. Review NuGet Package Compatibility
Open the NuGet package manager or inspect `.csproj` files to confirm all referenced packages have versions compatible with the new target framework. Replace any packages that have known cross-platform replacements, for example:
- `System.Web` → `Microsoft.AspNetCore.*`
- `Newtonsoft.Json` (still valid, but consider `System.Text.Json`)

### 7. Run the Application
Execute the application directly to perform a basic smoke test:

```bash
dotnet run --project ./AdoCore/AdoCore.csproj --configuration Release
```

Verify that the application starts and core functionality behaves as expected.

### 8. Test on Target Platforms
If cross-platform support is a goal, run the application on each intended operating system (Windows, Linux, macOS) to surface any platform-specific runtime issues that would not appear at build time.

### 9. Review Output Artifacts
Publish the project and inspect the output to confirm the correct runtime and dependencies are included:

```bash
dotnet publish --configuration Release --output ./publish
```

Check that no unintended platform-specific binaries are included and that the output is self-consistent.