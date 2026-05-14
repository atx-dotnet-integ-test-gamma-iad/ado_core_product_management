# Next Steps

The solution appears to have transformed successfully — no build errors were detected across any of the projects in the solution.

## Validation Steps

### 1. Verify Target Framework
Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure no projects still reference `net48`, `netcoreapp*`, or other legacy monikers unless intentional.

### 2. Restore Dependencies
Run the following command from the solution root to confirm all NuGet packages resolve correctly:

```bash
dotnet restore
```

Resolve any warnings about deprecated or unlisted packages by updating them in the relevant `.csproj` files.

### 3. Build the Solution
Perform a clean build to confirm there are no errors or warnings that may have been missed:

```bash
dotnet build --configuration Release
```

Review any warnings in the output, particularly those related to nullable reference types, obsolete APIs, or platform compatibility.

### 4. Run the Test Suite
If the solution contains test projects, execute them to verify runtime behavior has not regressed:

```bash
dotnet test --configuration Release
```

Review test output carefully. A successful build does not guarantee correct runtime behavior.

### 5. Check for Platform-Specific API Usage
Use the .NET Upgrade Assistant or the `Microsoft.DotNet.PlatformAbstractions` compatibility analyzer to identify any remaining Windows-specific APIs that may compile successfully but fail at runtime on Linux or macOS. You can also enable the platform compatibility analyzer by adding the following to your `.csproj`:

```xml
<PropertyGroup>
  <EnableNETAnalyzers>true</EnableNETAnalyzers>
  <AnalysisMode>All</AnalysisMode>
</PropertyGroup>
```

### 6. Run the Application
Execute the application directly to confirm it starts and operates as expected:

```bash
dotnet run --project ./AdoCore/AdoCore.csproj --configuration Release
```

Test all major code paths, particularly any that involve database access, file I/O, or network communication, as these areas are most commonly affected by cross-platform migration.

### 7. Review `app.config` / `web.config` Migrations
If the original project used `app.config` or `web.config`, confirm that settings have been correctly migrated to `appsettings.json` or environment-based configuration, and that the application reads them correctly at runtime.

### 8. Verify Output Artifacts
Check the contents of the `bin/Release` output folder to confirm the expected assemblies, configuration files, and dependencies are present:

```bash
dotnet publish --configuration Release --output ./publish
```

Review the publish output to ensure no required files are missing.