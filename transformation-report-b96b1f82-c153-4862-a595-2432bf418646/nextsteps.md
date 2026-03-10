# Next Steps

The solution appears to have transformed successfully — no build errors were detected across any of the projects in the solution.

## Validation

### 1. Verify Target Framework
Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure this is consistent across all projects in the solution, particularly `AdoCore.csproj` and any projects that depend on it.

### 2. Restore NuGet Packages
Run the following command from the solution root to confirm all dependencies resolve cleanly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or version conflicts.

### 3. Build the Solution
Perform a full build to confirm there are no warnings that may indicate compatibility issues:

```bash
dotnet build --configuration Release
```

Address any warnings related to nullable reference types, obsolete APIs, or platform compatibility.

### 4. Run Existing Tests
If the solution contains test projects, execute them to verify runtime behavior has not changed:

```bash
dotnet test --configuration Release
```

Review test output carefully. A passing build does not guarantee correct runtime behavior.

### 5. Check for Platform-Specific APIs
Use the .NET Upgrade Assistant or the `Microsoft.DotNet.PlatformAbstractions` compatibility analyzer to identify any remaining Windows-specific API calls that may fail on Linux or macOS:

```bash
dotnet tool install -g dotnet-format
dotnet format --verify-no-changes
```

Additionally, consider running:

```bash
dotnet build /p:EnableNETAnalyzers=true
```

This will surface platform compatibility warnings via Roslyn analyzers.

### 6. Review `AdoCore.csproj` Dependencies
Since `AdoCore.csproj` appears to be the least independent project (a leaf dependency), verify that:

- All referenced NuGet packages have .NET-compatible versions available.
- No `<HintPath>` references point to old `.dll` files from the legacy project output.
- No `packages.config` file remains alongside the `.csproj`.

### 7. Smoke Test the Application
Run the application manually against a representative workload or dataset to confirm end-to-end behavior:

```bash
dotnet run --project ./AdoCore/AdoCore.csproj --configuration Release
```

Observe console output, log files, and any database or network interactions for unexpected errors.

## Deployment

### 1. Publish a Self-Contained or Framework-Dependent Build
Choose the appropriate publish mode based on your target environment:

**Framework-dependent:**
```bash
dotnet publish --configuration Release --output ./publish
```

**Self-contained (example for Linux x64):**
```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained true --output ./publish
```

### 2. Verify the Publish Output
Inspect the `./publish` directory to confirm all expected assemblies, configuration files, and static assets are present.

### 3. Test the Published Output
Run the published output directly to confirm it behaves identically to the development build:

```bash
./publish/AdoCore
```

Or on Windows:

```powershell
.\publish\AdoCore.exe
```

### 4. Review Configuration Files
Ensure `appsettings.json` (or equivalent configuration files) are correctly included in the publish output and contain environment-appropriate values. Sensitive values should be managed via environment variables or a secrets manager rather than being embedded in config files.