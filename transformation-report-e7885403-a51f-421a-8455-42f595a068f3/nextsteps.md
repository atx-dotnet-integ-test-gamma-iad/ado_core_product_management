# Next Steps

The transformation appears to have completed successfully. There are no build errors present in the solution. Below are steps to validate, test, and deploy the migrated project.

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

Review the output for any warnings about deprecated packages or version conflicts. If any packages previously referenced were Windows-only (e.g., certain `System.Drawing` or COM interop packages), verify that cross-platform alternatives have been substituted.

## 3. Build the Solution

Perform a clean build to confirm there are no compilation issues:

```bash
dotnet clean
dotnet build --configuration Release
```

Review any warnings in the build output, as some warnings may indicate API usage that is deprecated or platform-specific.

## 4. Run Existing Tests

If the solution contains a test project, execute the test suite:

```bash
dotnet test --configuration Release
```

Confirm that all previously passing tests continue to pass. If tests were not migrated, consider writing unit tests that cover the core functionality of `AdoCore` before proceeding.

## 5. Check for Platform-Specific API Usage

Use the .NET Compatibility Analyzer or the `dotnet-compatibility` tool to identify any remaining platform-specific API calls that may compile successfully but fail at runtime on non-Windows platforms:

```bash
dotnet add package Microsoft.DotNet.Analyzers.Compatibility
```

Alternatively, review the code manually for usages of:

- `System.Windows.Forms`
- `System.Drawing` (GDI+ based)
- P/Invoke calls targeting Windows-only DLLs
- Registry access via `Microsoft.Win32.Registry`

## 6. Test on Target Platforms

If cross-platform support is a goal, run and test the application on each intended platform (Linux, macOS, Windows). Pay particular attention to:

- File path separators
- Environment variable names
- Line ending differences
- Case sensitivity in file system operations

## 7. Review Configuration Files

Check that any configuration files (e.g., `appsettings.json`, connection strings) have been updated to remove legacy `app.config` or `web.config` patterns where applicable. The modern approach uses `Microsoft.Extensions.Configuration`.

## 8. Publish the Application

Once validation is complete, publish the application for the target runtime:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained false
```

Replace `linux-x64` with the appropriate runtime identifier (`win-x64`, `osx-x64`, etc.) as needed. Use `--self-contained true` if you want to bundle the .NET runtime with the output.

## 9. Verify Published Output

Navigate to the publish output directory and confirm the expected binaries and configuration files are present. Run the published output directly to perform a final smoke test before distribution.