# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are recommended steps to validate and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended cross-platform .NET version (e.g., `net8.0` or `net6.0`):

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

Ensure there are no warnings that could indicate deprecated APIs or compatibility issues.

## 3. Run Existing Tests

If the solution contains test projects, execute them to verify runtime behavior matches expectations:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests carefully, as they may indicate behavioral differences between the legacy .NET Framework runtime and the new cross-platform .NET runtime.

## 4. Check for Platform-Specific API Usage

Even without build errors, some APIs may have changed behavior at runtime. Review the code for usage of the following, which are common problem areas in migrations:

- `System.Data` and ADO.NET provider registrations (relevant given the `AdoCore` project name)
- `ConfigurationManager` — replaced by `Microsoft.Extensions.Configuration`
- `AppDomain` usage
- `BinaryFormatter` — removed in .NET 9, deprecated in earlier versions
- Windows-only APIs (e.g., registry access, COM interop)

## 5. Validate ADO.NET Database Connectivity

Since this project appears to be ADO.NET-related, verify that the correct database driver NuGet packages are referenced and functional:

- **SQL Server**: `Microsoft.Data.SqlClient`
- **MySQL**: `MySql.Data` or `MySqlConnector`
- **PostgreSQL**: `Npgsql`
- **SQLite**: `Microsoft.Data.Sqlite`

Test actual database connections in a non-production environment to confirm queries execute as expected.

## 6. Review NuGet Package Compatibility

Run the following command to check for outdated or vulnerable packages:

```bash
dotnet list package --outdated
dotnet list package --vulnerable
```

Update packages where appropriate, particularly any that were carried over from the legacy project.

## 7. Run on Target Operating Systems

If cross-platform support is a goal, run and test the application on each intended operating system (Windows, Linux, macOS) to surface any platform-specific runtime issues that would not appear at build time.

## 8. Publish the Application

Once validation is complete, publish the application using:

```bash
dotnet publish --configuration Release --output ./publish
```

For a self-contained deployment that does not require .NET to be installed on the target machine:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained true --output ./publish
```

Replace `linux-x64` with the appropriate runtime identifier (`win-x64`, `osx-x64`, etc.) for your target environment.