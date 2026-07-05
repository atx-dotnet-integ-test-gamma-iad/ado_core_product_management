# Next Steps

The transformation appears to have completed successfully. There are no build errors present in the solution. The following steps outline how to validate, test, and deploy the migrated project.

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

Review the output for any warnings about deprecated packages or packages that do not support the target framework. If any packages are flagged, check NuGet.org for updated versions that support the new TFM.

## 3. Build the Solution

Perform a full build to confirm there are no compilation issues:

```bash
dotnet build --configuration Release
```

Address any warnings that surface during the build, particularly those related to nullable reference types or obsolete APIs, as these can indicate compatibility concerns.

## 4. Run Existing Tests

If the solution contains a test project, execute the test suite to verify that existing behavior is preserved:

```bash
dotnet test --configuration Release
```

Review any failing tests carefully. Failures may indicate behavioral differences between the legacy .NET Framework runtime and the new cross-platform .NET runtime, such as differences in globalization, string handling, or threading.

## 5. Check for Windows-Specific API Usage

Since this is a cross-platform migration, audit the codebase for APIs that are Windows-only. Common areas to check include:

- `Microsoft.Win32` registry access
- `System.Windows.Forms` or `System.Drawing` (GDI+)
- Windows-specific file path assumptions (e.g., backslash separators)
- COM interop or P/Invoke calls targeting Windows DLLs

Use the .NET Compatibility Analyzer to assist with this:

```bash
dotnet add package Microsoft.DotNet.Analyzers.Compatibility
```

## 6. Test on Target Platforms

If cross-platform support is a goal, run and validate the application on each intended operating system (Linux, macOS, Windows). Pay particular attention to:

- File system case sensitivity (Linux is case-sensitive)
- Path separator differences
- Environment variable behavior

## 7. Review Configuration and App Settings

If the project previously used `App.config` or `Web.config`, confirm that settings have been migrated to `appsettings.json` or the appropriate .NET configuration system. Verify that the configuration is loaded and read correctly at runtime.

## 8. Publish the Application

Once validation is complete, publish the application using the desired deployment model.

For a framework-dependent deployment:

```bash
dotnet publish --configuration Release --output ./publish
```

For a self-contained deployment targeting a specific runtime:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained true --output ./publish
```

Verify the contents of the `./publish` directory and confirm the application runs correctly from that output.