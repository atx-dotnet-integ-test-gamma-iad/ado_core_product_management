# Next Steps

The solution appears to have transformed successfully — no build errors were detected across any of the projects in the solution.

## Validation Steps

### 1. Verify Target Framework
Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure no projects are still referencing `net48` or any other legacy .NET Framework moniker unless a multi-targeting scenario is intentional.

### 2. Restore and Build Locally
Run the following commands from the solution root to confirm a clean restore and build:

```bash
dotnet restore
dotnet build --configuration Release
```

Review the output for any warnings that may indicate deprecated APIs or compatibility concerns, even if they do not block the build.

### 3. Run Existing Tests
If the solution contains test projects, execute them to verify runtime behavior has not changed:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Address any test failures by reviewing logic that may depend on platform-specific behavior, such as file path separators, encoding defaults, or Windows-only APIs.

### 4. Check for Platform-Specific API Usage
Use the .NET Upgrade Assistant or the `Microsoft.DotNet.PlatformAbstractions` compatibility analyzer to identify any remaining calls to Windows-only APIs (e.g., registry access, `System.Drawing`, COM interop). These will build successfully on Windows but will throw `PlatformNotSupportedException` at runtime on Linux or macOS.

```bash
dotnet add package Microsoft.Windows.Compatibility
```

Only add this package if Windows-only APIs are required and cross-platform support for those specific features is not needed.

### 5. Review NuGet Package Compatibility
Open the `.csproj` files and review all `<PackageReference>` entries. Confirm each package supports the target framework by checking [nuget.org](https://www.nuget.org). Packages that only support `net4x` may have been included via compatibility shims and could behave unexpectedly at runtime.

### 6. Validate Configuration and File Paths
Review any hardcoded file paths, connection strings, or configuration values in `appsettings.json` or `App.config`. Ensure paths use `Path.Combine` or forward-slash-compatible formats rather than hardcoded backslashes.

### 7. Smoke Test on Target Platform
If the intended deployment platform is Linux or macOS, run the application on that platform directly:

```bash
dotnet run --configuration Release
```

Observe runtime behavior and check application logs for exceptions that would not surface during a Windows build.

### 8. Publish a Self-Contained Build
Produce a release build targeting the intended runtime to confirm the published output is complete:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained true
```

Replace `linux-x64` with the appropriate runtime identifier (`win-x64`, `osx-x64`, etc.) as needed.