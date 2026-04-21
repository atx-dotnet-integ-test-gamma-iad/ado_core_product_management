# Next Steps

The solution appears to have transformed successfully — no build errors were detected across any of the projects in the solution.

## Validation Steps

### 1. Verify Target Framework
Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure no projects are still referencing `net48` or other Windows-only frameworks unless that is intentional.

### 2. Restore Dependencies
Run the following command from the solution root to confirm all NuGet packages resolve correctly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or packages that do not support the target framework.

### 3. Build the Solution
Perform a full build to confirm there are no errors or warnings that were not captured previously:

```bash
dotnet build --configuration Release
```

Address any warnings that could indicate runtime issues, such as nullable reference warnings or platform compatibility warnings.

### 4. Run Existing Tests
If the solution contains test projects, execute the test suite to verify that existing behavior has been preserved:

```bash
dotnet test --configuration Release
```

Review any failing tests and determine whether they are caused by behavioral differences between the legacy .NET Framework and the new cross-platform .NET runtime.

### 5. Check for Windows-Specific API Usage
Use the .NET Compatibility Analyzer or review the code manually for APIs that are Windows-only. These will typically be marked with a `[SupportedOSPlatform("windows")]` attribute or will throw `PlatformNotSupportedException` on non-Windows systems. Common areas to check include:

- Registry access (`Microsoft.Win32.Registry`)
- Windows Communication Foundation (WCF) server-side APIs
- `System.Drawing` (GDI+)
- Windows Event Log

### 6. Run the Application on the Target Platform
Execute the application on the intended target operating system (Linux, macOS, or Windows) and verify that all core functionality works as expected:

```bash
dotnet run --project ./AdoCore/AdoCore.csproj --configuration Release
```

### 7. Publish a Self-Contained or Framework-Dependent Build
Once validation is complete, publish the application for the target runtime:

**Framework-dependent:**
```bash
dotnet publish --configuration Release --output ./publish
```

**Self-contained (example for Linux x64):**
```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained true --output ./publish
```

Review the contents of the `./publish` directory and confirm all required files are present before deploying to the target environment.