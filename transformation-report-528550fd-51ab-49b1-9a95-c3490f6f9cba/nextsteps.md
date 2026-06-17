# Next Steps

The solution appears to have transformed successfully — no build errors were detected across any of the projects in the solution.

## Validation Steps

### 1. Verify Target Framework
Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure no projects are still referencing `net48` or any other legacy .NET Framework moniker unless that is intentional.

### 2. Restore Dependencies
Run the following command from the solution root to confirm all NuGet packages resolve correctly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or packages that do not support the target framework.

### 3. Build the Solution
Perform a full build to confirm there are no errors or warnings that may have been missed:

```bash
dotnet build --configuration Release
```

Address any warnings that surface, particularly those related to nullable reference types or obsolete APIs, as these can indicate latent issues.

### 4. Run Existing Tests
If the solution contains test projects, execute them to verify that existing behavior has been preserved:

```bash
dotnet test --configuration Release
```

Review any failing tests carefully, as failures after a migration often point to behavioral differences between .NET Framework and modern .NET (e.g., changes in `HttpClient`, serialization, threading, or globalization).

### 5. Check for Removed or Changed APIs
Review the code for any usage of APIs that were removed or had behavior changes in modern .NET. The [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the `Microsoft.DotNet.PlatformAbstractions` compatibility tools can assist with this.

Common areas to check:
- `System.Web` references (not available in modern .NET)
- `BinaryFormatter` usage (disabled by default in .NET 5+)
- `AppDomain` APIs with limited support
- Windows-specific APIs if cross-platform support is required

### 6. Validate Runtime Behavior
Run the application and exercise its primary workflows manually or through integration tests. Pay particular attention to:
- Configuration loading (e.g., `app.config` vs `appsettings.json`)
- Logging behavior
- File path handling, especially if the application is expected to run on Linux or macOS

### 7. Review Output Artifacts
Confirm the build output is placed in the expected location and that all required assets (configuration files, static resources, etc.) are copied correctly:

```bash
dotnet publish --configuration Release --output ./publish
```

Inspect the `./publish` directory to ensure all necessary files are present before deploying.

## Deployment

Once validation is complete:

1. Ensure the target machine has the appropriate .NET runtime installed. You can verify the required runtime version from the `<TargetFramework>` in the `.csproj` file and download it from [https://dotnet.microsoft.com/download](https://dotnet.microsoft.com/download).
2. Copy the published output to the target environment.
3. Run the application using:

```bash
dotnet AdoCore.dll
```

Or, if published as a self-contained executable, run the generated binary directly without requiring a separate runtime installation.