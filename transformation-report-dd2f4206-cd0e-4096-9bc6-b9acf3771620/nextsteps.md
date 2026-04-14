# Next Steps

The transformation appears to have completed successfully. There are no build errors present in the solution. Below are steps to validate, test, and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure this matches the .NET SDK version you have installed. Run the following to confirm your SDK:

```bash
dotnet --version
```

## 2. Restore Dependencies

Run a NuGet restore to ensure all packages are resolved correctly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or packages that may not be fully compatible with the target framework.

## 3. Build the Solution

Perform a clean build to confirm there are no compilation issues:

```bash
dotnet build --configuration Release
```

Address any warnings that surface during the build, particularly those related to nullable reference types or obsolete API usage, as these can indicate latent issues.

## 4. Run Existing Tests

If the solution contains test projects, execute them to verify that existing behavior is preserved:

```bash
dotnet test --configuration Release
```

Review test output carefully. Any failing tests should be investigated to determine whether they represent regressions introduced during migration or pre-existing issues.

## 5. Validate Platform-Specific Code

Since this project was migrated from a legacy Windows-based project, review the codebase for any remaining platform-specific dependencies, including:

- Usage of `Microsoft.Win32` or `System.Windows.Forms` namespaces
- P/Invoke calls targeting Windows-only native libraries
- Registry access via `RegistryKey`
- Windows-specific file path assumptions (e.g., backslashes, drive letters)

Use the .NET Compatibility Analyzer to assist with this:

```bash
dotnet add package Microsoft.DotNet.Analyzers.Compatibility
```

## 6. Test on Target Platforms

If cross-platform support is a goal, run and validate the application on each intended operating system (Windows, Linux, macOS) to surface any runtime issues that do not appear at compile time.

## 7. Review Removed or Changed APIs

Check the [.NET Upgrade Assistant documentation](https://learn.microsoft.com/en-us/dotnet/core/porting/) and the [.NET API compatibility reference](https://learn.microsoft.com/en-us/dotnet/core/compatibility/) for any APIs that were available in the legacy .NET Framework but have been removed or changed in modern .NET. Pay particular attention to:

- `System.Data` and ADO.NET behavior differences, which is relevant given the `AdoCore` project name
- Connection string formats and provider registration differences
- `DataSet` and `DataTable` serialization changes

## 8. Publish the Application

Once validation is complete, publish the application for the target runtime:

```bash
dotnet publish --configuration Release --runtime <runtime-identifier> --self-contained false
```

Replace `<runtime-identifier>` with the appropriate value, such as `win-x64`, `linux-x64`, or `osx-x64`. Review the contents of the publish output directory before deploying to confirm all required files are present.