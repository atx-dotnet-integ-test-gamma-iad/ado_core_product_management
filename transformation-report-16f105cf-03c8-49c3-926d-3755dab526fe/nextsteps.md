# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are recommended steps to validate and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended .NET version (e.g., `net8.0` or `net6.0`). Example:

```xml
<PropertyGroup>
  <TargetFramework>net8.0</TargetFramework>
</PropertyGroup>
```

## 2. Restore and Build Locally

Run the following commands from the solution root to confirm a clean restore and build:

```bash
dotnet restore
dotnet build --configuration Release
```

Review the output for any warnings that may indicate deprecated APIs or packages that could cause runtime issues.

## 3. Run Existing Tests

If the solution contains test projects, execute them to verify that behavior has not changed after migration:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests and address them before proceeding.

## 4. Check for Removed or Changed APIs

Cross-platform .NET removes certain APIs that were available in .NET Framework. Run the .NET Compatibility Analyzer to surface any runtime-level compatibility concerns:

```bash
dotnet add package Microsoft.DotNet.Analyzers.Compatibility
dotnet build
```

Pay attention to any `CA` or `PC` prefixed warnings in the build output.

## 5. Review NuGet Package Compatibility

Open the `.csproj` file and verify that all referenced NuGet packages have versions that support your target framework. You can check compatibility at [nuget.org](https://www.nuget.org). Replace any packages that only support `net4x` with their cross-platform equivalents.

## 6. Validate Platform-Specific Behavior

Since this is a cross-platform migration, test the application on each target operating system (Windows, Linux, macOS) if applicable. Pay particular attention to:

- File path separators (`\` vs `/`)
- Registry access (not available on Linux/macOS)
- Windows-only APIs such as those in `System.Windows.Forms` or `Microsoft.Win32`

## 7. Review Configuration and Connection Strings

If the project uses `App.config` or `Web.config`, confirm that configuration has been migrated to `appsettings.json` or environment variables, as `ConfigurationManager` behavior differs in cross-platform .NET.

## 8. Publish the Application

Once validation is complete, publish the application using:

```bash
dotnet publish --configuration Release --output ./publish
```

For a self-contained deployment targeting a specific runtime:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained true --output ./publish
```

Review the contents of the `./publish` directory and verify all required files are present before deploying to the target environment.