# Next Steps

The transformation appears to have completed successfully. There are no build errors present in the solution. Below are steps to validate, test, and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the target framework is set to the intended cross-platform .NET version (e.g., `net6.0`, `net7.0`, or `net8.0`):

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

Review the output for any warnings about deprecated packages or packages that may have been replaced during migration.

## 3. Build the Solution

Perform a full build to confirm there are no errors or warnings that may have been missed:

```bash
dotnet build --configuration Release
```

Address any warnings that appear, particularly those related to nullable reference types or obsolete API usage, as these can indicate areas that may cause runtime issues.

## 4. Run Existing Tests

If the solution contains test projects, execute them to verify that existing functionality has not regressed:

```bash
dotnet test --configuration Release
```

Review the test results carefully. Any failing tests should be investigated to determine if they are caused by behavioral differences between the legacy .NET Framework and the new cross-platform .NET runtime.

## 5. Check for Platform-Specific API Usage

Review the codebase for any APIs that were available in .NET Framework but are not available or behave differently in cross-platform .NET. Common areas to check include:

- `System.Data` and ADO.NET provider usage (relevant given the `AdoCore` project name)
- Database connection strings and driver compatibility (e.g., ensure you are using a compatible ADO.NET provider such as `Microsoft.Data.SqlClient` instead of `System.Data.SqlClient` if applicable)
- Registry access (`Microsoft.Win32.Registry`)
- Windows-specific APIs (`System.Windows.Forms`, `System.Drawing`)
- `AppDomain` and remoting APIs

## 6. Validate ADO.NET Functionality

Given the project is named `AdoCore`, pay particular attention to database connectivity:

- Confirm that the ADO.NET provider packages referenced are compatible with cross-platform .NET.
- Test all database connection, query, and transaction operations against your target database.
- Verify that connection string formats have not changed between the old and new provider versions.

## 7. Run the Application on Target Platforms

If cross-platform support is a goal, run and test the application on each intended operating system (e.g., Windows, Linux, macOS):

```bash
dotnet run --configuration Release
```

Observe runtime behavior for any exceptions or unexpected results that did not appear during the build phase.

## 8. Review Output and Publish

Once validation is complete, publish the application for the target runtime:

```bash
dotnet publish --configuration Release --runtime <runtime-identifier>
```

Replace `<runtime-identifier>` with the appropriate value, for example:
- `win-x64` for Windows
- `linux-x64` for Linux
- `osx-x64` for macOS

Verify the published output in the `bin/Release/<tfm>/<rid>/publish/` directory contains all expected files and dependencies.