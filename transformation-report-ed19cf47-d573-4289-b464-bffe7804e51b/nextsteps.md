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
Perform a full build to confirm the absence of errors in a clean environment:

```bash
dotnet build --configuration Release
```

Review any warnings that surface, as some may indicate compatibility concerns that did not produce hard errors.

### 4. Run the Test Suite
If the solution contains test projects, execute them to verify runtime behavior has not regressed:

```bash
dotnet test --configuration Release
```

Review test output carefully, paying attention to any tests that were previously passing under the legacy framework.

### 5. Check for Windows-Specific API Usage
Even when a project compiles cleanly, it may contain calls to Windows-specific APIs (e.g., the registry, certain `System.Drawing` members, WinForms, or WPF). Use the .NET Compatibility Analyzer to surface these:

```bash
dotnet add package Microsoft.DotNet.Analyzers.Compatibility
```

Alternatively, review analyzer warnings produced during the build step above under the `CA1416` rule (platform compatibility).

### 6. Validate Runtime Behavior on Target Platforms
Run the application on each platform you intend to support (Windows, Linux, macOS) and confirm that core functionality behaves as expected. Pay particular attention to:

- File path handling (`Path.Combine` vs. hardcoded separators)
- Line ending differences
- Case sensitivity on Linux file systems
- Culture and encoding assumptions

### 7. Review NuGet Package Compatibility
Check that all third-party NuGet packages in use have versions that support your target framework. The following command lists outdated packages:

```bash
dotnet list package --outdated
```

Update any packages that have newer versions with cross-platform support.

### 8. Inspect Output Artifacts
After a successful Release build, inspect the output directory to confirm the expected assemblies, configuration files, and other assets are present:

```bash
dotnet publish --configuration Release --output ./publish
```

Verify the published output runs correctly on a clean machine without the SDK installed, using only the .NET runtime.