# Next Steps

The solution appears to have transformed successfully — no build errors were detected across any of the projects in the solution.

## Validation Steps

### 1. Verify Target Framework
Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended cross-platform .NET version, for example:

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
Run a full solution build to confirm the error-free state is consistent across all configurations:

```bash
dotnet build --configuration Release
```

Check the output for any warnings that may indicate runtime issues even if the build succeeds.

### 4. Run the Test Suite
If the solution contains test projects, execute them to verify behavioral correctness after the transformation:

```bash
dotnet test --configuration Release
```

Review any failing tests carefully, as failures may indicate runtime behavioral differences between .NET Framework and cross-platform .NET (e.g., differences in globalization, file path handling, or reflection behavior).

### 5. Check for Platform-Specific API Usage
Use the .NET Upgrade Assistant compatibility analyzer or the `Microsoft.DotNet.PlatformAbstractions` tooling to scan for any APIs that are present but throw `PlatformNotSupportedException` at runtime on non-Windows platforms:

```bash
dotnet tool install -g dotnet-platform-compat
```

Pay particular attention to areas such as:
- `System.Drawing` (requires `libgdiplus` on Linux/macOS or replacement with a supported library)
- Windows Registry access (`Microsoft.Win32.Registry`)
- Windows-specific interop or COM calls

### 6. Run the Application
Execute the application directly to observe runtime behavior:

```bash
dotnet run --project AdoCore --configuration Release
```

Test all major code paths, particularly those that interact with external systems, the file system, or the network, as these areas are most likely to surface cross-platform differences.

### 7. Review Nullable Reference Type Warnings
If nullable reference types are enabled in the migrated projects, review any compiler warnings (`CS8600`–`CS8625` range) that surfaced during the build. These are not errors by default but can indicate potential null dereference issues at runtime.

### 8. Deployment
Once validation is complete, publish the application for the target runtime:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained false
```

Replace `linux-x64` with the appropriate runtime identifier for your target environment (e.g., `win-x64`, `osx-x64`, `linux-arm64`). Review the contents of the `publish` output folder before deploying to the target machine.