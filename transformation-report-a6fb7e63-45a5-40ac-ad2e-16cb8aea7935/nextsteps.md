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
Run the following command from the solution root to confirm all NuGet packages resolve cleanly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or unresolved dependencies.

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

Review test output for any failures that may indicate behavioral differences introduced by the migration.

### 5. Check for Windows-Specific APIs
Use the .NET Upgrade Assistant compatibility analyzer or the `Microsoft.DotNet.PlatformAbstractions` tooling to scan for any remaining Windows-specific API calls that would break on Linux or macOS:

```bash
dotnet add package Microsoft.Windows.Compatibility
```

Alternatively, review the code manually for usages of APIs such as `Registry`, `System.Drawing` (GDI+), or COM interop that are not cross-platform.

### 6. Verify Runtime Behavior
Run the application on each target platform (Windows, Linux, macOS) to confirm consistent behavior. Pay particular attention to:

- File path separators (`\` vs `/`)
- Case sensitivity in file system operations
- Environment variable names and values
- Culture and locale-dependent formatting

### 7. Review NuGet Package Compatibility
Check that all third-party NuGet packages support the target .NET version. Visit [nuget.org](https://www.nuget.org) or use the following command to list outdated packages:

```bash
dotnet list package --outdated
```

Update any packages that have newer versions with cross-platform support.

### 8. Publish the Application
Once validation is complete, publish the application for the desired runtime target:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained true
```

Replace `linux-x64` with the appropriate runtime identifier (`win-x64`, `osx-x64`, etc.) as needed. Review the published output to confirm all required files are present.