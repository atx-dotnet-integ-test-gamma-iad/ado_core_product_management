# Next Steps

The solution appears to have transformed successfully — no build errors were detected across any of the projects in the solution.

## Validation Steps

### 1. Verify Target Framework
Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure no projects are still referencing `net48` or other Windows-only framework monikers unless that is intentional.

### 2. Restore Dependencies
Run the following command from the solution root to confirm all NuGet packages resolve correctly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or packages that do not support the target framework.

### 3. Build the Solution
Perform a clean build to confirm there are no errors or warnings that may have been masked:

```bash
dotnet build --configuration Release
```

Address any warnings that appear, particularly those related to nullable reference types, obsolete APIs, or platform compatibility.

### 4. Run the Test Suite
If the solution contains test projects, execute all tests to verify runtime behavior has not changed:

```bash
dotnet test --configuration Release
```

Review test output carefully. A passing build does not guarantee correct runtime behavior, so all existing tests should pass before proceeding.

### 5. Check for Windows-Specific API Usage
Use the .NET Compatibility Analyzer or the `Microsoft.DotNet.PlatformCompat.Analyzer` NuGet package to identify any remaining calls to Windows-only APIs. This is especially relevant if the project previously targeted .NET Framework and used APIs such as the Windows Registry, `System.Windows.Forms`, or `System.Drawing`.

Run a quick scan with:

```bash
dotnet build /p:EnableNETAnalyzers=true
```

Review any `CA1416` (platform compatibility) warnings in the output.

### 6. Verify Runtime Behavior on Target Platforms
Run or deploy the application on each platform you intend to support (e.g., Windows, Linux, macOS) and confirm the application starts and behaves as expected. Pay particular attention to:

- File path separators (`/` vs `\`)
- Case sensitivity in file system operations
- Environment variable names and availability
- Any configuration files that may reference platform-specific paths

### 7. Review NuGet Package Compatibility
Check that all third-party NuGet packages in use have versions that support the target .NET version. Visit [nuget.org](https://www.nuget.org) for each package and confirm `.NET 6`, `.NET 7`, or `.NET 8` (whichever applies) is listed under supported frameworks.

### 8. Update `app.config` / `appsettings.json`
If the project previously used `app.config` or `web.config`, confirm that configuration has been migrated to `appsettings.json` and that `Microsoft.Extensions.Configuration` is being used where appropriate.

### 9. Publish the Application
Once validation is complete, publish the application for the target runtime:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained false
```

Replace `linux-x64` with the appropriate runtime identifier (`win-x64`, `osx-x64`, etc.) as needed. Review the publish output directory to confirm all required files are present.