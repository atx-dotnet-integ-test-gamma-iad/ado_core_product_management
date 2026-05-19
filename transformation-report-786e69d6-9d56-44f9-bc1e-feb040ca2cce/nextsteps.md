# Next Steps

The solution appears to have transformed successfully — no build errors were detected across any of the projects in the solution.

## Validation Steps

### 1. Verify Target Framework
Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

### 2. Restore NuGet Packages
Run the following command from the solution root to ensure all dependencies are restored cleanly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated or unlisted packages and consider updating them.

### 3. Build the Solution
Perform a full build to confirm there are no errors:

```bash
dotnet build --configuration Release
```

### 4. Run the Test Suite
If the solution contains test projects, execute all tests to verify runtime behavior is consistent with the original project:

```bash
dotnet test --configuration Release
```

Review any failing tests carefully, as they may indicate behavioral differences introduced during the migration rather than pre-existing failures.

### 5. Check for Platform-Specific API Usage
Even without build errors, some APIs may have been silently replaced or may behave differently on non-Windows platforms. Use the .NET Compatibility Analyzer to surface any remaining platform-specific concerns:

```bash
dotnet add package Microsoft.DotNet.Analyzers.Compatibility
```

Run the build again after adding the analyzer and review any new warnings.

### 6. Validate Runtime Behavior
Run the application on each target platform (Windows, Linux, macOS as applicable) and verify that:

- Application startup completes without exceptions.
- Core workflows produce the same output as the legacy version.
- File paths, line endings, and culture-sensitive operations behave as expected across platforms.

### 7. Review Removed or Changed APIs
Check the [.NET Upgrade Assistant breaking changes documentation](https://learn.microsoft.com/en-us/dotnet/core/compatibility/) for the specific version you migrated to. Pay particular attention to areas such as:

- `System.Configuration` usage (replaced by `Microsoft.Extensions.Configuration`)
- Windows-only APIs such as the registry, WMI, or certain `System.Drawing` features
- Serialization behavior changes

### 8. Review Output Artifacts
Confirm that the build output directory contains the expected binaries and that the assembly versions are correct:

```bash
dotnet publish --configuration Release --output ./publish
```

Inspect the `./publish` directory to ensure all required files, including configuration files and native dependencies, are present.