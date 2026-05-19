# Next Steps

The transformation appears to have completed successfully. There are no build errors present in the solution. Below are steps to validate and test the migrated project before deploying it.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element targets the intended cross-platform .NET version (e.g., `net8.0` or `net6.0`). Example:

```xml
<PropertyGroup>
  <TargetFramework>net8.0</TargetFramework>
</PropertyGroup>
```

## 2. Restore Dependencies

Run the following command from the solution root to ensure all NuGet packages are restored correctly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated or unlisted packages and consider updating them.

## 3. Build the Solution

Perform a clean build to confirm there are no errors or warnings introduced by the restored packages:

```bash
dotnet build --configuration Release
```

Address any warnings that may indicate compatibility concerns, such as obsolete API usage.

## 4. Run Existing Tests

If the solution contains test projects, execute them to verify that existing functionality has not regressed:

```bash
dotnet test --configuration Release
```

Review the test results and investigate any failures. Pay particular attention to tests that exercise platform-specific behavior, as these are the most likely to surface issues after a cross-platform migration.

## 5. Verify Runtime Behavior on Target Platforms

Run the application on each platform you intend to support (Windows, Linux, macOS) and verify that core functionality behaves as expected. Pay attention to the following common cross-platform concerns:

- **File paths**: Ensure no hardcoded backslashes (`\`) are used; use `Path.Combine` or `Path.DirectorySeparatorChar` instead.
- **Line endings**: Confirm that file reading and writing handles both `\r\n` and `\n` correctly.
- **Case sensitivity**: Linux file systems are case-sensitive; verify that all file and directory references use consistent casing.
- **Environment variables and configuration**: Confirm that any configuration previously read from the Windows registry or `app.config` has been migrated to a supported mechanism such as `appsettings.json` or environment variables.

## 6. Review Removed or Changed APIs

Check the code for any APIs that were available in .NET Framework but have changed behavior or are absent in cross-platform .NET. The [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the [Platform Compatibility Analyzer](https://learn.microsoft.com/en-us/dotnet/standard/analyzers/platform-compat-analyzer) can help identify these issues.

## 7. Publish the Application

Once validation is complete, publish the application for your target runtime. For a self-contained deployment targeting Linux x64 as an example:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained true
```

For a framework-dependent deployment:

```bash
dotnet publish --configuration Release
```

Review the contents of the `publish` output folder to confirm all required files are present before deploying to the target environment.