# Next Steps

## Build Status

The solution has no build errors following the transformation. All projects compiled successfully.

## Validation Steps

### 1. Review Target Framework
Open `AdoCore.csproj` and confirm the target framework is set to the intended cross-platform version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure this aligns with the .NET version installed on your machine. Run the following to confirm your SDK version:

```bash
dotnet --version
```

### 2. Restore Dependencies
Run a clean restore to ensure all NuGet packages resolve correctly under the new framework:

```bash
dotnet restore
```

Review the output for any dependency warnings, particularly packages that may have been resolved to older or incompatible versions.

### 3. Build the Solution
Perform a full build from the command line to confirm no errors exist outside of the IDE:

```bash
dotnet build --configuration Release
```

Address any warnings that appear, especially those related to nullable reference types, deprecated APIs, or platform compatibility.

### 4. Run Existing Tests
If the solution contains a test project, execute the test suite to verify runtime behavior has not changed:

```bash
dotnet test --configuration Release
```

Review any failing tests carefully, as they may indicate behavioral differences between the legacy .NET Framework and the new cross-platform .NET runtime.

### 5. Check for Platform-Specific API Usage
Even without build errors, certain APIs that compiled successfully may throw at runtime on non-Windows platforms. Review the code for usage of the following:

- `System.Windows.Forms` or `System.Drawing` (requires additional packages or Windows)
- `Microsoft.Win32` registry access
- `System.Security.Permissions` attributes
- COM interop or P/Invoke calls targeting Windows-only libraries

Use the [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the `Microsoft.DotNet.PlatformAbstractions` tooling to identify remaining compatibility concerns.

### 6. Run the Application
Execute the application directly and exercise its primary functionality:

```bash
dotnet run --project ado_core_product_management/AdoCore.csproj --configuration Release
```

Observe runtime behavior and compare it against the expected behavior from the legacy version.

### 7. Publish the Application
Once runtime behavior is validated, publish a self-contained or framework-dependent build as appropriate for your deployment target:

**Framework-dependent:**
```bash
dotnet publish ado_core_product_management/AdoCore.csproj --configuration Release --output ./publish
```

**Self-contained (example for Linux x64):**
```bash
dotnet publish ado_core_product_management/AdoCore.csproj --configuration Release --runtime linux-x64 --self-contained true --output ./publish
```

Review the contents of the `./publish` directory and verify all required assets and configuration files are present before deploying to the target environment.