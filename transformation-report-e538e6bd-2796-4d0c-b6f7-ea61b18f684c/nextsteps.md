# Next Steps

The solution appears to have transformed successfully — no build errors were detected across any of the projects in the solution.

## Validation Steps

### 1. Verify Target Framework
Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure no projects are still referencing `net48` or any other .NET Framework moniker unless that is intentional.

### 2. Restore Dependencies
Run the following command from the solution root to confirm all NuGet packages resolve cleanly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or packages that do not support the target framework.

### 3. Build the Solution
Run a full solution build to confirm the error-free state holds in a clean environment:

```bash
dotnet build --configuration Release
```

Review any warnings that surface, as some warnings may indicate runtime issues even if the build succeeds.

### 4. Run Existing Tests
If the solution contains test projects, execute them to verify runtime behavior has not regressed:

```bash
dotnet test --configuration Release
```

Review test output carefully. A passing build does not guarantee correct runtime behavior after a framework migration.

### 5. Check for Windows-Specific APIs
Even with a successful build, some APIs that compiled against .NET Framework may not behave identically on non-Windows platforms. Use the .NET Compatibility Analyzer to surface these:

```bash
dotnet add package Microsoft.DotNet.Analyzers.Compatibility
```

Alternatively, review the build output for `CA1416` platform compatibility warnings, which are emitted by the built-in platform compatibility analyzer in .NET 5+.

### 6. Review `App.config` / `Web.config` Usage
.NET does not use `App.config` or `Web.config` in the same way as .NET Framework. If the project relied on these files for configuration, migrate the relevant settings to `appsettings.json` and use `Microsoft.Extensions.Configuration` to read them.

### 7. Validate Runtime Behavior
Run the application in a representative environment and exercise the primary workflows. Pay particular attention to:

- File I/O paths (path separators differ between Windows and Linux/macOS)
- Registry access (not available on non-Windows platforms)
- `System.Drawing` usage (requires `libgdiplus` on Linux or migration to an alternative library)
- Reflection-based code that may be affected by trimming or assembly loading differences

### 8. Review Removed APIs
Cross-reference the project's dependencies against the [.NET Upgrade Assistant API analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the [.NET API compatibility documentation](https://learn.microsoft.com/en-us/dotnet/core/compatibility/) to identify any APIs that were removed or changed in behavior between .NET Framework and modern .NET.

## Deployment

### Publish the Application
Once validation is complete, publish the application using:

```bash
dotnet publish --configuration Release --output ./publish
```

For a self-contained deployment that does not require the .NET runtime to be installed on the target machine:

```bash
dotnet publish --configuration Release --runtime win-x64 --self-contained true --output ./publish
```

Replace `win-x64` with the appropriate runtime identifier for your target platform (e.g., `linux-x64`, `osx-x64`).

### Verify the Published Output
Before deploying to a production environment, run the published output on a staging machine that mirrors the production environment to confirm there are no missing runtime dependencies or configuration issues.