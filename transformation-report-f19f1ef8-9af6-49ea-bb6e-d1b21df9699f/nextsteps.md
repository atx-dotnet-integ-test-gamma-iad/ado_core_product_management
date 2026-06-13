# Next Steps

The solution appears to have transformed successfully — no build errors were detected across any of the projects in the solution.

## Validation Steps

### 1. Verify Target Framework
Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure no projects still reference `net4x` or `netstandard` targets unless intentionally kept for compatibility.

### 2. Restore Dependencies
Run the following command from the solution root to confirm all NuGet packages resolve cleanly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or version conflicts.

### 3. Build the Solution
Perform a full build to confirm there are no warnings that may indicate subtle issues:

```bash
dotnet build --configuration Release
```

Address any warnings related to nullable reference types, obsolete APIs, or platform compatibility.

### 4. Run Existing Tests
If the solution contains test projects, execute them to verify runtime behavior has not changed:

```bash
dotnet test --configuration Release
```

Review test output carefully. A passing build does not guarantee correct runtime behavior, so all existing tests should pass before proceeding.

### 5. Check Platform-Specific API Usage
Use the .NET Upgrade Assistant compatibility analyzer or the `Microsoft.DotNet.PlatformAbstractions` tooling to identify any remaining Windows-specific API calls that may compile but fail at runtime on Linux or macOS:

```bash
dotnet add package Microsoft.Windows.Compatibility
```

Only add this package if Windows-specific APIs are genuinely required; otherwise, replace those APIs with cross-platform equivalents.

### 6. Validate Runtime Behavior
Run the application on each target platform (Windows, Linux, macOS) to confirm consistent behavior. Pay particular attention to:

- File path separators (`/` vs `\`)
- Environment variable access
- Registry access (Windows-only)
- Case sensitivity in file system operations

### 7. Review NuGet Package Versions
Check for any packages that were carried over from the legacy project and may have newer, cross-platform compatible versions available:

```bash
dotnet list package --outdated
```

Update packages where appropriate, then re-run the build and tests.

### 8. Inspect Output Artifacts
After a Release build, inspect the output directory to confirm the expected assemblies, configuration files, and dependencies are present:

```bash
dotnet publish --configuration Release --output ./publish
```

Verify the published output runs correctly on the target platform.