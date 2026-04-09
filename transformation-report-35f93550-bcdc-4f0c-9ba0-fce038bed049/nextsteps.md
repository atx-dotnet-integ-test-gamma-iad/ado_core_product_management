# Next Steps

The solution appears to have transformed successfully — no build errors were detected across any of the projects in the solution.

## Validation Steps

### 1. Verify Target Framework
Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure no projects are still referencing `net48` or other legacy .NET Framework monikers unless that is intentional for multi-targeting.

### 2. Restore Dependencies
Run the following command from the solution root to confirm all NuGet packages resolve cleanly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or packages that do not support the target framework.

### 3. Build the Solution
Run a full build to confirm the absence of errors and review any warnings:

```bash
dotnet build --configuration Release
```

Address any warnings that could indicate runtime issues, such as nullable reference warnings or platform-compatibility warnings.

### 4. Run Existing Tests
If the solution contains test projects, execute them to verify that existing behavior is preserved:

```bash
dotnet test --configuration Release
```

Review test output carefully. A passing build does not guarantee correct runtime behavior.

### 5. Check for Removed or Changed APIs
Use the .NET Upgrade Assistant compatibility analyzer or review the [.NET API compatibility documentation](https://learn.microsoft.com/en-us/dotnet/core/compatibility/) to identify any APIs used in the project that behave differently or have been removed in the target .NET version. Pay particular attention to:

- `System.Web` usages (not available on cross-platform .NET)
- Windows-only APIs (e.g., registry access, WCF server-side, Windows Forms if targeting non-Windows)
- Reflection behavior changes

### 6. Run the Application
Execute the application directly and exercise its primary workflows:

```bash
dotnet run --project ./AdoCore/AdoCore.csproj --configuration Release
```

Verify that runtime behavior matches expectations from the original .NET Framework version.

### 7. Review Configuration Files
Confirm that any `app.config` or `web.config` files have been migrated appropriately to `appsettings.json` or other .NET configuration mechanisms. Legacy XML-based configuration is not fully supported in cross-platform .NET.

### 8. Validate Platform-Specific Behavior
If the application will run on Linux or macOS, test it on those platforms explicitly. File path separators, environment variable access, and certain cryptographic APIs can behave differently across operating systems.

## Deployment

### Publish a Self-Contained or Framework-Dependent Executable
To produce a deployable artifact, use the `dotnet publish` command:

**Framework-dependent (requires .NET runtime on target machine):**
```bash
dotnet publish --configuration Release --output ./publish
```

**Self-contained (bundles the runtime):**
```bash
dotnet publish --configuration Release --self-contained true --runtime linux-x64 --output ./publish
```

Replace `linux-x64` with the appropriate runtime identifier for your target environment (e.g., `win-x64`, `osx-x64`).

### Verify the Published Output
Navigate to the `./publish` directory and confirm the expected binaries and configuration files are present before deploying to the target environment.