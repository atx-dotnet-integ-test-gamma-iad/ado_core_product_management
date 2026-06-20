# Next Steps

The transformation appears to have completed successfully. There are no build errors present in the solution. Below are steps to validate, test, and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended cross-platform .NET version (e.g., `net8.0` or `net6.0`).

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

Ensure there are no warnings that could indicate compatibility issues, such as deprecated APIs or platform-specific calls.

## 3. Review NuGet Package Compatibility

Check that all NuGet packages referenced in `AdoCore.csproj` are compatible with the target framework. You can inspect this by running:

```bash
dotnet list package --outdated
dotnet list package --deprecated
```

Update any packages that are outdated or deprecated to their current stable versions.

## 4. Check for Platform-Specific Code

Search the codebase for any APIs that were Windows-specific in the legacy .NET Framework project. Common areas to check include:

- `System.Web` references (not available in cross-platform .NET)
- `Microsoft.Win32` registry access
- Windows-only interop or P/Invoke calls
- `AppDomain` usage that behaves differently in .NET Core and later

Use the [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the `Microsoft.DotNet.PlatformAbstractions` package where needed.

## 5. Run Existing Tests

If the solution contains a test project, execute the test suite to verify runtime behavior matches expectations:

```bash
dotnet test --configuration Release --logger trx
```

Review the `.trx` output for any failing or skipped tests. Pay particular attention to tests covering data access, as the project name suggests ADO.NET usage.

## 6. Validate ADO.NET Functionality

Since the project is named `AdoCore`, manually verify that database connectivity and query execution work as expected on the target platform:

- Confirm the database driver NuGet package (e.g., `Microsoft.Data.SqlClient`, `Npgsql`, `MySql.Data`) is the cross-platform compatible version.
- Test connection strings and ensure they are not relying on Windows-integrated authentication in environments where it may not be supported.

## 7. Run on Target Operating Systems

If cross-platform support is a goal, run the application on each intended OS (Windows, Linux, macOS) to catch any runtime issues that do not surface at compile time:

```bash
dotnet run --configuration Release
```

## 8. Publish the Application

Once validation is complete, publish the application using the appropriate runtime identifier:

```bash
# Framework-dependent (requires .NET runtime installed on target machine)
dotnet publish --configuration Release

# Self-contained for a specific platform
dotnet publish --configuration Release --runtime linux-x64 --self-contained true
```

Review the output in the `publish` folder before deploying to the target environment.