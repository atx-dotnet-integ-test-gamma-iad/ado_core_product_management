# Next Steps

The transformation appears to have completed successfully. There are no build errors present in the solution. Below are steps to validate, test, and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended cross-platform .NET version (e.g., `net8.0` or `net6.0`):

```xml
<PropertyGroup>
  <TargetFramework>net8.0</TargetFramework>
</PropertyGroup>
```

If the target framework does not match your intended version, update it and rebuild the solution.

## 2. Restore Dependencies

Run the following command from the solution root to ensure all NuGet packages are restored correctly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or packages that could not be resolved.

## 3. Build the Solution

Perform a clean build to confirm there are no errors or warnings that may have been missed:

```bash
dotnet build --configuration Release
```

Address any warnings that appear, particularly those related to nullable reference types, obsolete APIs, or platform compatibility.

## 4. Run Existing Tests

If the solution contains test projects, execute them to verify that existing functionality has not been broken during migration:

```bash
dotnet test --configuration Release
```

Review the test results carefully. Any failing tests should be investigated to determine whether the failure is due to a behavioral change introduced by the migration.

## 5. Check for Platform-Specific API Usage

Even if the build succeeds, some APIs that were available in .NET Framework may behave differently or have reduced functionality on non-Windows platforms. Use the .NET Upgrade Assistant compatibility analyzer or review the [.NET Platform Compatibility documentation](https://learn.microsoft.com/en-us/dotnet/core/compatibility/) to identify any such APIs in your codebase.

Run the following command to check for platform compatibility issues using the built-in analyzer:

```bash
dotnet build /p:EnableNETAnalyzers=true /p:AnalysisMode=All
```

## 6. Validate Runtime Behavior

Run the application on each target platform (Windows, Linux, macOS) to confirm it behaves as expected:

```bash
dotnet run --configuration Release
```

Pay particular attention to:
- File path handling (use `Path.Combine` rather than hardcoded separators)
- Registry access (not available on non-Windows platforms)
- Windows-specific APIs such as `System.Drawing` or `System.Windows.Forms`

## 7. Publish the Application

Once validation is complete, publish the application for your target platform. The following example publishes a self-contained executable for Linux:

```bash
dotnet publish -c Release -r linux-x64 --self-contained true
```

Replace `linux-x64` with the appropriate runtime identifier for your target environment (e.g., `win-x64`, `osx-x64`). Review the output in the `publish` folder before deploying to your target environment.