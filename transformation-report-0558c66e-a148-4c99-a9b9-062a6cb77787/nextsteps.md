# Next Steps

The solution appears to have transformed successfully — no build errors were detected across any of the projects in the solution.

## Validation Steps

### 1. Verify Target Framework
Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure no projects are still referencing `net48` or other legacy .NET Framework monikers unless a multi-targeting scenario is intentional.

### 2. Restore and Build Locally
Run the following commands from the solution root to confirm a clean restore and build:

```bash
dotnet restore
dotnet build --configuration Release
```

Review the output for any warnings that may indicate deprecated APIs or packages that could cause runtime issues.

### 3. Run Existing Tests
If the solution contains test projects, execute them to verify runtime behavior has not regressed:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Address any failing tests before proceeding.

### 4. Check for Removed or Changed APIs
Use the .NET Upgrade Assistant compatibility analyzer or the `Microsoft.DotNet.ApiCompat` tooling to identify any API usage that was available in .NET Framework but has been removed or altered in cross-platform .NET:

```bash
dotnet tool install -g dotnet-apicompat
```

Pay particular attention to:
- `System.Web` dependencies (not available in cross-platform .NET)
- Windows-specific APIs (e.g., registry access, WCF server-side, certain cryptography APIs)
- Any third-party NuGet packages that may not have cross-platform compatible versions

### 5. Review NuGet Package Versions
Open each `.csproj` file and verify that all `<PackageReference>` entries reference current, cross-platform compatible versions. You can check for outdated packages with:

```bash
dotnet list package --outdated
```

Update packages where appropriate, then re-run the build and tests.

### 6. Validate Runtime Behavior on Target Platforms
If the goal is to run on non-Windows platforms (Linux, macOS), test the application explicitly on those platforms or using a compatible runtime environment. File path separators, line endings, and platform-specific behaviors can surface issues that do not appear at compile time.

### 7. Review Output Artifacts
Confirm that the compiled output is placed in the expected directories and that all necessary assets (configuration files, static resources, etc.) are copied correctly:

```bash
dotnet publish --configuration Release --output ./publish
```

Inspect the `./publish` folder to ensure all required files are present.

## Deployment

Once validation is complete:

1. Use `dotnet publish` with the appropriate runtime identifier if a self-contained deployment is needed:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained true
```

2. For a framework-dependent deployment (requires .NET runtime installed on the target machine):

```bash
dotnet publish --configuration Release --self-contained false
```

3. Copy the published output to the target environment and execute the entry point assembly:

```bash
dotnet AdoCore.dll
```

Replace `AdoCore.dll` with the actual entry point assembly name if it differs.