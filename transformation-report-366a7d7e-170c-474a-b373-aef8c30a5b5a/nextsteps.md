# Next Steps

The solution has no build errors following the transformation. The steps below cover validation, testing, and deployment of the migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the target framework moniker (TFM) is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

If multiple targets are required, use `<TargetFrameworks>` (plural) with a semicolon-separated list.

## 2. Restore Dependencies

Run the following command from the solution root to ensure all NuGet packages resolve correctly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or packages that do not support the target framework.

## 3. Build the Solution

Perform a full build to confirm there are no errors or warnings that were not surfaced previously:

```bash
dotnet build --configuration Release
```

Address any warnings related to nullable reference types, obsolete APIs, or platform compatibility analyzers before proceeding.

## 4. Run Existing Tests

If the solution contains test projects, execute them to verify that existing behavior is preserved:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests carefully, as they may indicate behavioral differences between the legacy .NET Framework runtime and the new cross-platform .NET runtime.

## 5. Check for Platform-Specific API Usage

Use the .NET Upgrade Assistant compatibility analyzer or the built-in platform compatibility warnings to identify any APIs that may not behave identically across operating systems. Pay particular attention to:

- `System.Drawing` (requires additional packages on Linux/macOS)
- Registry access (`Microsoft.Win32.Registry`)
- Windows-specific interop or COM components
- File path separator assumptions

## 6. Test on All Target Platforms

If cross-platform support is a goal, run the application and its tests on each intended operating system (Windows, Linux, macOS) to surface any runtime differences that do not appear at compile time:

```bash
dotnet run --configuration Release
```

## 7. Review Configuration and App Settings

Confirm that any configuration files (e.g., `appsettings.json`, environment variables) are correctly structured for the new hosting model. Legacy `App.config` or `Web.config` files may need to be migrated to `appsettings.json` or the `Microsoft.Extensions.Configuration` system.

## 8. Publish the Application

Once validation is complete, publish the application for the target runtime:

```bash
dotnet publish --configuration Release --runtime <runtime-identifier> --self-contained false
```

Replace `<runtime-identifier>` with the appropriate value, for example `win-x64`, `linux-x64`, or `osx-x64`. Use `--self-contained true` if you want to bundle the .NET runtime with the output.

Review the contents of the `publish` output folder to confirm all required assets and dependencies are present before deploying.