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
Perform a full build to confirm no errors or warnings surface at compile time:

```bash
dotnet build --configuration Release
```

Address any warnings that could indicate runtime issues, such as nullable reference warnings or platform compatibility warnings.

### 4. Run the Test Suite
If the solution contains test projects, execute them to verify existing behavior has been preserved:

```bash
dotnet test --configuration Release
```

Review test output for any failures that may indicate behavioral differences between the legacy .NET Framework runtime and the new cross-platform .NET runtime.

### 5. Check for Platform-Specific API Usage
Use the .NET Compatibility Analyzer or review the build output for `CA1416` warnings, which indicate calls to APIs that are only available on specific operating systems (e.g., Windows-only APIs such as the Registry or certain `System.Drawing` types). If any are found, either guard them with `OperatingSystem.IsWindows()` checks or replace them with cross-platform alternatives.

### 6. Verify Configuration and App Settings
Confirm that any configuration files (e.g., `appsettings.json`) are correctly structured for the `Microsoft.Extensions.Configuration` model used in modern .NET, and that any legacy `App.config` or `Web.config` settings have been migrated appropriately.

### 7. Run the Application
Execute the application directly to confirm runtime behavior:

```bash
dotnet run --project ./AdoCore/AdoCore.csproj --configuration Release
```

Test all major code paths, particularly any that involve database access, file I/O, or network calls, as these areas can surface runtime differences not caught at compile time.

### 8. Test on Target Operating Systems
If cross-platform support is a goal, run the application on each intended operating system (Windows, Linux, macOS) to confirm there are no platform-specific runtime failures.

## Deployment

### 1. Publish a Self-Contained or Framework-Dependent Build
To produce deployable output, use the `dotnet publish` command. For a framework-dependent deployment:

```bash
dotnet publish --configuration Release --output ./publish
```

For a self-contained deployment targeting a specific runtime:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained true --output ./publish
```

### 2. Verify Published Output
Navigate to the output directory and confirm all expected binaries, configuration files, and assets are present before deploying to the target environment.