# Next Steps

The solution appears to have transformed successfully — no build errors were detected across any of the projects in the solution.

## Validation

### 1. Verify Target Framework
Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure no projects are still referencing `net48` or other .NET Framework monikers unless a multi-targeting scenario is intentional.

### 2. Restore Dependencies
Run the following command from the solution root to confirm all NuGet packages resolve correctly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or packages that do not support the target framework.

### 3. Build the Solution
Perform a clean build to confirm there are no errors or warnings that may have been suppressed:

```bash
dotnet build --configuration Release
```

Address any warnings that could indicate runtime issues, such as nullable reference warnings or platform compatibility warnings.

### 4. Run the Test Suite
If the solution contains test projects, execute them to verify functional correctness after the transformation:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests and determine whether they are caused by behavioral differences between .NET Framework and cross-platform .NET (e.g., changes in globalization, reflection, or threading behavior).

### 5. Check for Platform-Specific API Usage
Use the .NET Compatibility Analyzer or review the code manually for APIs that are Windows-specific. These will typically produce analyzer warnings such as `CA1416`. If the application must run on non-Windows platforms, those code paths need to be replaced or guarded with runtime checks:

```csharp
if (OperatingSystem.IsWindows())
{
    // Windows-specific code
}
```

### 6. Review `App.config` / `Web.config` Usage
Cross-platform .NET does not use `App.config` or `Web.config` in the same way as .NET Framework. Confirm that any configuration previously handled by those files has been migrated to `appsettings.json` or another supported configuration provider.

### 7. Validate Runtime Behavior
Run the application in a development environment and exercise the primary workflows manually or through integration tests. Pay particular attention to:

- File path handling (use `Path.Combine` rather than hardcoded separators)
- Culture and encoding assumptions
- Reflection-based code that may behave differently under trimming or AOT scenarios

### 8. Test on Target Platforms
If cross-platform support is a goal, run the application on each intended operating system (Windows, Linux, macOS) to surface any remaining platform-specific issues.

## Deployment

### 1. Publish the Application
Use the `dotnet publish` command to produce the deployment artifacts:

```bash
dotnet publish --configuration Release --output ./publish
```

For a self-contained deployment that does not require the .NET runtime to be installed on the target machine:

```bash
dotnet publish --configuration Release --self-contained true --runtime linux-x64 --output ./publish
```

Replace `linux-x64` with the appropriate runtime identifier for your target environment (e.g., `win-x64`, `osx-x64`).

### 2. Verify Published Output
Inspect the `./publish` directory to confirm all expected assemblies, configuration files, and static assets are present.

### 3. Smoke Test the Published Artifact
Run the published output directly on the target machine or environment before wider deployment to confirm it operates correctly outside of the development toolchain:

```bash
./publish/AdoCore
```

or on Windows:

```bash
.\publish\AdoCore.exe
```