# Next Steps

The transformation appears to have completed successfully. There are no build errors present in the solution. Below are steps to validate, test, and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended cross-platform .NET version (e.g., `net8.0` or `net6.0`):

```xml
<PropertyGroup>
  <TargetFramework>net8.0</TargetFramework>
</PropertyGroup>
```

If it is still referencing a Windows-specific framework (e.g., `net472`), update it accordingly.

## 2. Restore Dependencies

Run the following command from the solution root to ensure all NuGet packages are restored correctly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated or incompatible packages.

## 3. Build the Solution

Perform a clean build to confirm there are no errors or warnings that may have been missed:

```bash
dotnet build --configuration Release
```

Address any warnings that could indicate runtime issues, such as nullable reference warnings or platform compatibility warnings.

## 4. Run Existing Tests

If the solution contains test projects, execute them to verify that existing functionality has not regressed:

```bash
dotnet test --configuration Release
```

Review the test output and investigate any failing tests. Pay particular attention to tests that cover data access logic, as ADO.NET behavior can differ slightly between .NET Framework and cross-platform .NET.

## 5. Check for Windows-Specific API Usage

Even without build errors, some APIs may compile but fail at runtime on non-Windows platforms. Use the .NET Compatibility Analyzer to identify potential issues:

```bash
dotnet add package Microsoft.DotNet.Analyzers.Compatibility
```

Review any analyzer warnings in your IDE or build output.

## 6. Validate ADO.NET Database Connectivity

Since this project appears to be ADO.NET-based (`AdoCore`), verify that the database driver packages being used are compatible with cross-platform .NET. For example:

- **SQL Server**: Ensure you are using `Microsoft.Data.SqlClient` rather than `System.Data.SqlClient`.
- **Other databases**: Confirm the relevant driver (e.g., `Npgsql`, `MySql.Data`) targets .NET Standard 2.0 or a compatible .NET version.

Test actual database connections in a development environment to confirm connectivity and query execution work as expected.

## 7. Review Configuration Files

If the project previously used `App.config` or `Web.config` for connection strings or settings, confirm these have been migrated to `appsettings.json` or environment variables, which are the standard configuration mechanisms in cross-platform .NET:

```json
{
  "ConnectionStrings": {
    "DefaultConnection": "your_connection_string_here"
  }
}
```

Update any code that uses `ConfigurationManager` to use `Microsoft.Extensions.Configuration` instead.

## 8. Test on Target Platform

If the goal is to run on a non-Windows operating system, deploy and run the application on that platform (e.g., Linux or macOS) in a development or staging environment to catch any remaining platform-specific issues before production deployment.

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained false
```

Run the published output on the target machine and verify expected behavior.