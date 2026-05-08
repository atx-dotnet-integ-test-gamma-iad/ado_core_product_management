# Next Steps

The transformation appears to have completed successfully. There are no build errors present in the solution. Below are steps to validate, test, and deploy the migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element targets the intended cross-platform .NET version (e.g., `net6.0`, `net7.0`, or `net8.0`):

```xml
<PropertyGroup>
  <TargetFramework>net8.0</TargetFramework>
</PropertyGroup>
```

If the target framework is not what you intended, update it and rebuild the solution.

## 2. Restore NuGet Packages

Run the following command from the solution root to ensure all dependencies are restored correctly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated or incompatible packages.

## 3. Build the Solution

Perform a clean build to confirm there are no hidden issues:

```bash
dotnet clean
dotnet build --configuration Release
```

Review the build output for any warnings that may indicate compatibility concerns, even if they are not hard errors.

## 4. Run Existing Tests

If the solution contains test projects, execute them to verify that existing functionality has not regressed:

```bash
dotnet test --configuration Release --verbosity normal
```

Review the test results and investigate any failures. Pay particular attention to tests that exercise database access, file I/O, or platform-specific APIs, as these are common sources of cross-platform issues.

## 5. Check for Platform-Specific API Usage

Even without build errors, some APIs may behave differently or throw at runtime on non-Windows platforms. Review the code for usage of:

- `Microsoft.Win32` namespace
- `System.Windows.Forms` or `System.Drawing` (GDI+)
- Windows registry access
- Windows-specific file path assumptions (e.g., backslash separators, drive letters)
- P/Invoke calls targeting Windows-only native libraries

Use the [.NET Compatibility Analyzer](https://learn.microsoft.com/en-us/dotnet/standard/analyzers/platform-compat-analyzer) to assist with identifying these issues.

## 6. Run the Application on Target Platforms

Execute the application on each platform you intend to support (e.g., Linux, macOS, Windows) and verify runtime behavior:

```bash
dotnet run --configuration Release
```

Test all major code paths, particularly those involving:

- Database connections (ADO.NET drivers must be cross-platform compatible)
- File system operations
- Network calls
- Configuration file loading

## 7. Verify ADO.NET Provider Compatibility

Since this project is named `AdoCore`, confirm that the database provider being used is compatible with cross-platform .NET. For example:

- **SQL Server**: Use `Microsoft.Data.SqlClient`
- **SQLite**: Use `Microsoft.Data.Sqlite`
- **PostgreSQL**: Use `Npgsql`
- **MySQL**: Use `MySql.Data` or `Pomelo.EntityFrameworkCore.MySql`

Avoid using `System.Data.OleDb` or `System.Data.Odbc` on non-Windows platforms, as these have limited or no cross-platform support.

## 8. Review Configuration and Connection Strings

Ensure that connection strings and configuration values are sourced from `appsettings.json` or environment variables rather than hard-coded values or Windows-specific configuration stores such as the registry.

## 9. Publish the Application

Once validation is complete, publish the application for the target runtime:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained false
```

Replace `linux-x64` with the appropriate runtime identifier (RID) for your target environment. A full list of RIDs is available in the [Microsoft RID catalog](https://learn.microsoft.com/en-us/dotnet/core/rid-catalog).