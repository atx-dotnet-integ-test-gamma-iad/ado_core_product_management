# Next Steps

The solution appears to have transformed successfully — no build errors were detected across any of the projects in the solution.

## Validation Steps

### 1. Verify Target Framework
Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

### 2. Restore NuGet Packages
Run the following command from the solution root to ensure all dependencies resolve correctly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated or unlisted packages.

### 3. Build the Solution
Perform a full build to confirm no errors exist in the transformed state:

```bash
dotnet build --configuration Release
```

Address any warnings that surface, particularly those related to nullable reference types or obsolete API usage, as these can indicate latent issues.

### 4. Run Existing Tests
If the solution contains test projects, execute them to verify runtime behavior has not regressed:

```bash
dotnet test --configuration Release --logger trx
```

Review the `.trx` output files for any failed or skipped tests and investigate accordingly.

### 5. Verify Platform-Specific Code
Search the codebase for any remaining platform-specific APIs that may compile successfully but fail at runtime on non-Windows platforms. Common areas to check include:

- `System.Windows.Forms` or `System.Drawing` usage
- `Microsoft.Win32` registry access
- P/Invoke calls to Windows-only native libraries
- File path separators hardcoded as `\`

Use the [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the `Microsoft.DotNet.PlatformAbstractions` package to identify these if needed.

### 6. Run on Target Platforms
Execute the application on each platform you intend to support (e.g., Linux, macOS, Windows) to catch any runtime-only issues:

```bash
dotnet run --configuration Release
```

### 7. Review Output Artifacts
Confirm the build output is producing the expected artifact type (executable, library, etc.) by inspecting the `bin/Release` directory and verifying the output matches the intended deployment format.

### 8. Publish a Release Build
Once validation passes, produce a published output to confirm the publish pipeline works correctly:

```bash
dotnet publish --configuration Release --output ./publish
```

Review the contents of the `./publish` directory to ensure all required files and dependencies are present.