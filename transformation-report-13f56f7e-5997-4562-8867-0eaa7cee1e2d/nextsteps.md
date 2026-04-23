# Next Steps

The solution appears to have transformed successfully — no build errors were detected across any of the projects in the solution.

## Validation Steps

### 1. Verify Target Framework
Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure this is consistent across all projects in the solution, particularly `AdoCore.csproj` and any projects that depend on it.

### 2. Restore NuGet Packages
Run the following command from the solution root to confirm all dependencies resolve correctly:

```bash
dotnet restore
```

Resolve any warnings about deprecated or unlisted packages by updating to actively maintained equivalents.

### 3. Build the Solution
Perform a full solution build to confirm no errors surface outside of the IDE:

```bash
dotnet build --configuration Release
```

Review any warnings produced during the build, as some may indicate API usage that is obsolete or behaves differently on cross-platform .NET compared to .NET Framework.

### 4. Run Existing Tests
If the solution contains test projects, execute them to verify runtime behavior has not changed:

```bash
dotnet test --configuration Release
```

Pay close attention to any tests that exercise platform-specific functionality such as file paths, registry access, Windows-specific APIs, or COM interop, as these are common sources of cross-platform failures that do not surface as build errors.

### 5. Check for Platform-Specific API Usage
Use the .NET Upgrade Assistant compatibility analyzer or the `Microsoft.DotNet.PlatformAbstractions` tooling to identify any APIs that are present in .NET but throw `PlatformNotSupportedException` at runtime on non-Windows platforms:

```bash
dotnet tool install -g dotnet-compatibility
```

Review the output and replace or conditionally compile any incompatible API calls.

### 6. Review `app.config` / `web.config` Migrations
If the original project used `app.config` or `web.config`, confirm that settings have been migrated to `appsettings.json` or the appropriate .NET configuration provider. Configuration sections from `System.Configuration` are not fully supported in cross-platform .NET without the `System.Configuration.ConfigurationManager` NuGet package.

### 7. Validate Output Artifacts
After a successful Release build, inspect the output directory:

```bash
dotnet publish --configuration Release --output ./publish
```

Confirm that all expected assemblies, resources, and dependencies are present in the publish output.

### 8. Manual Smoke Testing
Run the application manually against representative inputs or workflows to confirm end-to-end behavior matches the original .NET Framework version. Focus on areas that interact with the file system, networking, serialization, or any third-party libraries that may have had breaking changes between versions.