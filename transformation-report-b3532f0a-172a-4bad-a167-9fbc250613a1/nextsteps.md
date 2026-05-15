# Next Steps

The solution appears to have transformed successfully — no build errors were detected across any of the projects in the solution.

## Validation Steps

### 1. Verify Target Framework
Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure no projects still reference `net4x` or `netstandard` targets unless explicitly required.

### 2. Restore Dependencies
Run a full NuGet restore to confirm all packages resolve correctly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or unresolved references.

### 3. Build the Solution
Perform a clean build to confirm there are no warnings that could indicate latent issues:

```bash
dotnet build --configuration Release
```

Address any warnings related to nullable reference types, obsolete APIs, or platform compatibility.

### 4. Run Existing Tests
If the solution contains test projects, execute the full test suite:

```bash
dotnet test --configuration Release
```

Review test results and investigate any failures, as they may indicate behavioral differences introduced during the migration.

### 5. Check for Platform-Specific APIs
Use the .NET Upgrade Assistant compatibility analyzer or the `Microsoft.DotNet.PlatformAbstractions` tooling to scan for any remaining Windows-specific API calls that may compile successfully but fail at runtime on non-Windows platforms:

```bash
dotnet add package Microsoft.Windows.Compatibility
```

Alternatively, review the code manually for usages of APIs such as `Registry`, `WinForms`, or `WPF` components if cross-platform runtime support is required.

### 6. Validate Runtime Behavior
Run the application on each target platform (Windows, Linux, macOS) to confirm runtime behavior is consistent. Pay particular attention to:

- File path separators (`/` vs `\`)
- Case sensitivity in file system operations
- Environment variable differences across platforms

### 7. Review NuGet Package Compatibility
Check that all referenced NuGet packages support the target framework. Packages that only support `net4x` or older `netstandard` versions may cause runtime issues even if they compile without errors:

```bash
dotnet list package --outdated
```

Update any outdated packages where a compatible version is available.

### 8. Deployment
Once validation is complete, publish the application for the desired target runtime:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained true
```

Replace `linux-x64` with the appropriate runtime identifier (`win-x64`, `osx-x64`, etc.) as needed. Review the contents of the publish output directory to confirm all required assets are present before deploying.