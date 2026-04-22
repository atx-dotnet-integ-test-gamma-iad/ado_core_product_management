# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are recommended steps to validate and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended cross-platform .NET version (e.g., `net8.0`). Example:

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

If the solution contains test projects, execute them to verify that existing functionality is preserved:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Address any test failures before proceeding further.

## 4. Check for Platform-Specific API Usage

Review the codebase for any APIs that were available in .NET Framework but have limited or no support in cross-platform .NET. Common areas to check include:

- `System.Web` references
- Windows Registry access (`Microsoft.Win32.Registry`)
- `AppDomain` usage
- COM interop or P/Invoke calls targeting Windows-only libraries
- `BinaryFormatter` (deprecated and disabled by default in modern .NET)

Use the [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the `Microsoft.DotNet.PlatformAbstractions` tooling to identify remaining platform-specific dependencies.

## 5. Review NuGet Package Compatibility

Confirm that all NuGet packages referenced in `AdoCore.csproj` support the target framework. Run:

```bash
dotnet list package --outdated
```

Update any packages that have newer versions with cross-platform support. Pay particular attention to data access packages (e.g., ADO.NET providers) since the project name suggests database interaction.

## 6. Validate ADO.NET / Database Connectivity

Given the project name `AdoCore`, verify that the database provider being used is compatible with cross-platform .NET. For example:

- **SQL Server**: Use `Microsoft.Data.SqlClient` instead of `System.Data.SqlClient`
- **Oracle**: Ensure you are using `Oracle.ManagedDataAccess.Core`
- **MySQL**: Use `MySql.Data` or `Pomelo.EntityFrameworkCore.MySql`
- **ODBC/OLE DB**: Note that `System.Data.OleDb` is Windows-only; a cross-platform alternative may be required

Test actual database connections in your target runtime environment.

## 7. Run on Target Operating System

If cross-platform support is a goal, test the application explicitly on the target non-Windows OS (Linux or macOS):

```bash
dotnet run --configuration Release
```

Monitor for any `PlatformNotSupportedException` or runtime errors that do not surface on Windows.

## 8. Publish the Application

Once validation is complete, publish the application for the target environment:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained false
```

Adjust the `--runtime` flag (`win-x64`, `linux-x64`, `osx-x64`, etc.) and `--self-contained` value based on your deployment requirements. Review the published output directory to confirm all required assets are present.