# Next Steps

The solution appears to have transformed successfully — no build errors were detected across any of the projects in the solution.

## Validation Steps

### 1. Verify Target Framework
Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure no projects are still referencing `net48` or other legacy .NET Framework monikers unless that is intentional.

### 2. Restore Dependencies
Run the following command from the solution root to confirm all NuGet packages resolve correctly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or packages that do not support the target framework.

### 3. Build the Solution
Run a full build to confirm no errors or warnings are present:

```bash
dotnet build --configuration Release
```

Address any warnings that could indicate runtime issues, such as nullable reference warnings or platform compatibility warnings.

### 4. Run Existing Tests
If the solution contains test projects, execute them to verify existing behavior is preserved:

```bash
dotnet test --configuration Release
```

Review test output carefully. A passing build does not guarantee correct runtime behavior.

### 5. Check for Windows-Specific APIs
Even without build errors, the code may use APIs that are Windows-only and will fail at runtime on other platforms. Use the .NET Compatibility Analyzer to surface these:

```bash
dotnet add package Microsoft.DotNet.Analyzers.Compatibility
```

Review any `CA1416` platform compatibility warnings that appear after adding the analyzer.

### 6. Review Removed Configuration Files
Confirm that any `App.config` or `Web.config` files have been migrated to the appropriate .NET configuration system. Settings should now reside in `appsettings.json` or be handled via `Microsoft.Extensions.Configuration`.

### 7. Validate Runtime Behavior
Run the application on each target platform (Windows, Linux, macOS) if cross-platform support is a requirement. Pay particular attention to:

- File path separators (`/` vs `\`)
- Case-sensitive file system behavior on Linux
- Platform-specific environment variables

### 8. Review NuGet Package Versions
Check for outdated or deprecated packages that may have been carried over from the legacy project:

```bash
dotnet list package --outdated
```

Update packages where appropriate, verifying that updated versions do not introduce breaking changes.

### 9. Publish the Application
Once validation is complete, publish the application for the target runtime:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained false
```

Replace `linux-x64` with the appropriate runtime identifier (`win-x64`, `osx-x64`, etc.) as needed. Review the publish output directory to confirm all expected assets are present.