# Next Steps

The transformation appears to have completed successfully. There are no build errors present in the solution. Below are steps to validate, test, and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the target framework moniker (TFM) is set to your intended cross-platform target, for example:

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

Review the output for any warnings about deprecated packages or packages that do not support the target framework. Replace any packages that only support `net4x` or `netstandard` with their modern equivalents where applicable.

## 3. Build the Solution

Perform a clean build to confirm there are no compilation issues:

```bash
dotnet clean
dotnet build --configuration Release
```

Address any warnings that surface, particularly those related to nullable reference types or obsolete APIs, as these can indicate areas that may cause runtime issues.

## 4. Run Existing Tests

If the solution contains test projects, execute them to verify behavioral correctness after the migration:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests carefully. Failures after a migration often point to platform-specific behavior differences, changed default encodings, or removed APIs.

## 5. Check for Windows-Specific API Usage

Even with a successful build, the code may contain APIs that only function on Windows. Use the .NET Compatibility Analyzer to surface these:

```bash
dotnet add package Microsoft.DotNet.Analyzers.Compatibility
```

Alternatively, review the code manually for usages of:
- `Microsoft.Win32` namespace
- `System.Windows.Forms` or `System.Drawing` (unless the `EnableWindowsTargeting` flag or appropriate packages are used)
- P/Invoke calls targeting Windows-only native libraries
- Registry access via `RegistryKey`

## 6. Validate Runtime Behavior on Target Platforms

If cross-platform support is a goal, run the application on each intended operating system (Windows, Linux, macOS) to catch platform-specific runtime issues that do not surface at compile time:

```bash
dotnet run --configuration Release
```

Pay particular attention to:
- File path separators (`\` vs `/`)
- Case sensitivity in file system operations
- Environment variable differences

## 7. Review `app.config` / `web.config` Migration

If the original project used `app.config` or `web.config`, verify that configuration has been migrated to `appsettings.json` and that `Microsoft.Extensions.Configuration` is being used where appropriate. Legacy config sections are not supported in .NET 5+.

## 8. Publish the Application

Once validation is complete, publish the application for your target environment:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained false
```

Replace `linux-x64` with your target runtime identifier (RID) as needed (e.g., `win-x64`, `osx-x64`). Use `--self-contained true` if you want to bundle the .NET runtime with the output.

Review the published output in the `bin/Release/net8.0/<rid>/publish/` directory before deploying.