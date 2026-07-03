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

Ensure there are no warnings that could indicate deprecated APIs or platform-specific code paths that may fail at runtime.

## 3. Run Existing Tests

If the solution contains test projects, execute them to verify that existing functionality has not regressed:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests and address them before proceeding.

## 4. Check for Platform-Specific API Usage

Even without build errors, some APIs may compile successfully but fail at runtime on non-Windows platforms. Use the .NET Compatibility Analyzer to surface these issues:

```bash
dotnet add package Microsoft.DotNet.Analyzers.Compatibility
dotnet build
```

Pay particular attention to:
- `System.Data` and ADO.NET provider-specific code (relevant given the `AdoCore` project name)
- Registry access (`Microsoft.Win32.Registry`)
- Windows-specific file path assumptions

## 5. Validate ADO.NET / Database Connectivity

Since this project appears to be data-access focused, verify that the database provider being used has a cross-platform compatible NuGet package. Common examples:

| Provider | Cross-Platform Package |
|---|---|
| SQL Server | `Microsoft.Data.SqlClient` |
| SQLite | `Microsoft.Data.Sqlite` |
| PostgreSQL | `Npgsql` |
| MySQL | `MySql.Data` or `Pomelo.EntityFrameworkCore.MySql` |

Replace any legacy `System.Data.SqlClient` references with `Microsoft.Data.SqlClient` if SQL Server is the target database:

```bash
dotnet remove package System.Data.SqlClient
dotnet add package Microsoft.Data.SqlClient
```

Update any `using` directives accordingly in your source files.

## 6. Test on Target Platform

If the goal is cross-platform support, run the application on the intended non-Windows platform (Linux or macOS) to catch any runtime-only issues:

```bash
dotnet run --configuration Release
```

## 7. Publish the Application

Once validation is complete, publish the application for the target runtime:

```bash
# Framework-dependent (requires .NET runtime installed on target machine)
dotnet publish --configuration Release --output ./publish

# Self-contained for a specific runtime
dotnet publish --configuration Release --runtime linux-x64 --self-contained true --output ./publish
```

Review the contents of the `./publish` directory to confirm all expected assemblies and configuration files are present before deploying to the target environment.