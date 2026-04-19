# Next Steps

The transformation appears to have completed successfully. There are no build errors present in the solution. Below are steps to validate, test, and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the target framework moniker (TFM) is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure this aligns with the .NET version installed on your machine by running:

```bash
dotnet --list-sdks
```

## 2. Restore Dependencies

Run a NuGet restore to confirm all packages resolve correctly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or packages that do not support the target framework. If any packages are flagged, check NuGet.org for updated versions and replace them in the `.csproj` file.

## 3. Build the Solution

Perform a clean build to confirm there are no compilation issues:

```bash
dotnet clean
dotnet build --configuration Release
```

Review the build output for any warnings, particularly those related to nullable reference types, obsolete APIs, or platform compatibility.

## 4. Run Existing Tests

If the solution contains test projects, execute them to verify that existing functionality is preserved:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests and determine whether they are caused by behavioral differences between the legacy .NET Framework and the new cross-platform .NET runtime.

## 5. Check for Platform-Specific API Usage

Use the .NET Compatibility Analyzer or the `dotnet-compatibility` tool to identify any APIs that may not behave identically across platforms (Windows, Linux, macOS):

```bash
dotnet add package Microsoft.DotNet.ApiCompat
```

Pay particular attention to areas such as:
- `System.Drawing` (requires additional native dependencies on non-Windows platforms)
- Registry access (`Microsoft.Win32.Registry`)
- Windows-specific security or identity APIs

## 6. Test on Target Platforms

If cross-platform support is a goal, run the application on each intended operating system to surface any runtime issues that do not appear at compile time.

## 7. Publish the Application

Once validation is complete, publish the application using the appropriate runtime identifier (RID):

```bash
dotnet publish --configuration Release --runtime win-x64 --self-contained true
```

Replace `win-x64` with the appropriate RID for your target environment (e.g., `linux-x64`, `osx-x64`). Use `--self-contained false` if you prefer a framework-dependent deployment and can guarantee the runtime is installed on the target machine.

## 8. Review Output Artifacts

After publishing, inspect the output directory (typically `bin/Release/net8.0/<rid>/publish/`) to confirm all required files, configuration files, and assets are present before deploying to the target environment.