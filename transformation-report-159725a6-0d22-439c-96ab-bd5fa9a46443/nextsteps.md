# Next Steps

The transformation appears to have completed successfully. There are no build errors present in the solution. Below are steps to validate, test, and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended cross-platform .NET version (e.g., `net8.0` or `net6.0`):

```xml
<PropertyGroup>
  <TargetFramework>net8.0</TargetFramework>
</PropertyGroup>
```

If it is still referencing a Windows-only TFM such as `net472` or `net48`, update it accordingly.

## 2. Restore and Build Locally

Run the following commands from the solution root to confirm a clean restore and build:

```bash
dotnet restore
dotnet build --configuration Release
```

Verify that no warnings or errors are produced. Pay attention to any `NU` prefixed NuGet warnings, as they may indicate packages that are not fully compatible with the target framework.

## 3. Run Existing Tests

If the solution contains test projects, execute them to confirm existing functionality is preserved:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review the output for any failing tests. Failures at this stage indicate behavioral regressions introduced during the migration and should be investigated before proceeding.

## 4. Check for Windows-Specific API Usage

Even when a project builds successfully, it may contain APIs that only function correctly on Windows. Use the .NET Compatibility Analyzer to surface these:

```bash
dotnet add package Microsoft.DotNet.Analyzers.Compatibility
```

Rebuild the project and review any `PC` prefixed warnings in the build output. Common problem areas include:

- `System.Windows.Forms` or `System.Drawing` references
- Registry access via `Microsoft.Win32`
- Windows-specific P/Invoke calls

## 5. Validate Runtime Behavior on Target Platforms

Run the application on each platform you intend to support (Linux, macOS, Windows) and verify that core functionality behaves as expected. Pay particular attention to:

- File path separators (`/` vs `\`)
- Case sensitivity of the file system
- Environment variable availability
- Line ending differences (`\r\n` vs `\n`)

## 6. Review Removed or Changed APIs

Check the [.NET Upgrade Assistant breaking changes documentation](https://docs.microsoft.com/en-us/dotnet/core/compatibility/) for the specific version you migrated to. Cross-reference any APIs used in `AdoCore` that may have changed behavior or been removed.

## 7. Update NuGet Dependencies

Confirm all NuGet packages are up to date and compatible with the target framework:

```bash
dotnet list package --outdated
```

Update packages that have newer versions available, and verify the build and tests still pass after each update.

## 8. Publish the Application

Once validation is complete, publish the application for the desired target runtime:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained false
```

Replace `linux-x64` with the appropriate runtime identifier (`win-x64`, `osx-x64`, etc.) as needed. Review the contents of the `publish` output directory to confirm all required assets are present.